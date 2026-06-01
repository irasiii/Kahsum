import { Router, Response } from 'express';
import { prisma } from '../index';
import { authenticate, requireTrader, AuthRequest } from '../middleware/auth';

const router = Router();

const TIER_PRICES: Record<string, number> = {
  basic: 49,
  standard: 99,
  premium: 199,
};

router.post('/initiate', authenticate, requireTrader, async (req: AuthRequest, res: Response) => {
  try {
    const { dealId, tier } = req.body;
    if (!dealId || !tier) return res.status(400).json({ error: 'dealId and tier required' });
    if (!TIER_PRICES[tier]) return res.status(400).json({ error: 'Invalid tier' });

    const amount = TIER_PRICES[tier];

    const payment = await prisma.payment.create({
      data: {
        traderId: req.userId!,
        dealId,
        amount,
        tier,
        status: 'completed',
      },
    });

    res.status(201).json({ payment, message: 'Mock payment completed' });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
