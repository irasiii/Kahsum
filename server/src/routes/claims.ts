import { Router, Response } from 'express';
import crypto from 'crypto';
import { prisma } from '../index';
import { authenticate, AuthRequest } from '../middleware/auth';
import { notifyDealClaimed, notifyDealRedeemed } from '../services/notificationService';

const router = Router();

/** POST /api/claims — consumer claims a deal */
router.post('/', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { dealId } = req.body;
    if (!dealId) return res.status(400).json({ error: 'dealId required' });

    const deal = await prisma.deal.findUnique({ where: { id: dealId } });
    if (!deal) return res.status(404).json({ error: 'Deal not found' });
    if (deal.status !== 'active') return res.status(400).json({ error: 'Deal is not active' });
    if (deal.expiryDate < new Date()) return res.status(400).json({ error: 'Deal has expired' });
    if (deal.redeemedCount >= deal.maxRedemptions) {
      return res.status(400).json({ error: 'Deal fully redeemed' });
    }

    const existing = await prisma.claim.findFirst({
      where: { dealId, consumerId: req.userId!, status: 'claimed' },
    });
    if (existing) return res.status(409).json({ error: 'Already claimed this deal' });

    const qrToken = crypto.randomBytes(32).toString('hex');

    // Atomic: create claim + increment counter in one transaction
    const [claim] = await prisma.$transaction([
      prisma.claim.create({
        data: { dealId, consumerId: req.userId!, qrToken },
      }),
      prisma.deal.update({
        where: { id: dealId },
        data: { redeemedCount: { increment: 1 } },
      }),
    ]);

    // Fire-and-forget push to trader — never block the HTTP response
    notifyDealClaimed(prisma, deal.traderId, deal.titleAr, deal.titleEn).catch(() => {});

    res.status(201).json({
      claim: {
        id: claim.id,
        qrToken: claim.qrToken,
        qrData: JSON.stringify({
          dealId,
          consumerId: req.userId!,
          claimId: claim.id,
          expiryTimestamp: deal.expiryDate.getTime(),
        }),
        deal,
      },
    });
  } catch (error) {
    console.error('Claim error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/** POST /api/claims/validate — trader scans consumer QR to mark as redeemed */
router.post('/validate', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { qrToken } = req.body;
    if (!qrToken) return res.status(400).json({ error: 'qrToken required' });

    const claim = await prisma.claim.findUnique({
      where: { qrToken },
      include: { deal: true },
    });
    if (!claim) return res.status(404).json({ error: 'Invalid QR code' });
    if (claim.status !== 'claimed') return res.status(400).json({ error: 'Already redeemed' });
    if (claim.deal.traderId !== req.userId) {
      return res.status(403).json({ error: 'This deal does not belong to you' });
    }

    const updated = await prisma.claim.update({
      where: { id: claim.id },
      data: { status: 'redeemed', redeemedAt: new Date() },
    });

    // Fire-and-forget push to consumer
    notifyDealRedeemed(
      prisma,
      claim.consumerId,
      claim.deal.titleAr,
      claim.deal.titleEn
    ).catch(() => {});

    res.json({ message: 'Redeemed successfully', claim: updated });
  } catch (error) {
    console.error('Validate error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/** GET /api/claims/mine — all claims for the authenticated consumer */
router.get('/mine', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const claims = await prisma.claim.findMany({
      where: { consumerId: req.userId! },
      include: {
        deal: {
          include: {
            trader: { include: { user: { select: { name: true } } } },
            category: true,
          },
        },
        rating: true,
      },
      orderBy: { claimedAt: 'desc' },
    });
    res.json({ claims });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
