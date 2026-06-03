import { Router, Response } from 'express';
import { z } from 'zod';
import { prisma } from '../index';
import { authenticate, optionalAuth, requireTrader, AuthRequest } from '../middleware/auth';

const router = Router();

// ── Schemas ──────────────────────────────────────────────────────────────────

const createDealSchema = z.object({
  categoryId: z.number().int(),
  titleAr: z.string().min(2).max(200),
  titleEn: z.string().min(2).max(200),
  descriptionAr: z.string().optional(),
  descriptionEn: z.string().optional(),
  discountPct: z.number().min(1).max(100),
  originalPrice: z.number().positive(),
  imageUrl: z.string().url().optional(),
  maxRedemptions: z.number().int().positive().default(100),
  expiryDate: z.string().datetime(),
  tier: z.enum(['basic', 'standard', 'premium']).default('basic'),
});

const updateDealSchema = z.object({
  categoryId: z.number().int().optional(),
  titleAr: z.string().min(2).max(200).optional(),
  titleEn: z.string().min(2).max(200).optional(),
  descriptionAr: z.string().optional(),
  descriptionEn: z.string().optional(),
  discountPct: z.number().min(1).max(100).optional(),
  originalPrice: z.number().positive().optional(),
  imageUrl: z.string().url().optional(),
  maxRedemptions: z.number().int().positive().optional(),
  expiryDate: z.string().datetime().optional(),
});

// ── Public / optional-auth routes ────────────────────────────────────────────

router.get('/', optionalAuth, async (req: AuthRequest, res: Response) => {
  try {
    const {
      category,
      sort = 'recent',
      minDiscount,
      maxPrice,
      page = '1',
      limit = '20',
    } = req.query as Record<string, string>;

    const where: any = { status: 'active', expiryDate: { gte: new Date() } };
    if (category) where.categoryId = parseInt(category);
    if (minDiscount) where.discountPct = { gte: parseFloat(minDiscount) };
    if (maxPrice) where.originalPrice = { lte: parseFloat(maxPrice) };

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [deals, total] = await Promise.all([
      prisma.deal.findMany({
        where,
        include: {
          trader: { include: { user: { select: { name: true } } } },
          category: true,
        },
        orderBy: sort === 'discount' ? { discountPct: 'desc' } : { createdAt: 'desc' },
        skip,
        take: parseInt(limit),
      }),
      prisma.deal.count({ where }),
    ]);

    res.json({ deals, total, page: parseInt(page), pages: Math.ceil(total / parseInt(limit)) });
  } catch (error) {
    console.error('Get deals error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/nearby', optionalAuth, async (req: AuthRequest, res: Response) => {
  try {
    const { lat, lng, radius = '25' } = req.query as Record<string, string>;
    if (!lat || !lng) return res.status(400).json({ error: 'Latitude and longitude required' });

    const userLat = parseFloat(lat);
    const userLng = parseFloat(lng);
    const maxDist = parseFloat(radius);

    const deals = await prisma.deal.findMany({
      where: { status: 'active', expiryDate: { gte: new Date() } },
      include: {
        trader: { include: { user: { select: { name: true } } } },
        category: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    const nearbyDeals = deals.filter((deal) => {
      if (!deal.trader.lat || !deal.trader.lng) return false;
      return _haversine(userLat, userLng, deal.trader.lat, deal.trader.lng) <= maxDist;
    });

    res.json({ deals: nearbyDeals });
  } catch (error) {
    console.error('Nearby deals error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ── Trader: own deals ─────────────────────────────────────────────────────────

/** GET /api/deals/mine — trader's own deals with redemption counts */
router.get('/mine', authenticate, requireTrader, async (req: AuthRequest, res: Response) => {
  try {
    const deals = await prisma.deal.findMany({
      where: { traderId: req.userId! },
      include: {
        category: true,
        _count: { select: { claims: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ deals });
  } catch (error) {
    console.error('Get my deals error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/** GET /api/deals/:id — single deal detail */
router.get('/:id', optionalAuth, async (req: AuthRequest, res: Response) => {
  try {
    const deal = await prisma.deal.findUnique({
      where: { id: req.params.id },
      include: {
        trader: { include: { user: { select: { name: true, phone: true } } } },
        category: true,
        _count: { select: { claims: true } },
      },
    });
    if (!deal) return res.status(404).json({ error: 'Deal not found' });
    res.json({ deal });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

/** POST /api/deals — create a new deal */
router.post('/', authenticate, requireTrader, async (req: AuthRequest, res: Response) => {
  try {
    const data = createDealSchema.parse(req.body);
    const deal = await prisma.deal.create({
      data: { ...data, expiryDate: new Date(data.expiryDate), traderId: req.userId! },
    });
    res.status(201).json({ deal });
  } catch (error) {
    if (error instanceof z.ZodError) return res.status(400).json({ error: error.errors });
    res.status(500).json({ error: 'Internal server error' });
  }
});

/** PUT /api/deals/:id — update editable fields (own deal only) */
router.put('/:id', authenticate, requireTrader, async (req: AuthRequest, res: Response) => {
  try {
    const existing = await prisma.deal.findUnique({ where: { id: req.params.id } });
    if (!existing) return res.status(404).json({ error: 'Deal not found' });
    if (existing.traderId !== req.userId) {
      return res.status(403).json({ error: 'Not your deal' });
    }

    const data = updateDealSchema.parse(req.body);
    const deal = await prisma.deal.update({
      where: { id: req.params.id },
      data: {
        ...data,
        ...(data.expiryDate ? { expiryDate: new Date(data.expiryDate) } : {}),
      },
    });
    res.json({ deal });
  } catch (error) {
    if (error instanceof z.ZodError) return res.status(400).json({ error: error.errors });
    res.status(500).json({ error: 'Internal server error' });
  }
});

/** PATCH /api/deals/:id/status — toggle active ↔ paused (own deal only) */
router.patch('/:id/status', authenticate, requireTrader, async (req: AuthRequest, res: Response) => {
  try {
    const existing = await prisma.deal.findUnique({ where: { id: req.params.id } });
    if (!existing) return res.status(404).json({ error: 'Deal not found' });
    if (existing.traderId !== req.userId) {
      return res.status(403).json({ error: 'Not your deal' });
    }

    const { status } = req.body as { status: 'active' | 'paused' };
    if (!['active', 'paused'].includes(status)) {
      return res.status(400).json({ error: 'status must be active or paused' });
    }

    const deal = await prisma.deal.update({
      where: { id: req.params.id },
      data: { status },
    });
    res.json({ deal });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

/** DELETE /api/deals/:id — soft-delete by setting status to expired */
router.delete('/:id', authenticate, requireTrader, async (req: AuthRequest, res: Response) => {
  try {
    const existing = await prisma.deal.findUnique({ where: { id: req.params.id } });
    if (!existing) return res.status(404).json({ error: 'Deal not found' });
    if (existing.traderId !== req.userId) {
      return res.status(403).json({ error: 'Not your deal' });
    }

    await prisma.deal.update({
      where: { id: req.params.id },
      data: { status: 'expired' },
    });
    res.json({ message: 'Deal removed' });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ── Helpers ───────────────────────────────────────────────────────────────────

function _haversine(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371;
  const dLat = _toRad(lat2 - lat1);
  const dLng = _toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(_toRad(lat1)) * Math.cos(_toRad(lat2)) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2);
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function _toRad(deg: number): number {
  return (deg * Math.PI) / 180;
}

export default router;
