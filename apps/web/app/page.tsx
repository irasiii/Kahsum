export default function HomePage() {
  return (
    <>
      <header>
        <div className="container">
          <h1>خصم <span style={{ opacity: 0.5 }}>|</span> Khasm</h1>
          <p>عروض حقيقية، توفير حقيقي</p>
        </div>
      </header>

      <section className="hero">
        <h2>عروض حقيقية من التجار مباشرة</h2>
        <p>
          نوصل لك أفضل العروض والتخفيضات من التجار في مدينتك. بدون وسطاء، بدون مبالغة.
          سعر السوق الحقيقي مدعوم بالذكاء الاصطناعي.
        </p>
        <a href="https://app.khasm.com" className="cta-button">
          تصفح العروض الآن
        </a>
      </section>

      <section className="features">
        <div className="container">
          <h2>لماذا خصم؟</h2>
          <div className="feature-grid">
            <div className="feature-card">
              <h3>🤖 سعر السوق الحقيقي</h3>
              <p>الذكاء الاصطناعي يحلل الأسواق ويظهر لك السعر العادل لكل منتج.</p>
            </div>
            <div className="feature-card">
              <h3>📍 عروض قريبة منك</h3>
              <p>اكتشف العروض والتخفيضات في محيطك بناءً على موقعك الجغرافي.</p>
            </div>
            <div className="feature-card">
              <h3>🎯 احصل على العرض بـ QR</h3>
              <p>احصل على العرض واستخدمه بمسح رمز QR بسيط عند التاجر.</p>
            </div>
            <div className="feature-card">
              <h3>🛍️ للتجار: نظام نشر عروض</h3>
              <p>انشر عروضك وتواصل مع المستهلكين مباشرة بدون الحاجة للتسويق عبر المؤثرين.</p>
            </div>
          </div>
        </div>
      </section>

      <footer>
        <div className="container">
          <p>© 2026 خصم - Khasm. جميع الحقوق محفوظة.</p>
        </div>
      </footer>
    </>
  );
}
