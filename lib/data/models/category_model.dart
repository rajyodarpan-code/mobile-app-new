class CategoryModel {
  final int id;
  final String name;
  final String slug;

  CategoryModel({required this.id, required this.name, required this.slug});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }
}

class TagModel {
  final int id;
  final String name;
  final String slug;

  TagModel({required this.id, required this.name, required this.slug});

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }
}

class PlatformAccountModel {
  final int id;
  final String platform;
  final String accountName;
  final bool isActive;

  PlatformAccountModel({
    required this.id,
    required this.platform,
    required this.accountName,
    required this.isActive,
  });

  factory PlatformAccountModel.fromJson(Map<String, dynamic> json) {
    return PlatformAccountModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      platform: json['platform'] ?? '',
      accountName: json['account_name'] ?? json['platform'] ?? '',
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }
}
