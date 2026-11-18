import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rajyo_darpan_publisher/core/network/api_client.dart';
import 'package:rajyo_darpan_publisher/core/constants/api_constants.dart';
import 'package:rajyo_darpan_publisher/data/models/article_model.dart';
import 'package:rajyo_darpan_publisher/data/models/category_model.dart';

class ArticleProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<ArticleModel> _articles = [];
  List<CategoryModel> _categories = [];
  List<TagModel> _tags = [];
  List<PlatformAccountModel> _platforms = [];

  PlatformAccountModel? _selectedPlatform;
  bool _isLoading = false;
  String? _errorMessage;

  List<ArticleModel> get articles => _articles;
  List<CategoryModel> get categories => _categories;
  List<TagModel> get tags => _tags;
  List<PlatformAccountModel> get platforms => _platforms;
  PlatformAccountModel? get selectedPlatform => _selectedPlatform;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchArticles({String? status, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final query = <String, String>{};
      if (status != null && status.isNotEmpty && status != 'all') {
        query['status'] = status;
      }
      if (search != null && search.isNotEmpty) {
        query['search'] = search;
      }

      final res = await _apiClient.get(ApiConstants.articles, queryParams: query);
      if (res != null && res['data'] is List) {
        _articles = (res['data'] as List)
            .map((item) => ArticleModel.fromJson(item))
            .toList();
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchPlatformsAndTaxonomies() async {
    try {
      final res = await _apiClient.get(ApiConstants.platforms);
      if (res != null && res['data'] is List) {
        _platforms = (res['data'] as List)
            .map((item) => PlatformAccountModel.fromJson(item))
            .where((p) => p.isActive)
            .toList();

        // Default to wordpress platform
        _selectedPlatform = _platforms.firstWhere(
          (p) => p.platform == 'wordpress',
          orElse: () => _platforms.isNotEmpty ? _platforms.first : PlatformAccountModel(id: 1, platform: 'wordpress', accountName: 'Rajyo Darpan', isActive: true),
        );

        if (_selectedPlatform != null) {
          await fetchTaxonomiesForPlatform(_selectedPlatform!.id);
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchTaxonomiesForPlatform(int platformId) async {
    try {
      // Categories
      final catRes = await _apiClient.get(ApiConstants.platformCategories(platformId));
      if (catRes != null && catRes['data'] is List) {
        _categories = (catRes['data'] as List)
            .map((c) => CategoryModel.fromJson(c))
            .toList();
      }

      // Tags
      final tagRes = await _apiClient.get(ApiConstants.platformTags(platformId));
      if (tagRes != null && tagRes['data'] is List) {
        _tags = (tagRes['data'] as List)
            .map((t) => TagModel.fromJson(t))
            .toList();
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<MediaModel?> uploadImage(File imageFile, {String? altText}) async {
    try {
      final res = await _apiClient.uploadMultipart(
        ApiConstants.mediaUpload,
        imageFile,
        altText: altText,
      );
      if (res != null && res['data'] != null) {
        return MediaModel.fromJson(res['data']);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<ArticleModel?> saveOrUpdateArticle({
    String? uuid,
    required String title,
    required String content,
    String? excerpt,
    String? slug,
    String? category,
    List<String>? tags,
    int? featuredMediaId,
    String? seoTitle,
    String? metaDescription,
    String? focusKeyword,
    String? imageAlt,
    String? imageCaption,
    bool isBreaking = false,
    bool isFeatured = false,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'content': content,
      'excerpt': excerpt,
      'slug': slug,
      'category': category,
      'tags': tags,
      'featured_media_id': featuredMediaId,
      'seo_title': seoTitle,
      'meta_description': metaDescription,
      'focus_keyword': focusKeyword,
      'image_alt': imageAlt,
      'workflow_type': 'manual',
    };

    // Platform specific flags & metadata (WordPress specific)
    final wpData = <String, dynamic>{
      'is_breaking_news': isBreaking ? '1' : '0',
      'is_homepage_hero': isFeatured ? '1' : '0',
    };
    if (imageAlt != null && imageAlt.isNotEmpty) {
      wpData['image_alt'] = imageAlt;
    }
    if (imageCaption != null && imageCaption.isNotEmpty) {
      wpData['image_caption'] = imageCaption;
    }

    body['platform_content'] = {
      'wordpress': wpData,
    };

    try {
      dynamic res;
      if (uuid != null && uuid.isNotEmpty) {
        res = await _apiClient.put(ApiConstants.articleDetail(uuid), body: body);
      } else {
        res = await _apiClient.post(ApiConstants.articles, body: body);
      }

      if (res != null && res['data'] != null) {
        final saved = ArticleModel.fromJson(res['data']);
        await fetchArticles();
        return saved;
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<bool> publishArticle({
    required String uuid,
    DateTime? scheduleAt,
    String status = 'publish',
  }) async {
    if (_selectedPlatform == null) {
      await fetchPlatformsAndTaxonomies();
    }

    final platformId = _selectedPlatform?.id ?? 1;

    final body = {
      'platforms': [
        {
          'platform_account_id': platformId,
          'schedule_at': scheduleAt?.toIso8601String(),
          'status': status,
        }
      ]
    };

    try {
      final res = await _apiClient.post(ApiConstants.publishArticle(uuid), body: body);
      await fetchArticles();
      return res != null;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> retryPublish(String uuid, dynamic jobId) async {
    try {
      final res = await _apiClient.post(ApiConstants.retryPublish(uuid, jobId));
      await fetchArticles();
      return res != null;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteArticle(String uuid) async {
    try {
      await _apiClient.delete(ApiConstants.articleDetail(uuid));
      _articles.removeWhere((a) => a.uuid == uuid);
      notifyListeners();
      return true;
    } catch (e) {
      rethrow;
    }
  }
}
