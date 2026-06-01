import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'خصم | Khasm - أفضل العروض والتخفيضات في السعودية',
  description: 'خصم هو سوق إلكتروني للعروض والتخفيضات يربط التجار بالمستهلكين مباشرة. اكتشف أفضل العروض في الرياض، جدة، الدمام والمزيد.',
  keywords: 'عروض, تخفيضات, خصم, كوبونات, السعودية, رياض, جدة, عروض مطاعم, عروض تسوق',
  openGraph: {
    title: 'خصم | Khasm - عروض حقيقية، توفير حقيقي',
    description: 'اكتشف العروض الحقيقية من التجار مباشرة.',
    locale: 'ar_SA',
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ar" dir="rtl">
      <body>{children}</body>
    </html>
  );
}
