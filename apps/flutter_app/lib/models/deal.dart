class Trader {
  final String userId;
  final String businessName;
  final String? address;
  final double? lat;
  final double? lng;
  final String? logoUrl;
  final double ratingAvg;

  Trader({
    required this.userId,
    required this.businessName,
    this.address,
    this.lat,
    this.lng,
    this.logoUrl,
    this.ratingAvg = 0,
  });

  factory Trader.fromJson(Map<String, dynamic> json) {
    return Trader(
      userId: json['userId'] as String,
      businessName: json['businessName'] as String,
      address: json['address'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      logoUrl: json['logoUrl'] as String?,
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Category {
  final int id;
  final String slug;
  final String nameEn;
  final String nameAr;
  final String icon;

  Category({
    required this.id,
    required this.slug,
    required this.nameEn,
    required this.nameAr,
    required this.icon,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      slug: json['slug'] as String,
      nameEn: json['nameEn'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
    );
  }
}

class Deal {
  final String id;
  final String titleAr;
  final String titleEn;
  final String? descriptionAr; // nullable — optional in schema
  final String? descriptionEn;
  final double discountPct; // Float in Postgres, never cast as int
  final double originalPrice;
  final String? imageUrl;
  final int maxRedemptions;
  final int redeemedCount;
  final String expiryDate;
  final String tier;
  final String status;
  final Trader trader;
  final Category category;

  Deal({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    this.descriptionAr,
    this.descriptionEn,
    required this.discountPct,
    required this.originalPrice,
    this.imageUrl,
    required this.maxRedemptions,
    required this.redeemedCount,
    required this.expiryDate,
    required this.tier,
    required this.status,
    required this.trader,
    required this.category,
  });

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      id: json['id'] as String,
      titleAr: json['titleAr'] as String,
      titleEn: json['titleEn'] as String,
      descriptionAr: json['descriptionAr'] as String?,
      descriptionEn: json['descriptionEn'] as String?,
      discountPct: (json['discountPct'] as num).toDouble(),
      originalPrice: (json['originalPrice'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      maxRedemptions: json['maxRedemptions'] as int,
      redeemedCount: json['redeemedCount'] as int,
      expiryDate: json['expiryDate'] as String,
      tier: json['tier'] as String,
      status: json['status'] as String,
      trader: Trader.fromJson(json['trader'] as Map<String, dynamic>),
      category: Category.fromJson(json['category'] as Map<String, dynamic>),
    );
  }
}
