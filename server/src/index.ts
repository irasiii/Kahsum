import express, { RequestHandler } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import rateLimit from 'express-rate-limit';
import { PrismaClient } from '@prisma/client';

dotenv.config();

export const prisma = new PrismaClient();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(helmet());
app.use(cors());

const morganMiddleware: RequestHandler = (req, res, next) => {
  const morgan = require('morgan');
  morgan('dev')(req, res, next);
};
app.use(morganMiddleware);
app.use(express.json({ limit: '10mb' }));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/', limiter);

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

import authRoutes from './routes/auth';
import dealRoutes from './routes/deals';
import categoryRoutes from './routes/categories';
import claimRoutes from './routes/claims';
import ratingRoutes from './routes/ratings';
import aiRoutes from './routes/ai';
import paymentRoutes from './routes/payments';
import userRoutes from './routes/users';
import notificationRoutes from './routes/notifications';

app.use('/api/auth', authRoutes);
app.use('/api/deals', dealRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/claims', claimRoutes);
app.use('/api/ratings', ratingRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/users', userRoutes);
app.use('/api/notifications', notificationRoutes);

app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' });
});

app.listen(PORT, () => {
  console.log(`Khasm server running on port ${PORT}`);
});

process.on('SIGTERM', async () => {
  await prisma.$disconnect();
  process.exit(0);
});
