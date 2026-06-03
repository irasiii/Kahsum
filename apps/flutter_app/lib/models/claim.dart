class ClaimRating {
  final String id;
  final int stars;
  final String? comment;

  const ClaimRating({required this.id, required this.stars, this.comment});

  factory ClaimRating.fromJson(Map<String, dynamic> json) => ClaimRating(
        id: json['id'] as String,
        stars: json['stars'] as int,
        comment: json['comment'] as String?,
      );
}

class ClaimCategory {
  final int id;
  final String nameEn;
  final String nameAr;
  final String icon;

  const ClaimCategory({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.icon,
  });

  factory ClaimCategory.fromJson(Map<String, dynamic> json) => ClaimCategory(
        id: json['id'] as int,
        nameEn: json['nameEn'] as String? ?? '',
        nameAr: json['nameAr'] as String? ?? '',
        icon: json['icon'] as String? ?? '',
      );
}

class ClaimTraderProfile {
  final String userId;
  final String businessName;
  final double? lat;
  final double? lng;

  const ClaimTraderProfile({
    required this.userId,
    required this.businessName,
    this.lat,
    this.lng,
  });

  factory ClaimTraderProfile.fromJson(Map<String, dynamic> json) =>
      ClaimTraderProfile(
        userId: json['userId'] as String,
        businessName: json['businessName'] as String,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
      );
}

class ClaimDeal {
  final String id;
  final String titleAr;
  final String titleEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final double originalPrice;
  final double discountPct;
  final String? imageUrl;
  final String expiryDate;
  final String status;
  final ClaimTraderProfile trader;
  final ClaimCategory category;

  const ClaimDeal({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    this.descriptionAr,
    this.descriptionEn,
    required this.originalPrice,
    required this.discountPct,
    this.imageUrl,
    required this.expiryDate,
    required this.status,
    required this.trader,
    required this.category,
  });

  factory ClaimDeal.fromJson(Map<String, dynamic> json) => ClaimDeal(
        id: json['id'] as String,
        titleAr: json['titleAr'] as String,
        titleEn: json['titleEn'] as String,
        descriptionAr: json['descriptionAr'] as String?,
        descriptionEn: json['descriptionEn'] as String?,
        originalPrice: (json['originalPrice'] as num).toDouble(),
        discountPct: (json['discountPct'] as num).toDouble(),
        imageUrl: json['imageUrl'] as String?,
        expiryDate: json['expiryDate'] as String,
        status: json['status'] as String,
        trader:
            ClaimTraderProfile.fromJson(json['trader'] as Map<String, dynamic>),
        category:
            ClaimCategory.fromJson(json['category'] as Map<String, dynamic>),
      );
}

class Claim {
  final String id;
  final String dealId;
  final String qrToken;
  final String status; // claimed | redeemed | expired
  final String claimedAt;
  final String? redeemedAt;
  final ClaimDeal deal;
  final ClaimRating? rating;

  const Claim({
    required this.id,
    required this.dealId,
    required this.qrToken,
    required this.status,
    required this.claimedAt,
    this.redeemedAt,
    required this.deal,
    this.rating,
  });

  factory Claim.fromJson(Map<String, dynamic> json) => Claim(
        id: json['id'] as String,
        dealId: json['dealId'] as String,
        qrToken: json['qrToken'] as String,
        status: json['status'] as String,
        claimedAt: json['claimedAt'] as String,
        redeemedAt: json['redeemedAt'] as String?,
        deal: ClaimDeal.fromJson(json['deal'] as Map<String, dynamic>),
        rating: json['rating'] != null
            ? ClaimRating.fromJson(
                json['rating'] as Map<String, dynamic>)
            : null,
      );
}
