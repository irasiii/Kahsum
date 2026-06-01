import { prisma } from '../index';
import { apifyClient } from './apifyClient';
import { claudeClient } from './claudeClient';
import fs from 'fs';
import path from 'path';

interface PriceSuggestionInput {
  productName: string;
  categoryId: number;
  traderPrice: number;
  discountPct: number;
  language: 'ar' | 'en';
}

interface MarketValueInput {
  productName: string;
  categoryId: number;
  language: 'ar' | 'en';
}

async function getSystemPrompt(): Promise<string> {
  const promptPath = path.join(__dirname, '..', 'prompts', 'pricingSystem.txt');
  return fs.readFileSync(promptPath, 'utf-8');
}

async function getCachedPrice(productName: string, categoryId: number) {
  return prisma.priceCache.findFirst({
    where: {
      productName: { contains: productName, mode: 'insensitive' },
      categoryId,
      expiresAt: { gte: new Date() },
    },
    orderBy: { createdAt: 'desc' },
  });
}

async function getInternalHistory(categoryId: number, productName: string) {
  const deals = await prisma.deal.findMany({
    where: {
      categoryId,
      status: 'active',
      OR: [
        { titleAr: { contains: productName, mode: 'insensitive' } },
        { titleEn: { contains: productName, mode: 'insensitive' } },
      ],
    },
    select: { originalPrice: true, discountPct: true },
  });

  if (deals.length === 0) return null;

  const total = deals.length;
  const avgPrice = deals.reduce((s, d) => s + d.originalPrice, 0) / total;
  const avgDiscount = deals.reduce((s, d) => s + d.discountPct, 0) / total;

  return { averagePrice: Math.round(avgPrice * 100) / 100, averageDiscount: Math.round(avgDiscount * 100) / 100, totalDeals: total };
}

export async function getPriceSuggestion(input: PriceSuggestionInput) {
  try {
    const cached = await getCachedPrice(input.productName, input.categoryId);
    if (cached && cached.verdict) {
      return formatResponse(cached, input);
    }

    const [noonPrices, amazonPrices, history] = await Promise.all([
      apifyClient.scrapeNoon(input.productName).catch(() => null),
      apifyClient.scrapeAmazon(input.productName).catch(() => null),
      getInternalHistory(input.categoryId, input.productName),
    ]);

    const systemPrompt = await getSystemPrompt();
    const userPrompt = {
      productName: input.productName,
      traderPrice: input.traderPrice,
      discountPct: input.discountPct,
      noonPrices: noonPrices || [],
      amazonPrices: amazonPrices || [],
      historicalAvg: history?.averagePrice || null,
      currency: 'SAR',
      language: input.language,
    };

    const aiResult = await claudeClient.analyzePrice(systemPrompt, userPrompt);

    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 6);

    await prisma.priceCache.create({
      data: {
        productName: input.productName,
        categoryId: input.categoryId,
        marketPriceMin: aiResult.marketPriceMin,
        marketPriceMax: aiResult.marketPriceMax,
        marketPriceAvg: aiResult.marketPriceAvg,
        verdict: aiResult.verdict,
        confidence: aiResult.confidenceScore,
        sources: aiResult.sources || [],
        rawResponse: aiResult,
        expiresAt,
      },
    });

    await prisma.aiPriceLog.create({
      data: {
        traderPrice: input.traderPrice,
        traderDiscountPct: input.discountPct,
        aiSuggestedPrice: aiResult.marketPriceAvg,
        aiVerdict: aiResult.verdict,
        traderId: '',
        finalPostedPrice: null,
      },
    });

    return {
      ...aiResult,
      fairPriceLabel: input.language === 'ar' ? 'سعر السوق العادل' : 'Fair market price',
      verdictLabel: getVerdictLabel(aiResult.verdict, input.language),
      discountLabel: getDiscountLabel(aiResult.discountVerdict, input.language),
      confidenceLabel: getConfidenceLabel(aiResult.confidenceScore, input.language),
    };
  } catch (error) {
    console.error('Price suggestion error:', error);
    return null;
  }
}

export async function getMarketValue(input: MarketValueInput) {
  try {
    const cached = await getCachedPrice(input.productName, input.categoryId);
    if (cached && cached.verdict) {
      return formatBadgeResponse(cached, input);
    }

    const [noonPrices, amazonPrices, history] = await Promise.all([
      apifyClient.scrapeNoon(input.productName).catch(() => null),
      apifyClient.scrapeAmazon(input.productName).catch(() => null),
      getInternalHistory(input.categoryId, input.productName),
    ]);

    const systemPrompt = await getSystemPrompt();
    const userPrompt = {
      productName: input.productName,
      traderPrice: 0,
      discountPct: 0,
      noonPrices: noonPrices || [],
      amazonPrices: amazonPrices || [],
      historicalAvg: history?.averagePrice || null,
      currency: 'SAR',
      language: input.language,
    };

    const aiResult = await claudeClient.analyzePrice(systemPrompt, userPrompt);
    return formatBadgeResponseFromAI(aiResult, input);
  } catch (error) {
    console.error('Market value error:', error);
    return null;
  }
}

function formatResponse(cached: any, input: PriceSuggestionInput) {
  return {
    marketPriceMin: cached.marketPriceMin,
    marketPriceMax: cached.marketPriceMax,
    marketPriceAvg: cached.marketPriceAvg,
    verdict: cached.verdict,
    fairPriceLabel: input.language === 'ar' ? 'سعر السوق العادل' : 'Fair market price',
    verdictLabel: getVerdictLabel(cached.verdict, input.language),
    discountVerdict: cached.verdict === 'honest' ? 'genuine' : 'exaggerated',
    discountLabel: cached.verdict === 'honest'
      ? (input.language === 'ar' ? 'خصم حقيقي' : 'Genuine discount')
      : (input.language === 'ar' ? 'خصم مبالغ فيه' : 'Exaggerated discount'),
    confidenceScore: cached.confidence || 'medium',
    confidenceLabel: getConfidenceLabel(cached.confidence, input.language),
    sources: cached.sources || [],
    suggestion: input.language === 'ar'
      ? `متوسط سعر السوق لهذا المنتج في السعودية هو ${cached.marketPriceAvg} ريال.`
      : `The average market price for this product in KSA is ${cached.marketPriceAvg} SAR.`,
  };
}

function formatBadgeResponse(cached: any, input: MarketValueInput) {
  if (!cached.marketPriceAvg) {
    return { available: false };
  }
  return {
    available: true,
    verdict: cached.verdict,
    marketPriceAvg: cached.marketPriceAvg,
    marketPriceMin: cached.marketPriceMin,
    marketPriceMax: cached.marketPriceMax,
    confidence: cached.confidence,
    sources: cached.sources,
  };
}

function formatBadgeResponseFromAI(aiResult: any, _input: MarketValueInput) {
  if (!aiResult || !aiResult.marketPriceAvg) {
    return { available: false };
  }
  return {
    available: true,
    verdict: aiResult.verdict,
    marketPriceAvg: aiResult.marketPriceAvg,
    marketPriceMin: aiResult.marketPriceMin,
    marketPriceMax: aiResult.marketPriceMax,
    confidence: aiResult.confidenceScore,
    sources: aiResult.sources || [],
  };
}

function getVerdictLabel(verdict: string, lang: 'ar' | 'en'): string {
  const labels: Record<string, Record<string, string>> = {
    honest: { ar: 'سعر حقيقي', en: 'Genuine price' },
    slightly_inflated: { ar: 'مبالغ قليلاً', en: 'Slightly inflated' },
    inflated: { ar: 'مبالغ فيه', en: 'Inflated' },
  };
  return labels[verdict]?.[lang] || verdict;
}

function getDiscountLabel(verdict: string, lang: 'ar' | 'en'): string {
  const labels: Record<string, Record<string, string>> = {
    genuine: { ar: 'خصم حقيقي', en: 'Genuine discount' },
    exaggerated: { ar: 'خصم مبالغ فيه', en: 'Exaggerated discount' },
  };
  return labels[verdict]?.[lang] || verdict;
}

function getConfidenceLabel(confidence: string, lang: 'ar' | 'en'): string {
  const labels: Record<string, Record<string, string>> = {
    high: { ar: 'ثقة عالية', en: 'High confidence' },
    medium: { ar: 'ثقة متوسطة', en: 'Medium confidence' },
    low: { ar: 'ثقة منخفضة', en: 'Low confidence' },
  };
  return labels[confidence]?.[lang] || confidence;
}
