import { Router, Response } from 'express';
import { prisma } from '../index';
import { authenticate, AuthRequest } from '../middleware/auth';

const router = Router();

router.post('/register', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken) return res.status(400).json({ error: 'fcmToken required' });

    await prisma.user.update({
      where: { id: req.userId! },
      data: { fcmToken },
    });
    res.json({ message: 'Token registered' });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const notifications = await prisma.notification.findMany({
      where: { userId: req.userId! },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    res.json({ notifications });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.put('/:id/read', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    await prisma.notification.updateMany({
      where: { id: req.params.id, userId: req.userId! },
      data: { read: true },
    });
    res.json({ message: 'Marked as read' });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
