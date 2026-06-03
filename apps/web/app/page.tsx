const APP_URL = process.env.NEXT_PUBLIC_APP_URL ?? 'https://app.khasm.com';

const FEATURES = [
  {
    icon: '🤖',
    ar: { title: 'سعر السوق الحقيقي بالذكاء الاصطناعي', body: 'قبل أن تحجز أي عرض، يحلّل الذكاء الاصطناعي أسعار نون وأمازون السعودية ويُخبرك إذا كان الخصم حقيقياً أم لا.' },
    en: { title: 'AI-Verified Market Price', body: 'Before you claim a deal, our AI checks Noon & Amazon.sa prices to tell you if the discount is real or inflated.' },
  },
  {
    icon: '📍',
    ar: { title: 'عروض قريبة منك على الخريطة', body: 'اكتشف العروض والتخفيضات في محيطك الجغرافي على خريطة تفاعلية. لا تفوّت عرضاً في حيّك.' },
    en: { title: 'Deals Near You on the Map', body: 'Discover live deals around you on an interactive map. Never miss a bargain in your neighbourhood.' },
  },
  {
    icon: '🎯',
    ar: { title: 'احصل على عرضك بـ QR', body: 'احجز العرض من التطبيق واحصل على رمز QR. أرِه للتاجر وأنت في محله — لا طباعة، لا كوبونات ورقية.' },
    en: { title: 'Claim Deals via QR Code', body: 'Book in the app, get a QR code, show it at the shop. No printing, no paper coupons.' },
  },
  {
    icon: '⭐',
    ar: { title: 'تقييمات حقيقية من المستهلكين', body: 'بعد استخدام العرض، قيّم تجربتك. التجار الجيدون يبرزون، والعروض المبالغ فيها تُكشف.' },
    en: { title: 'Genuine Consumer Ratings', body: 'After redeeming a deal, rate your experience. Great traders shine, inflated deals get exposed.' },
  },
  {
    icon: '🌍',
    ar: { title: 'ثنائي اللغة — عربي وإنجليزي', body: 'التطبيق والواجهة مصممان أولاً للعربية مع دعم كامل للإنجليزية، ويدعم تقويم هجري وضريبة القيمة المضافة.' },
    en: { title: 'Arabic-First, Bilingual', body: 'Built Arabic-first with full English support, Hijri calendar, and VAT display out of the box.' },
  },
  {
    icon: '🔔',
    ar: { title: 'إشعارات فورية', body: 'يصلك إشعار فوري عند حجز أحد عروضك (للتاجر) أو عند استخدام عرضك عند التاجر (للمستهلك).' },
    en: { title: 'Real-Time Push Notifications', body: "Get instant alerts when someone claims your deal (traders) or when your deal is redeemed (consumers)." },
  },
];

const STEPS_CONSUMER = [
  { num: '١', ar: 'حمّل التطبيق وأنشئ حساباً مجاناً', en: 'Download the app & create a free account' },
  { num: '٢', ar: 'تصفح العروض القريبة أو ابحث حسب الفئة', en: 'Browse nearby deals or search by category' },
  { num: '٣', ar: 'اضغط "احصل على العرض" واحصل على رمز QR', en: 'Tap "Claim Deal" and receive your QR code' },
  { num: '٤', ar: 'أرِ الرمز للتاجر واستمتع بخصمك!', en: 'Show the QR to the trader and enjoy your discount!' },
];

const CATEGORIES = [
  { icon: '🍔', ar: 'مطاعم وكافيهات', en: 'Food & Cafés' },
  { icon: '👗', ar: 'أزياء وملابس', en: 'Fashion' },
  { icon: '💆', ar: 'صحة وجمال', en: 'Beauty & Wellness' },
  { icon: '📱', ar: 'إلكترونيات', en: 'Electronics' },
  { icon: '🏋️', ar: 'رياضة ولياقة', en: 'Sports & Fitness' },
  { icon: '🏠', ar: 'أثاث ومنازل', en: 'Home & Furniture' },
  { icon: '📚', ar: 'تعليم وكتب', en: 'Education' },
  { icon: '✈️', ar: 'سفر وترفيه', en: 'Travel & Entertainment' },
  { icon: '🔧', ar: 'خدمات', en: 'Services' },
  { icon: '🎁', ar: 'هدايا', en: 'Gifts' },
];

// Simple bilingual wrapper — no client-side JS needed for static SEO page.
// The HTML dir="rtl" already handles RTL layout; English content is shown
// side-by-side via helper below.
function Bi({ ar, en }: { ar: React.ReactNode; en: React.ReactNode }) {
  return (
    <>
      <span lang="ar">{ar}</span>
      <span className="en-sep" lang="en" aria-hidden="true"> / {en}</span>
    </>
  );
}

export default function HomePage() {
  return (
    <>
      {/* ── Navbar ──────────────────────────────────────────────────────── */}
      <header className="navbar">
        <div className="container inner">
          <a href="/" className="logo" aria-label="خصم - Khasm">
            <span className="logo-icon" aria-hidden="true">🏷️</span>
            خصم&nbsp;
            <span style={{ opacity: 0.45 }}>|</span>
            &nbsp;Khasm
          </a>
          <nav>
            <a href="#features">المميزات</a>
            <a href="#categories">الفئات</a>
            <a href="#for-traders">للتجار</a>
            <a href={APP_URL} className="btn btn-primary" style={{ padding: '8px 20px', fontSize: '0.9rem' }}>
              ابدأ الآن
            </a>
          </nav>
        </div>
      </header>

      <main>
        {/* ── Hero ────────────────────────────────────────────────────── */}
        <section className="hero">
          <div className="hero-badge">🇸🇦 متاح في المملكة العربية السعودية ودول الخليج</div>
          <h1>
            عروض <span>حقيقية</span>،<br />توفير حقيقي
          </h1>
          <p>
            سوق رقمي يربطك بالتجار مباشرة. الذكاء الاصطناعي يتحقق من كل سعر
            — لتحصل على خصم حقيقي، لا مبالغ فيه.
          </p>
          <div className="hero-ctas">
            <a href={APP_URL} className="btn btn-accent btn-lg">تصفح العروض الآن</a>
            <a href="#for-traders" className="btn btn-white btn-lg">أنا تاجر ←</a>
          </div>
          <div className="hero-stats">
            <div className="hero-stat"><div className="num">+40</div><div className="lbl">فئة</div></div>
            <div className="hero-stat"><div className="num">AI</div><div className="lbl">تحقق آلي من الأسعار</div></div>
            <div className="hero-stat"><div className="num">QR</div><div className="lbl">استخدام فوري</div></div>
            <div className="hero-stat"><div className="num">0</div><div className="lbl">عمولة على المستهلك</div></div>
          </div>
        </section>

        {/* ── How it works ────────────────────────────────────────────── */}
        <section className="steps section" id="how">
          <div className="container">
            <h2 className="section-title">كيف يعمل خصم؟</h2>
            <p className="section-subtitle">أربع خطوات بسيطة تفصلك عن أفضل العروض في مدينتك</p>
            <div className="grid-4">
              {STEPS_CONSUMER.map((s, i) => (
                <div key={i} className="step-card">
                  <div className="step-num">{s.num}</div>
                  <h3>{s.ar}</h3>
                  <p style={{ fontSize: '0.83rem', color: '#9E9E9E', marginTop: 4 }}>{s.en}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        <hr className="divider" />

        {/* ── Features ────────────────────────────────────────────────── */}
        <section className="features section" id="features">
          <div className="container">
            <h2 className="section-title">لماذا خصم؟</h2>
            <p className="section-subtitle">
              نحن لا نجمع عروضاً — نحن نتحقق منها.
            </p>
            <div className="grid-3">
              {FEATURES.map((f, i) => (
                <div key={i} className="feature-card">
                  <div className="feature-icon">{f.icon}</div>
                  <h3>{f.ar.title}</h3>
                  <p>{f.ar.body}</p>
                  <p style={{ fontSize: '0.82rem', color: '#BDBDBD', marginTop: 8 }}>{f.en.body}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* ── Categories ──────────────────────────────────────────────── */}
        <section className="categories section" id="categories">
          <div className="container">
            <h2 className="section-title">+40 فئة تجارية</h2>
            <p className="section-subtitle">من المطاعم إلى الإلكترونيات — كل عروض مدينتك في مكان واحد</p>
            <div className="cat-grid">
              {CATEGORIES.map((c, i) => (
                <div key={i} className="cat-chip">
                  <div className="icon">{c.icon}</div>
                  {c.ar}
                  <div style={{ fontSize: '0.72rem', color: '#BDBDBD', marginTop: 2 }}>{c.en}</div>
                </div>
              ))}
            </div>
          </div>
        </section>

        <hr className="divider" />

        {/* ── Trader CTA ──────────────────────────────────────────────── */}
        <section className="trader-section section" id="for-traders">
          <div className="container">
            <div className="trader-cta-card">
              <div>
                <h2>أنت تاجر؟ انشر عروضك الآن</h2>
                <p>
                  وصّل عروضك لآلاف المستهلكين في مدينتك. الذكاء الاصطناعي يساعدك على تسعير منتجاتك
                  تسعيراً منافساً — لتكسب ثقة المستهلك وتزيد مبيعاتك.
                </p>
                <div style={{ marginBottom: 28 }}>
                  <a href={`${APP_URL}/register`} className="btn btn-accent btn-lg">
                    أنشئ حسابك مجاناً
                  </a>
                </div>
                <div className="tier-list">
                  <div className="tier-item">
                    <div className="tier-price">٤٩ ريال</div>
                    <div className="tier-name">أساسية · ٧ أيام</div>
                  </div>
                  <div className="tier-item">
                    <div className="tier-price">٩٩ ريال</div>
                    <div className="tier-name">قياسية · ١٥ يوماً</div>
                  </div>
                  <div className="tier-item" style={{ borderColor: 'rgba(245,166,35,0.6)' }}>
                    <div className="tier-price">١٩٩ ريال</div>
                    <div className="tier-name">مميزة · ٣٠ يوماً ⭐</div>
                  </div>
                </div>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 16, textAlign: 'center' }}>
                <div style={{ fontSize: '5rem', lineHeight: 1 }}>🏪</div>
                <div style={{ fontSize: '0.88rem', opacity: 0.8, maxWidth: 200 }}>
                  إدارة عروضك، مسح QR، تقييمات العملاء — كل شيء في تطبيق واحد
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ── App download ────────────────────────────────────────────── */}
        <section className="download section" id="download">
          <div className="container">
            <div className="download-inner">
              <div className="phone-mockup">📱</div>
              <div className="download-text">
                <h2>حمّل التطبيق الآن</h2>
                <p>
                  متاح على iOS وAndroid. تصفح بدون حساب، أو سجّل لتحصل على عروضك وتتابع تاريخ خصوماتك.
                </p>
                <div className="store-buttons">
                  <a href="#" className="store-btn" aria-label="App Store">
                    <span className="store-icon"></span>
                    <span>
                      <div style={{ fontSize: '0.7rem', opacity: 0.7 }}>Download on the</div>
                      App Store
                    </span>
                  </a>
                  <a href="#" className="store-btn" aria-label="Google Play">
                    <span className="store-icon">▶</span>
                    <span>
                      <div style={{ fontSize: '0.7rem', opacity: 0.7 }}>Get it on</div>
                      Google Play
                    </span>
                  </a>
                </div>
                <p style={{ marginTop: 16, fontSize: '0.85rem', color: '#9E9E9E' }}>
                  أو افتح التطبيق على الويب مباشرة:{' '}
                  <a href={APP_URL} style={{ color: 'var(--primary)', fontWeight: 700 }}>
                    app.khasm.com
                  </a>
                </p>
              </div>
            </div>
          </div>
        </section>
      </main>

      {/* ── Footer ──────────────────────────────────────────────────────── */}
      <footer className="footer">
        <div className="container">
          <div className="footer-grid">
            <div className="footer-brand">
              <div className="f-logo">🏷️ خصم | Khasm</div>
              <p>سوق رقمي للعروض الحقيقية في السعودية ودول الخليج.</p>
            </div>
            <div>
              <h4>روابط سريعة</h4>
              <ul>
                <li><a href="#how">كيف يعمل</a></li>
                <li><a href="#features">المميزات</a></li>
                <li><a href="#categories">الفئات</a></li>
                <li><a href="#for-traders">للتجار</a></li>
              </ul>
            </div>
            <div>
              <h4>التطبيق</h4>
              <ul>
                <li><a href={APP_URL}>فتح التطبيق</a></li>
                <li><a href={`${APP_URL}/register`}>إنشاء حساب</a></li>
                <li><a href={`${APP_URL}/login`}>تسجيل الدخول</a></li>
                <li><a href="#">سياسة الخصوصية</a></li>
                <li><a href="#">شروط الاستخدام</a></li>
              </ul>
            </div>
          </div>
          <div className="footer-bottom">
            <span>© {new Date().getFullYear()} خصم — Khasm. جميع الحقوق محفوظة.</span>
            <span>صُنع في المملكة العربية السعودية 🇸🇦</span>
          </div>
        </div>
      </footer>
    </>
  );
}
