import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/article_model.dart';

class DashboardProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  int _publishedCount = 0;
  int _draftCount = 0;
  int _scheduledCount = 0;
  int _failedCount = 0;

  List<ArticleModel> _recentPublished = [];
  List<ArticleModel> _recentEdited = [];

  bool _isLoading = false;
  String? _errorMessage;

  int get publishedCount => _publishedCount;
  int get draftCount => _draftCount;
  int get scheduledCount => _scheduledCount;
  int get failedCount => _failedCount;

  List<ArticleModel> get recentPublished => _recentPublished;
  List<ArticleModel> get recentEdited => _recentEdited;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSummary() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.get(ApiConstants.mobileSummary);
      if (res != null && res['data'] != null) {
        final data = res['data'];
        final counts = data['counts'] ?? {};

        _publishedCount = counts['published'] ?? 0;
        _draftCount = counts['drafts'] ?? 0;
        _scheduledCount = counts['scheduled'] ?? 0;
        _failedCount = counts['failed'] ?? 0;

        if (data['recent_published'] is List) {
          _recentPublished = (data['recent_published'] as List)
              .map((item) => ArticleModel.fromJson(item))
              .toList();
        }

        if (data['recent_edited'] is List) {
          _recentEdited = (data['recent_edited'] as List)
              .map((item) => ArticleModel.fromJson(item))
              .toList();
        }
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
