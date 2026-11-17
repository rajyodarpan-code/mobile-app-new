class ApiConstants {
  // Base URLs
  static const String defaultBaseUrl = 'https://rajyodarpan.in/admin_rajyo';
  static const String apiV1Prefix = '/api/v1';

  // Auth endpoints
  static const String login = '$apiV1Prefix/auth/login';
  static const String logout = '$apiV1Prefix/auth/logout';
  static const String user = '$apiV1Prefix/auth/user';
  static const String refresh = '$apiV1Prefix/auth/refresh';

  // Dashboard endpoints
  static const String mobileSummary = '$apiV1Prefix/analytics/mobile-summary';

  // Article endpoints
  static const String articles = '$apiV1Prefix/articles';
  static String articleDetail(String uuid) => '$apiV1Prefix/articles/$uuid';
  static String publishArticle(String uuid) => '$apiV1Prefix/articles/$uuid/publish';
  static String publishStatus(String uuid) => '$apiV1Prefix/articles/$uuid/publish/status';
  static String retryPublish(String uuid, dynamic jobId) => '$apiV1Prefix/articles/$uuid/publish/retry/$jobId';
  static String cancelPublish(String uuid, dynamic jobId) => '$apiV1Prefix/articles/$uuid/publish/cancel/$jobId';

  // Media endpoints
  static const String mediaUpload = '$apiV1Prefix/media/upload';

  // Platform endpoints
  static const String platforms = '$apiV1Prefix/platforms';
  static String platformCategories(dynamic platformId) => '$apiV1Prefix/platforms/$platformId/categories';
  static String platformTags(dynamic platformId) => '$apiV1Prefix/platforms/$platformId/tags';
  static String platformStatus(dynamic platformId) => '$apiV1Prefix/platforms/$platformId/status';

  // Schedules
  static const String schedules = '$apiV1Prefix/schedules';
  static const String upcomingSchedules = '$apiV1Prefix/schedules/upcoming';
  static String scheduleDetail(dynamic id) => '$apiV1Prefix/schedules/$id';
}
