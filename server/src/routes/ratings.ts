import { Router, Response } from 'express';
import { z } from 'zod';
import { prisma } from '../index';
import { authenticate, AuthRequest } from '../middleware/auth';

const router = Router();

const ratingSchema = z.object({
  claimId: z.string().uuid(),
  stars: z.number().int().min(1).max(5),
  comment: z.string().max(200).optional(),
});

router.post('/', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const data = ratingSchema.parse(req.body);
    const claim = await prisma.claim.findUnique({
      where: { id: data.claimId },
      include: { deal: true, rating: true },
    });
    if (!claim) return res.status(404).json({ error: 'Claim not found' });
    if (claim.consumerId !== req.userId) return res.status(403).json({ error: 'Not your claim' });
    if (claim.status !== 'redeemed') return res.status(400).json({ error: 'Deal not yet redeemed' });
    if (claim.rating) return res.status(409).json({ error: 'Already rated' });

    const rating = await prisma.rating.create({
      data: {
        claimId: data.claimId,
        traderId: claim.deal.traderId,
        consumerId: req.userId!,
        stars: data.stars,
        comment: data.comment,
      },
    });

    const stats = await prisma.rating.aggregate({
      where: { traderId: claim.deal.traderId },
      _avg: { stars: true },
      _count: true,
    });

    await prisma.traderProfile.update({
      where: { userId: claim.deal.traderId },
      data: {
        ratingAvg: stats._avg.stars || 0,
        ratingCount: stats._count,
      },
    });

    res.status(201).json({ rating });
  } catch (error) {
    if (error instanceof z.ZodError) return res.status(400).json({ error: error.errors });
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
