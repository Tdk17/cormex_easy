class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.iconKey,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      iconKey: json['icon']?.toString() ?? 'services',
    );
  }

  final String id;
  final String name;
  final String slug;
  final String iconKey;
}

class ProviderProfile {
  const ProviderProfile({
    required this.id,
    required this.slug,
    required this.displayName,
    required this.category,
    required this.description,
    required this.city,
    required this.state,
    required this.whatsapp,
    required this.providerType,
    required this.services,
    required this.serviceArea,
    required this.availability,
    this.isPro = false,
    this.isVerified = false,
    this.isOpen24Hours = false,
    this.rating,
    this.reviewCount = 0,
    this.distanceKm,
  });

  factory ProviderProfile.fromJson(Map<String, dynamic> json) {
    return ProviderProfile(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      category: ServiceCategory.fromJson(
        (json['category'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      description: json['description']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      whatsapp: json['whatsapp']?.toString() ?? '',
      providerType: json['providerType']?.toString() ?? 'Autônomo',
      services: (json['services'] as List? ?? []).map((e) => '$e').toList(),
      serviceArea: json['serviceArea']?.toString() ?? '',
      availability: json['availability']?.toString() ?? '',
      isPro: json['isPro'] == true,
      isVerified: json['isVerified'] == true,
      isOpen24Hours: json['isOpen24Hours'] == true,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }

  final String id;
  final String slug;
  final String displayName;
  final ServiceCategory category;
  final String description;
  final String city;
  final String state;
  final String whatsapp;
  final String providerType;
  final List<String> services;
  final String serviceArea;
  final String availability;
  final bool isPro;
  final bool isVerified;
  final bool isOpen24Hours;
  final double? rating;
  final int reviewCount;
  final double? distanceKm;
}

class CatalogHomeData {
  const CatalogHomeData({
    required this.categories,
    required this.providers,
    required this.bannerTitle,
    required this.bannerSubtitle,
    this.reviewsEnabled = false,
  });

  final List<ServiceCategory> categories;
  final List<ProviderProfile> providers;
  final String bannerTitle;
  final String bannerSubtitle;
  final bool reviewsEnabled;
}

enum SubscriptionStatus {
  trial,
  active,
  pending,
  pastDue,
  cancelled,
  suspended,
  expired,
}

class EligiblePlan {
  const EligiblePlan({
    required this.id,
    required this.name,
    required this.priceLabel,
    required this.cycleLabel,
    required this.benefits,
    this.isRecommended = false,
    this.trialDays = 0,
  });

  final String id;
  final String name;
  final String priceLabel;
  final String cycleLabel;
  final List<String> benefits;
  final bool isRecommended;
  final int trialDays;
}

