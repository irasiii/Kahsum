import Anthropic from '@anthropic-ai/sdk';

const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY || '',
});

export const claudeClient = {
  async analyzePrice(systemPrompt: string, userPrompt: any): Promise<any> {
    if (!process.env.ANTHROPIC_API_KEY) {
      console.warn('ANTHROPIC_API_KEY not set, returning mock data');
      return getMockAnalysis(userPrompt);
    }

    const response = await anthropic.messages.create({
      model: 'claude-haiku-4-5',
      max_tokens: 1000,
      system: systemPrompt,
      messages: [
        {
          role: 'user',
          content: JSON.stringify(userPrompt),
        },
      ],
    });

    const textBlock = response.content.find((block: any) => block.type === 'text');
    if (!textBlock || textBlock.type !== 'text') {
      throw new Error('Unexpected response format from Claude');
    }

    try {
      return JSON.parse(textBlock.text);
    } catch {
      throw new Error('Failed to parse Claude response as JSON');
    }
  },
};

function getMockAnalysis(input: any) {
  const avgPrice = input.historicalAvg || input.traderPrice * 0.85;
  const minPrice = avgPrice * 0.85;
  const maxPrice = avgPrice * 1.15;
  const diff = input.traderPrice - avgPrice;
  const verdict = diff > avgPrice * 0.2 ? 'inflated' : diff > avgPrice * 0.1 ? 'slightly_inflated' : 'honest';
  const discountVerdict = input.discountPct > 60 ? 'exaggerated' : 'genuine';

  return {
    marketPriceMin: Math.round(minPrice),
    marketPriceMax: Math.round(maxPrice),
    marketPriceAvg: Math.round(avgPrice),
    fairPriceLabel: input.language === 'ar' ? 'سعر السوق العادل' : 'Fair market price',
    verdict,
    verdictLabel: verdict === 'honest'
      ? (input.language === 'ar' ? 'سعر حقيقي' : 'Genuine price')
      : (input.language === 'ar' ? 'مبالغ فيه' : 'Inflated'),
    discountVerdict,
    discountLabel: discountVerdict === 'genuine'
      ? (input.language === 'ar' ? 'خصم حقيقي' : 'Genuine discount')
      : (input.language === 'ar' ? 'خصم مبالغ فيه' : 'Exaggerated discount'),
    confidenceScore: 'medium',
    confidenceLabel: input.language === 'ar' ? 'ثقة متوسطة' : 'Medium confidence',
    sources: ['khasm_history'],
    suggestion: input.language === 'ar'
      ? `متوسط سعر السوق لهذا المنتج هو ${Math.round(avgPrice)} ريال.`
      : `The average market price is ${Math.round(avgPrice)} SAR.`,
  };
}
