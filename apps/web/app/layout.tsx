import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'خصم | Khasm — عروض حقيقية، توفير حقيقي',
  description:
    'خصم هو سوق رقمي يربط التجار بالمستهلكين مباشرة. تحقق من سعر السوق بالذكاء الاصطناعي، واحصل على عروضك بمسح رمز QR. متاح في الرياض وجدة والدمام وكامل المملكة.',
  keywords:
    'عروض, تخفيضات, خصم, كوبونات, السعودية, رياض, جدة, دمام, عروض مطاعم, عروض تسوق, Khasm, discount, deals, Saudi Arabia',
  openGraph: {
    title: 'خصم | Khasm — عروض حقيقية، توفير حقيقي',
    description: 'اكتشف العروض الحقيقية من التجار مباشرة.',
    locale: 'ar_SA',
    type: 'website',
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="ar" dir="rtl">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link
          href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;900&display=swap"
          rel="stylesheet"
        />
      </head>
      <body>{children}</body>
    </html>
  );
}
