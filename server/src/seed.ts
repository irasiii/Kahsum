import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const categories = [
  { sortOrder: 1, slug: 'restaurants', nameEn: 'Restaurants', nameAr: 'مطاعم', groupEn: 'Food & Drink', groupAr: 'مأكولات ومشروبات', icon: 'restaurant' },
  { sortOrder: 2, slug: 'coffee-shops', nameEn: 'Coffee shops', nameAr: 'مقاهي', groupEn: 'Food & Drink', groupAr: 'مأكولات ومشروبات', icon: 'coffee' },
  { sortOrder: 3, slug: 'fast-food', nameEn: 'Fast food', nameAr: 'وجبات سريعة', groupEn: 'Food & Drink', groupAr: 'مأكولات ومشروبات', icon: 'fastfood' },
  { sortOrder: 4, slug: 'desserts', nameEn: 'Desserts & sweets', nameAr: 'حلويات', groupEn: 'Food & Drink', groupAr: 'مأكولات ومشروبات', icon: 'cake' },
  { sortOrder: 5, slug: 'groceries', nameEn: 'Groceries', nameAr: 'بقالة', groupEn: 'Food & Drink', groupAr: 'مأكولات ومشروبات', icon: 'shopping_cart' },
  { sortOrder: 6, slug: 'juices', nameEn: 'Juices & smoothies', nameAr: 'عصائر', groupEn: 'Food & Drink', groupAr: 'مأكولات ومشروبات', icon: 'local_cafe' },
  { sortOrder: 7, slug: 'healthy-organic', nameEn: 'Healthy & organic', nameAr: 'صحي وعضوي', groupEn: 'Food & Drink', groupAr: 'مأكولات ومشروبات', icon: 'spa' },
  { sortOrder: 8, slug: 'mens-fashion', nameEn: "Men's fashion", nameAr: 'أزياء رجالية', groupEn: 'Fashion & Apparel', groupAr: 'أزياء وإكسسوارات', icon: 'man' },
  { sortOrder: 9, slug: 'womens-fashion', nameEn: "Women's fashion", nameAr: 'أزياء نسائية', groupEn: 'Fashion & Apparel', groupAr: 'أزياء وإكسسوارات', icon: 'woman' },
  { sortOrder: 10, slug: 'abayas-thobes', nameEn: 'Abayas & thobes', nameAr: 'عبايات وثياب', groupEn: 'Fashion & Apparel', groupAr: 'أزياء وإكسسوارات', icon: 'checkroom', isGulfExclusive: true },
  { sortOrder: 11, slug: 'footwear', nameEn: 'Footwear', nameAr: 'أحذية', groupEn: 'Fashion & Apparel', groupAr: 'أزياء وإكسسوارات', icon: 'footprint' },
  { sortOrder: 12, slug: 'bags-accessories', nameEn: 'Bags & accessories', nameAr: 'شنط وإكسسوارات', groupEn: 'Fashion & Apparel', groupAr: 'أزياء وإكسسوارات', icon: 'handbag' },
  { sortOrder: 13, slug: 'kids-clothing', nameEn: "Kids' clothing", nameAr: 'أزياء أطفال', groupEn: 'Fashion & Apparel', groupAr: 'أزياء وإكسسوارات', icon: 'child_care' },
  { sortOrder: 14, slug: 'salons-barbers', nameEn: 'Salons & barbershops', nameAr: 'صالونات وحلاقة', groupEn: 'Beauty & Wellness', groupAr: 'جمال وعناية', icon: 'content_cut' },
  { sortOrder: 15, slug: 'spas-massage', nameEn: 'Spas & massage', nameAr: 'منتجعات ومساج', groupEn: 'Beauty & Wellness', groupAr: 'جمال وعناية', icon: 'self_improvement' },
  { sortOrder: 16, slug: 'skincare-cosmetics', nameEn: 'Skincare & cosmetics', nameAr: 'عناية بالبشرة ومستحضرات تجميل', groupEn: 'Beauty & Wellness', groupAr: 'جمال وعناية', icon: 'face' },
  { sortOrder: 17, slug: 'nail-care', nameEn: 'Nail care', nameAr: 'عناية بالأظافر', groupEn: 'Beauty & Wellness', groupAr: 'جمال وعناية', icon: 'back_hand' },
  { sortOrder: 18, slug: 'laser-aesthetics', nameEn: 'Laser & aesthetics', nameAr: 'ليزر وتجميل', groupEn: 'Beauty & Wellness', groupAr: 'جمال وعناية', icon: 'healing' },
  { sortOrder: 19, slug: 'perfumes-oud', nameEn: 'Perfumes & oud', nameAr: 'عطور ودهن عود', groupEn: 'Beauty & Wellness', groupAr: 'جمال وعناية', icon: 'air_freshener', isGulfExclusive: true },
  { sortOrder: 20, slug: 'phones-tablets', nameEn: 'Phones & tablets', nameAr: 'جوالات وأجهزة لوحية', groupEn: 'Electronics & Tech', groupAr: 'إلكترونيات وتقنية', icon: 'smartphone' },
  { sortOrder: 21, slug: 'computers-laptops', nameEn: 'Computers & laptops', nameAr: 'كمبيوتر ولابتوب', groupEn: 'Electronics & Tech', groupAr: 'إلكترونيات وتقنية', icon: 'computer' },
  { sortOrder: 22, slug: 'home-appliances', nameEn: 'Home appliances', nameAr: 'أجهزة منزلية', groupEn: 'Electronics & Tech', groupAr: 'إلكترونيات وتقنية', icon: 'kitchen' },
  { sortOrder: 23, slug: 'gadgets', nameEn: 'Gadgets & accessories', nameAr: 'إلكترونيات وإكسسوارات', groupEn: 'Electronics & Tech', groupAr: 'إلكترونيات وتقنية', icon: 'watch' },
  { sortOrder: 24, slug: 'furniture', nameEn: 'Furniture', nameAr: 'أثاث', groupEn: 'Home & Furniture', groupAr: 'منزل وأثاث', icon: 'chair' },
  { sortOrder: 25, slug: 'home-decor', nameEn: 'Home decor', nameAr: 'ديكور منزلي', groupEn: 'Home & Furniture', groupAr: 'منزل وأثاث', icon: 'blender' },
  { sortOrder: 26, slug: 'home-services', nameEn: 'Home services', nameAr: 'خدمات منزلية', groupEn: 'Home & Furniture', groupAr: 'منزل وأثاث', icon: 'handyman' },
  { sortOrder: 27, slug: 'garden-outdoor', nameEn: 'Garden & outdoor', nameAr: 'حدائق وأماكن خارجية', groupEn: 'Home & Furniture', groupAr: 'منزل وأثاث', icon: 'yard' },
  { sortOrder: 28, slug: 'gyms-fitness', nameEn: 'Gyms & fitness', nameAr: 'نوادي رياضية', groupEn: 'Sports, Health & Leisure', groupAr: 'رياضة وصحة وترفيه', icon: 'fitness_center' },
  { sortOrder: 29, slug: 'sports-gear', nameEn: 'Sports gear', nameAr: 'معدات رياضية', groupEn: 'Sports, Health & Leisure', groupAr: 'رياضة وصحة وترفيه', icon: 'sports_soccer' },
  { sortOrder: 30, slug: 'healthcare', nameEn: 'Healthcare', nameAr: 'رعاية صحية', groupEn: 'Sports, Health & Leisure', groupAr: 'رياضة وصحة وترفيه', icon: 'local_hospital' },
  { sortOrder: 31, slug: 'pharmacy-supplements', nameEn: 'Pharmacy & supplements', nameAr: 'صيدلية ومكملات', groupEn: 'Sports, Health & Leisure', groupAr: 'رياضة وصحة وترفيه', icon: 'medication' },
  { sortOrder: 32, slug: 'entertainment', nameEn: 'Entertainment & activities', nameAr: 'ترفيه وأنشطة', groupEn: 'Sports, Health & Leisure', groupAr: 'رياضة وصحة وترفيه', icon: 'celebration' },
  { sortOrder: 33, slug: 'car-wash', nameEn: 'Car wash & detailing', nameAr: 'غسيل وتلميع سيارات', groupEn: 'Automotive & Transport', groupAr: 'سيارات ومواصلات', icon: 'local_car_wash' },
  { sortOrder: 34, slug: 'car-maintenance', nameEn: 'Car maintenance', nameAr: 'صيانة سيارات', groupEn: 'Automotive & Transport', groupAr: 'سيارات ومواصلات', icon: 'build' },
  { sortOrder: 35, slug: 'car-accessories', nameEn: 'Car accessories', nameAr: 'اكسسوارات سيارات', groupEn: 'Automotive & Transport', groupAr: 'سيارات ومواصلات', icon: 'garage' },
  { sortOrder: 36, slug: 'shisha-lounges', nameEn: 'Shisha lounges', nameAr: 'شيشة', groupEn: 'Gulf-Exclusive', groupAr: 'خليجيات', icon: 'smoking_rooms', isGulfExclusive: true },
  { sortOrder: 37, slug: 'quran-islamic', nameEn: 'Quran & Islamic education', nameAr: 'قرآن وتعليم إسلامي', groupEn: 'Gulf-Exclusive', groupAr: 'خليجيات', icon: ' mosque', isGulfExclusive: true },
  { sortOrder: 38, slug: 'majlis-event-halls', nameEn: 'Majlis & event halls', nameAr: 'مجالس وصالات مناسبات', groupEn: 'Gulf-Exclusive', groupAr: 'خليجيات', icon: 'meeting_room', isGulfExclusive: true },
  { sortOrder: 39, slug: 'eid-gifts', nameEn: 'Eid & occasion gifts', nameAr: 'هدايا العيد والمناسبات', groupEn: 'Gulf-Exclusive', groupAr: 'خليجيات', icon: 'card_giftcard', isGulfExclusive: true },
  { sortOrder: 40, slug: 'education-tutoring', nameEn: 'Education & tutoring', nameAr: 'تعليم ودروس خصوصية', groupEn: 'Gulf-Exclusive', groupAr: 'خليجيات', icon: 'school', isGulfExclusive: true },
];

async function seed() {
  console.log('Seeding categories...');
  for (const cat of categories) {
    await prisma.category.upsert({
      where: { slug: cat.slug },
      update: cat,
      create: cat,
    });
  }

  console.log('Seeding traders...');
  const traderData = [
    { name: 'Ahmed Al-Otaibi', email: 'ahmed@example.com', phone: '+966501111111', businessName: 'مطعم الناضج', businessNameEn: 'Al-Nadij Restaurant', cat: 'restaurants', lat: 24.7136, lng: 46.6753 },
    { name: 'Noura Al-Saud', email: 'noura@example.com', phone: '+966502222222', businessName: 'صالون نورة', businessNameEn: "Noura's Salon", cat: 'salons-barbers', lat: 24.7210, lng: 46.6800 },
    { name: 'Khalid Al-Ghamdi', email: 'khalid@example.com', phone: '+966503333333', businessName: 'متجر كلاود', businessNameEn: 'Cloud Store', cat: 'phones-tablets', lat: 24.7300, lng: 46.6700 },
    { name: 'Sara Al-Harbi', email: 'sara@example.com', phone: '+966504444444', businessName: 'نادي فتنس برو', businessNameEn: 'Fitness Pro Gym', cat: 'gyms-fitness', lat: 24.7250, lng: 46.6900 },
    { name: 'Fahad Al-Dossari', email: 'fahad@example.com', phone: '+966505555555', businessName: 'غسيل السيارات الماسي', businessNameEn: 'Diamond Car Wash', cat: 'car-wash', lat: 24.7100, lng: 46.6650 },
  ];

  for (const t of traderData) {
    const cat = await prisma.category.findUnique({ where: { slug: t.cat } });
    if (!cat) continue;

    const existingUser = await prisma.user.findUnique({ where: { email: t.email } });
    if (existingUser) continue;

    const user = await prisma.user.create({
      data: {
        type: 'trader',
        name: t.name,
        email: t.email,
        phone: t.phone,
        passwordHash: '$2a$12$LJ3m4ys3Lk0TSwHnbfOMe.XP1tAsFzJQVmQKxOHpV0KXqGqYqGqYq',
        language: 'ar',
      },
    });

    await prisma.traderProfile.create({
      data: {
        userId: user.id,
        businessName: t.businessName,
        categoryId: cat.id,
        lat: t.lat,
        lng: t.lng,
      },
    });
  }

  console.log('Seeding deals...');
  const allTraders = await prisma.traderProfile.findMany({ include: { user: true } });
  const deals = [
    { trader: allTraders[0], titleAr: 'بروست دجاج مشكل', titleEn: 'Mixed Chicken Broast', descAr: 'وجبة بروست دجاج مشكل مع بطاطس ومشروب غازي', descEn: 'Mixed chicken broast meal with fries and soda', pct: 40, price: 89, expiry: '2026-07-01' },
    { trader: allTraders[0], titleAr: 'بيتزا عائلية كبيرة', titleEn: 'Large Family Pizza', descAr: 'بيتزا عائلية كبيرة بأي حشوة من اختيارك', descEn: 'Large family pizza with any topping of your choice', pct: 25, price: 65, expiry: '2026-06-15' },
    { trader: allTraders[1], titleAr: 'قص شعر وتصفيف', titleEn: 'Haircut & Styling', descAr: 'قص وتصفيف شعر مع منتجات عناية مجانية', descEn: 'Haircut and styling with free care products', pct: 30, price: 150, expiry: '2026-06-20' },
    { trader: allTraders[1], titleAr: 'باديكير فاخر', titleEn: 'Luxury Pedicure', descAr: 'جلسة باديكير فاخرة مع مساج للقدمين', descEn: 'Luxury pedicure session with foot massage', pct: 35, price: 200, expiry: '2026-06-25' },
    { trader: allTraders[2], titleAr: 'سماعات بلوتوث لاسلكية', titleEn: 'Wireless Bluetooth Earbuds', descAr: 'سماعات بلوتوث لاسلكية عالية الجودة مع علبة شحن', descEn: 'High quality wireless Bluetooth earbuds with charging case', pct: 45, price: 349, expiry: '2026-07-10' },
    { trader: allTraders[2], titleAr: 'حامل جوال ذكي', titleEn: 'Smart Phone Stand', descAr: 'حامل جوال ذكي قابل للتعديل لجميع الأحجام', descEn: 'Adjustable smart phone stand for all sizes', pct: 20, price: 79, expiry: '2026-06-18' },
    { trader: allTraders[3], titleAr: 'اشتراك شهر نادي رياضي', titleEn: '1-Month Gym Membership', descAr: 'اشتراك شهر كامل في النادي الرياضي مع مدرب شخصي', descEn: 'Full month gym membership with personal trainer', pct: 50, price: 600, expiry: '2026-06-30' },
    { trader: allTraders[3], titleAr: 'جلسة تدريب شخصي', titleEn: 'Personal Training Session', descAr: 'جلسة تدريب شخصي مع أحد أفضل المدربين', descEn: 'Personal training session with top coach', pct: 15, price: 120, expiry: '2026-07-05' },
    { trader: allTraders[4], titleAr: 'غسيل سيارات كامل', titleEn: 'Full Car Wash', descAr: 'غسيل سيارات كامل من الخارج والداخل مع تلميع', descEn: 'Full car wash inside and out with polishing', pct: 30, price: 80, expiry: '2026-06-22' },
    { trader: allTraders[4], titleAr: 'تلميع سيارات احترافي', titleEn: 'Professional Car Detailing', descAr: 'تلميع سيارات احترافي يشمل التلميع الداخلي والخارجي', descEn: 'Professional car detailing including interior and exterior', pct: 20, price: 250, expiry: '2026-07-15' },
  ];

  for (const d of deals) {
    if (!d.trader) continue;
    await prisma.deal.create({
      data: {
        traderId: d.trader.userId,
        categoryId: d.trader.categoryId,
        titleAr: d.titleAr,
        titleEn: d.titleEn,
        descriptionAr: d.descAr,
        descriptionEn: d.descEn,
        discountPct: d.pct,
        originalPrice: d.price,
        maxRedemptions: 50,
        expiryDate: new Date(d.expiry),
        tier: 'basic',
        status: 'active',
      },
    });
  }

  console.log('Seed complete!');
}

seed()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
