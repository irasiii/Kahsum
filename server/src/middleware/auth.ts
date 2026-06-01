import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

export interface AuthRequest extends Request {
  userId?: string;
  userType?: string;
}

export function authenticate(req: AuthRequest, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Authentication required' });
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'dev-secret') as {
      userId: string;
      type: string;
    };
    req.userId = decoded.userId;
    req.userType = decoded.type;
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

export function optionalAuth(req: AuthRequest, _res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.split(' ')[1];
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'dev-secret') as {
        userId: string;
        type: string;
      };
      req.userId = decoded.userId;
      req.userType = decoded.type;
    } catch {
      // Silently continue as guest
    }
  }
  next();
}

export function requireTrader(req: AuthRequest, res: Response, next: NextFunction) {
  if (req.userType !== 'trader') {
    return res.status(403).json({ error: 'Trader access required' });
  }
  next();
}
