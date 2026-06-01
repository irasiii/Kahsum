import { Router, Request, Response } from 'express';
import { prisma } from '../index';

const router = Router();

router.get('/', async (_req: Request, res: Response) => {
  try {
    const categories = await prisma.category.findMany({
      orderBy: { sortOrder: 'asc' },
    });
    res.json({ categories });
  } catch (error) {
    console.error('Categories error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/:id', async (req: Request, res: Response) => {
  try {
    const category = await prisma.category.findUnique({
      where: { id: parseInt(req.params.id) },
    });
    if (!category) return res.status(404).json({ error: 'Category not found' });
    res.json({ category });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
