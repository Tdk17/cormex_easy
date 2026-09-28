class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.iconKey,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: (json['publicId'] ?? json['id'])?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      iconKey: (json['iconKey'] ?? json['icon'])?.toString() ?? 'services',
    );
  }

  final String id;
  final String name;
  final String slug;
  final String iconKey;
}

class _PublicCategoryRule {
  const _PublicCategoryRule(this.label, this.aliases);

  final String label;
  final Set<String> aliases;
}

const _publicCategoryRules = <_PublicCategoryRule>[
  _PublicCategoryRule('Eletricista', {'eletricista'}),
  _PublicCategoryRule('Encanador', {'encanador', 'encanamento'}),
  _PublicCategoryRule('Pintor', {'pintor', 'pintura'}),
  _PublicCategoryRule('Pedreiro', {'pedreiro'}),
  _PublicCategoryRule(
    'Diarista',
    {'diarista', 'limpeza', 'diarista-limpeza', 'limpeza-residencial'},
  ),
  _PublicCategoryRule('Jardinagem', {'jardinagem', 'jardineiro'}),
];

List<ServiceCategory> publicCatalogCategories(
  Iterable<ServiceCategory> categories,
) {
  final available = categories.toList(growable: false);
  final visible = <ServiceCategory>[];

  for (final rule in _publicCategoryRules) {
    ServiceCategory? match;
    for (final category in available) {
      final slug = _normalizeCategoryKey(category.slug);
      final name = _normalizeCategoryKey(category.name);
      if (rule.aliases.contains(slug) || rule.aliases.contains(name)) {
        match = category;
        break;
      }
    }
    if (match == null) continue;
    visible.add(
      ServiceCategory(
        id: match.id,
        name: rule.label,
        slug: match.slug,
        iconKey: match.iconKey,
      ),
    );
  }

  return List.unmodifiable(visible);
}

String _normalizeCategoryKey(String value) {
  var normalized = value.trim().toLowerCase();
  const replacements = <String, String>{
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
  };
  for (final replacement in replacements.entries) {
    normalized = normalized.replaceAll(replacement.key, replacement.value);
  }
  return normalized
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
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
    this.imageUrl,
  });

  factory ProviderProfile.fromJson(Map<String, dynamic> json) {
    final location = (json['location'] as Map?)?.cast<String, dynamic>() ?? {};
    final serviceArea =
        (json['serviceArea'] as Map?)?.cast<String, dynamic>() ?? {};
    final availability =
        (json['availability'] as Map?)?.cast<String, dynamic>() ?? {};
    return ProviderProfile(
      id: (json['publicId'] ?? json['id'])?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      category: ServiceCategory.fromJson(
        (json['category'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      description: json['description']?.toString() ?? '',
      city: (location['city'] ?? json['city'])?.toString() ?? '',
      state: (location['state'] ?? json['state'])?.toString() ?? '',
      whatsapp: json['whatsapp']?.toString() ?? '',
      providerType: json['providerType']?.toString() ?? 'Autônomo',
      services: (json['services'] as List? ?? []).map((e) => '$e').toList(),
      serviceArea: (serviceArea['label'] ?? json['serviceAreaLabel'] ??
              json['serviceArea'])
          ?.toString() ??
          '',
      availability: (availability['label'] ?? json['availabilityLabel'] ??
              json['availability'])
          ?.toString() ??
          '',
      isPro: json['isPro'] == true,
      isVerified: json['isVerified'] == true,
      isOpen24Hours:
          availability['isOpen24Hours'] == true || json['isOpen24Hours'] == true,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      imageUrl: (json['photoUrl'] ?? json['logoUrl'] ?? json['avatarUrl'])
          ?.toString(),
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
  final String? imageUrl;
}

class CatalogHomeData {
  const CatalogHomeData({
    required this.categories,
    required this.providers,
    required this.bannerTitle,
    required this.bannerSubtitle,
    this.reviewsEnabled = false,
    this.isFromCache = false,
  });

  final List<ServiceCategory> categories;
  final List<ProviderProfile> providers;
  final String bannerTitle;
  final String bannerSubtitle;
  final bool reviewsEnabled;
  final bool isFromCache;
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
