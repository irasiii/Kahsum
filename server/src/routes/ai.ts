import { Router, Response } from 'express';
import { prisma } from '../index';
import { authenticate, optionalAuth, requireTrader, AuthRequest } from '../middleware/auth';
import { getPriceSuggestion, getMarketValue } from '../services/pricingEngine';

const router = Router();

router.post('/price-suggestion', authenticate, requireTrader, async (req: AuthRequest, res: Response) => {
  try {
    const { productName, categoryId, traderPrice, discountPct, language = 'ar' } = req.body;

    if (!productName || !categoryId || !traderPrice) {
      return res.status(400).json({ error: 'productName, categoryId, and traderPrice required' });
    }

    const suggestion = await getPriceSuggestion({
      productName,
      categoryId: Number(categoryId),
      traderPrice: Number(traderPrice),
      discountPct: Number(discountPct) || 0,
      language: language as 'ar' | 'en',
      traderId: req.userId!,   // ← passed directly; no updateMany needed
    });

    if (!suggestion) return res.json({ available: false });
    res.json({ available: true, ...suggestion });
  } catch (error) {
    console.error('AI price suggestion error:', error);
    res.status(500).json({ error: 'AI service temporarily unavailable' });
  }
});

router.get('/market-value/:dealId', optionalAuth, async (req: AuthRequest, res: Response) => {
  try {
    const lang = (['ar', 'en'].includes(req.headers['accept-language'] as string)
      ? req.headers['accept-language']
      : 'ar') as 'ar' | 'en';

    const deal = await prisma.deal.findUnique({
      where: { id: req.params.dealId },
      include: { category: true },
    });
    if (!deal) return res.status(404).json({ error: 'Deal not found' });

    const marketValue = await getMarketValue({
      productName: lang === 'ar' ? deal.titleAr : deal.titleEn,
      categoryId: deal.categoryId,
      language: lang,
    });

    if (!marketValue?.available) return res.json({ available: false, status: 'no_data' });

    const savings = marketValue.marketPriceAvg
      ? deal.originalPrice - marketValue.marketPriceAvg
      : null;

    res.json({
      available: true,
      verdict: marketValue.verdict,
      marketPriceAvg: marketValue.marketPriceAvg,
      marketPriceMin: marketValue.marketPriceMin,
      marketPriceMax: marketValue.marketPriceMax,
      traderPrice: deal.originalPrice,
      savings: savings && savings > 0 ? savings : null,
      discountPct: deal.discountPct,
      confidence: marketValue.confidence,
      sources: marketValue.sources,
    });
  } catch (error) {
    console.error('Market value error:', error);
    res.json({ available: false, status: 'error' });
  }
});

export default router;
