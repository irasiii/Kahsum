import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { z } from 'zod';
import { prisma } from '../index';

const router = Router();

const registerSchema = z.object({
  type: z.enum(['consumer', 'trader']),
  name: z.string().min(2).max(100),
  email: z.string().email(),
  phone: z.string().min(8).max(20),
  password: z.string().min(6).max(100),
  language: z.enum(['ar', 'en']).default('ar'),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string(),
});

router.post('/register', async (req: Request, res: Response) => {
  try {
    const data = registerSchema.parse(req.body);
    const existingUser = await prisma.user.findFirst({
      where: {
        OR: [{ email: data.email }, { phone: data.phone }],
      },
    });
    if (existingUser) {
      return res.status(409).json({ error: 'Email or phone already registered' });
    }

    const passwordHash = await bcrypt.hash(data.password, 12);
    const user = await prisma.user.create({
      data: {
        type: data.type,
        name: data.name,
        email: data.email,
        phone: data.phone,
        passwordHash,
        language: data.language,
      },
    });

    if (data.type === 'trader') {
      await prisma.traderProfile.create({
        data: { userId: user.id, categoryId: 1, businessName: data.name },
      });
    }

    const token = jwt.sign(
      { userId: user.id, type: user.type },
      process.env.JWT_SECRET || 'dev-secret',
      { expiresIn: '30d' }
    );

    res.status(201).json({
      token,
      user: { id: user.id, name: user.name, email: user.email, type: user.type },
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: error.errors });
    }
    console.error('Register error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/login', async (req: Request, res: Response) => {
  try {
    const data = loginSchema.parse(req.body);
    const user = await prisma.user.findUnique({ where: { email: data.email } });
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const valid = await bcrypt.compare(data.password, user.passwordHash);
    if (!valid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { userId: user.id, type: user.type },
      process.env.JWT_SECRET || 'dev-secret',
      { expiresIn: '30d' }
    );

    res.json({
      token,
      user: { id: user.id, name: user.name, email: user.email, type: user.type },
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: error.errors });
    }
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
