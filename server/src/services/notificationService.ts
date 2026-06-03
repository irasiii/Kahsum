/**
 * Notification service — Firebase Cloud Messaging + in-app DB notifications.
 *
 * FCM is optional: if FIREBASE_PROJECT_ID is not set the service silently
 * skips the push and only writes to the Notification table.
 */
import { PrismaClient } from '@prisma/client';

let _messaging: import('firebase-admin/messaging').Messaging | null = null;

function getMessaging() {
  if (_messaging) return _messaging;
  const projectId = process.env.FIREBASE_PROJECT_ID;
  if (!projectId) return null;

  try {
    // Dynamic import to avoid crashing if firebase-admin is missing
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const admin = require('firebase-admin') as typeof import('firebase-admin');
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL ?? '',
          privateKey: (process.env.FIREBASE_PRIVATE_KEY ?? '').replace(/\\n/g, '\n'),
        }),
      });
    }
    _messaging = admin.messaging();
    return _messaging;
  } catch (err) {
    console.warn('firebase-admin not available, push notifications disabled:', (err as Error).message);
    return null;
  }
}

// ── Core send ─────────────────────────────────────────────────────────────────

async function sendPush(
  fcmToken: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<void> {
  const messaging = getMessaging();
  if (!messaging || !fcmToken) return;

  try {
    await messaging.send({
      token: fcmToken,
      notification: { title, body },
      data: data ?? {},
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    });
  } catch (err) {
    // A bad token (e.g. after app uninstall) throws messaging/invalid-argument
    // — log and continue; don't let a push failure break the request.
    console.error('FCM send error:', (err as Error).message);
  }
}

async function createDbNotification(
  prisma: PrismaClient,
  userId: string,
  type: string,
  messageAr: string,
  messageEn: string
): Promise<void> {
  await prisma.notification.create({
    data: { userId, type, messageAr, messageEn },
  }).catch((err: Error) => console.error('DB notification error:', err.message));
}

// ── Domain helpers ────────────────────────────────────────────────────────────

/**
 * Notify a trader that a consumer just claimed their deal.
 */
export async function notifyDealClaimed(
  prisma: PrismaClient,
  traderId: string,
  dealTitleAr: string,
  dealTitleEn: string
): Promise<void> {
  const trader = await prisma.user.findUnique({
    where: { id: traderId },
    select: { fcmToken: true, language: true },
  });
  if (!trader) return;

  const lang = trader.language ?? 'ar';
  const title = lang === 'ar' ? 'عرض جديد محجوز 🎉' : 'New Claim 🎉';
  const body = lang === 'ar'
    ? `تم حجز عرض "${dealTitleAr}" من قِبَل مستخدم جديد`
    : `"${dealTitleEn}" was claimed by a new customer`;

  await Promise.all([
    trader.fcmToken ? sendPush(trader.fcmToken, title, body) : Promise.resolve(),
    createDbNotification(prisma, traderId, 'deal_claimed',
      `تم حجز عرض "${dealTitleAr}"`,
      `"${dealTitleEn}" was claimed`),
  ]);
}

/**
 * Notify a consumer that the trader just validated (redeemed) their claim.
 */
export async function notifyDealRedeemed(
  prisma: PrismaClient,
  consumerId: string,
  dealTitleAr: string,
  dealTitleEn: string
): Promise<void> {
  const consumer = await prisma.user.findUnique({
    where: { id: consumerId },
    select: { fcmToken: true, language: true },
  });
  if (!consumer) return;

  const lang = consumer.language ?? 'ar';
  const title = lang === 'ar' ? 'تم استخدام العرض ✅' : 'Deal Redeemed ✅';
  const body = lang === 'ar'
    ? `تم استخدام عرض "${dealTitleAr}" بنجاح`
    : `"${dealTitleEn}" was redeemed successfully`;

  await Promise.all([
    consumer.fcmToken ? sendPush(consumer.fcmToken, title, body) : Promise.resolve(),
    createDbNotification(prisma, consumerId, 'deal_redeemed',
      `تم استخدام عرض "${dealTitleAr}"`,
      `"${dealTitleEn}" was redeemed`),
  ]);
}

/**
 * Warn a trader that their deal expires within 24 hours.
 * Call this from a scheduled job.
 */
export async function notifyDealExpiring(
  prisma: PrismaClient,
  traderId: string,
  dealTitleAr: string,
  dealTitleEn: string
): Promise<void> {
  const trader = await prisma.user.findUnique({
    where: { id: traderId },
    select: { fcmToken: true, language: true },
  });
  if (!trader) return;

  const lang = trader.language ?? 'ar';
  const title = lang === 'ar' ? 'عرضك على وشك الانتهاء ⏰' : 'Deal Expiring Soon ⏰';
  const body = lang === 'ar'
    ? `عرض "${dealTitleAr}" سينتهي خلال 24 ساعة`
    : `"${dealTitleEn}" expires in 24 hours`;

  await Promise.all([
    trader.fcmToken ? sendPush(trader.fcmToken, title, body) : Promise.resolve(),
    createDbNotification(prisma, traderId, 'deal_expiring',
      `عرض "${dealTitleAr}" سينتهي قريباً`,
      `"${dealTitleEn}" is expiring soon`),
  ]);
}
