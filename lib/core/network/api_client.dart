import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiClient {
  Future<String> _getBaseUrl() async {
    final custom = await SecureStorageService.getBaseUrl();
    if (custom != null && custom.isNotEmpty) {
      return custom.replaceAll(RegExp(r'/+$'), '');
    }
    return ApiConstants.defaultBaseUrl;
  }

  Future<Map<String, String>> _getHeaders({bool isMultipart = false}) async {
    final token = await SecureStorageService.getToken();
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    final baseUrl = await _getBaseUrl();
    var uri = Uri.parse('$baseUrl$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 25));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('ইন্টারনেট সংযোগ নেই। ইন্টারনেট চেক করে আবার চেষ্টা করুন।');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('সার্ভারের সাথে যোগাযোগ করা যাচ্ছে না: $e');
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final baseUrl = await _getBaseUrl();
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final headers = await _getHeaders();
      final response = await http
          .post(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(const Duration(seconds: 35));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('ইন্টারনেট সংযোগ নেই। ইন্টারনেট চেক করে আবার চেষ্টা করুন।');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('সার্ভার এরর: $e');
    }
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    final baseUrl = await _getBaseUrl();
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final headers = await _getHeaders();
      final response = await http
          .put(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(const Duration(seconds: 35));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('ইন্টারনেট সংযোগ নেই।');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('সার্ভার এরর: $e');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final baseUrl = await _getBaseUrl();
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final headers = await _getHeaders();
      final response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 20));
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('সার্ভার এরর: $e');
    }
  }

  Future<dynamic> uploadMultipart(String endpoint, File file, {String? altText}) async {
    final baseUrl = await _getBaseUrl();
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final headers = await _getHeaders(isMultipart: true);
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);

      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      if (altText != null && altText.isNotEmpty) {
        request.fields['alt_text'] = altText;
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('ইন্টারনেট সংযোগ নেই। ছবি আপলোড করা যায়নি।');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('ছবি আপলোডে সমস্যা হয়েছে: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 204) {
      return null;
    }

    dynamic decodedBody;
    try {
      decodedBody = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      decodedBody = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodedBody;
    }

    if (response.statusCode == 401) {
      throw ApiException('আপনার লগইন সেশন শেষ হয়ে গেছে। অনুগ্রহ করে আবার লগইন করুন।', 401);
    }

    if (response.statusCode == 403) {
      throw ApiException('আপনার এই কাজটি করার অনুমতি নেই।', 403);
    }

    if (response.statusCode == 422 && decodedBody is Map && decodedBody.containsKey('errors')) {
      final errors = decodedBody['errors'] as Map;
      final firstError = errors.values.first;
      if (firstError is List && firstError.isNotEmpty) {
        throw ApiException(firstError.first.toString(), 422);
      }
    }

    if (decodedBody is Map && decodedBody.containsKey('error')) {
      final err = decodedBody['error'];
      if (err is Map && err.containsKey('message')) {
        throw ApiException(err['message'].toString(), response.statusCode);
      }
    }

    if (decodedBody is Map && decodedBody.containsKey('message')) {
      throw ApiException(decodedBody['message'].toString(), response.statusCode);
    }

    throw ApiException('অনাকাঙ্ক্ষিত সমস্যা দেখা দিয়েছে (Status: ${response.statusCode})', response.statusCode);
  }
}
