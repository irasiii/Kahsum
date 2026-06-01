import { Router, Response } from 'express';
import { z } from 'zod';
import { prisma } from '../index';
import { authenticate, optionalAuth, requireTrader, AuthRequest } from '../middleware/auth';

const router = Router();

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

router.get('/', optionalAuth, async (req: AuthRequest, res: Response) => {
  try {
    const {
      category,
      sort = 'recent',
      lat,
      lng,
      radius,
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

    const deals = await prisma.deal.findMany({
      where,
      include: {
        trader: { include: { user: { select: { name: true } } } },
        category: true,
      },
      orderBy: sort === 'discount' ? { discountPct: 'desc' } : { createdAt: 'desc' },
      skip,
      take: parseInt(limit),
    });

    const total = await prisma.deal.count({ where });

    res.json({ deals, total, page: parseInt(page), pages: Math.ceil(total / parseInt(limit)) });
  } catch (error) {
    console.error('Get deals error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/nearby', optionalAuth, async (req: AuthRequest, res: Response) => {
  try {
    const { lat, lng, radius = '25' } = req.query as Record<string, string>;
    if (!lat || !lng) {
      return res.status(400).json({ error: 'Latitude and longitude required' });
    }

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
      const dist = _haversine(userLat, userLng, deal.trader.lat, deal.trader.lng);
      return dist <= maxDist;
    });

    res.json({ deals: nearbyDeals });
  } catch (error) {
    console.error('Nearby deals error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/:id', optionalAuth, async (req: AuthRequest, res: Response) => {
  try {
    const deal = await prisma.deal.findUnique({
      where: { id: req.params.id },
      include: {
        trader: {
          include: { user: { select: { name: true, phone: true } } },
        },
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

router.post('/', authenticate, requireTrader, async (req: AuthRequest, res: Response) => {
  try {
    const data = createDealSchema.parse(req.body);
    const deal = await prisma.deal.create({
      data: {
        ...data,
        expiryDate: new Date(data.expiryDate),
        traderId: req.userId!,
      },
    });
    res.status(201).json({ deal });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: error.errors });
    }
    res.status(500).json({ error: 'Internal server error' });
  }
});

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
