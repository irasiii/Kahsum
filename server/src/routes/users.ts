import { Router, Response } from 'express';
import { prisma } from '../index';
import { authenticate, AuthRequest } from '../middleware/auth';

const router = Router();

router.get('/me', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.userId! },
      include: { traderProfile: true },
    });
    if (!user) return res.status(404).json({ error: 'User not found' });
    const { passwordHash, ...userData } = user;
    res.json({ user: userData });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.put('/me', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { name, phone, language } = req.body;
    const data: any = {};
    if (name) data.name = name;
    if (phone) data.phone = phone;
    if (language) data.language = language;

    const user = await prisma.user.update({
      where: { id: req.userId! },
      data,
    });
    const { passwordHash, ...userData } = user;
    res.json({ user: userData });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.put('/language', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { language } = req.body;
    if (!['ar', 'en'].includes(language)) {
      return res.status(400).json({ error: 'Language must be ar or en' });
    }
    await prisma.user.update({
      where: { id: req.userId! },
      data: { language },
    });
    res.json({ message: 'Language updated' });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
