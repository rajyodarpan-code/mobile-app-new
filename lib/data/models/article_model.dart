class MediaModel {
  final int id;
  final String url;
  final String? altText;
  final String? mimeType;

  MediaModel({required this.id, required this.url, this.altText, this.mimeType});

  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      url: json['url'] ?? json['file_url'] ?? '',
      altText: json['alt_text'],
      mimeType: json['mime_type'],
    );
  }
}

class ArticleModel {
  final String uuid;
  final String title;
  final String? slug;
  final String? content;
  final String? excerpt;
  final String? category;
  final List<String> tags;
  final String status;
  final String? seoTitle;
  final String? metaDescription;
  final String? focusKeyword;
  final String? imageAlt;
  final MediaModel? featuredMedia;
  final String? publishedAt;
  final String? updatedAt;
  final List<PublishingJobModel> publishingStatus;

  ArticleModel({
    required this.uuid,
    required this.title,
    this.slug,
    this.content,
    this.excerpt,
    this.category,
    this.tags = const [],
    required this.status,
    this.seoTitle,
    this.metaDescription,
    this.focusKeyword,
    this.imageAlt,
    this.featuredMedia,
    this.publishedAt,
    this.updatedAt,
    this.publishingStatus = const [],
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    final seo = json['seo'] is Map ? json['seo'] : {};
    
    List<PublishingJobModel> jobs = [];
    if (json['publishing_status'] is List) {
      jobs = (json['publishing_status'] as List)
          .map((item) => PublishingJobModel.fromJson(item))
          .toList();
    }

    return ArticleModel(
      uuid: json['uuid'] ?? '',
      title: json['title'] ?? '',
      slug: json['slug'],
      content: json['content'],
      excerpt: json['excerpt'],
      category: json['category'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      status: json['status'] ?? 'draft',
      seoTitle: seo['title'] ?? json['seo_title'],
      metaDescription: seo['meta_description'] ?? json['meta_description'],
      focusKeyword: seo['focus_keyword'] ?? json['focus_keyword'],
      imageAlt: json['image_alt'],
      featuredMedia: json['featured_media'] != null
          ? MediaModel.fromJson(json['featured_media'])
          : null,
      publishedAt: json['published_at'],
      updatedAt: json['updated_at'],
      publishingStatus: jobs,
    );
  }
}

class PublishingJobModel {
  final String? uuid;
  final String platform;
  final String status;
  final String? scheduledAt;
  final String? completedAt;
  final bool canRetry;
  final String? lastError;
  final String? externalUrl;

  PublishingJobModel({
    this.uuid,
    required this.platform,
    required this.status,
    this.scheduledAt,
    this.completedAt,
    this.canRetry = false,
    this.lastError,
    this.externalUrl,
  });

  factory PublishingJobModel.fromJson(Map<String, dynamic> json) {
    String? extUrl;
    if (json['publication'] is Map && json['publication']['external_url'] != null) {
      extUrl = json['publication']['external_url'];
    }

    return PublishingJobModel(
      uuid: json['uuid'],
      platform: json['platform'] ?? '',
      status: json['status'] ?? 'pending',
      scheduledAt: json['scheduled_at'],
      completedAt: json['completed_at'],
      canRetry: json['can_retry'] == true,
      lastError: json['last_error'],
      externalUrl: extUrl,
    );
  }
}
