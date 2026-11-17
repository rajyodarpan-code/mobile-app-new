import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rajyo_darpan_publisher/core/network/api_client.dart';
import 'package:rajyo_darpan_publisher/core/constants/api_constants.dart';
import 'package:rajyo_darpan_publisher/core/storage/secure_storage_service.dart';
import 'package:rajyo_darpan_publisher/data/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;

  Future<bool> sendOtp(String email, {String? customUrl}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (customUrl != null && customUrl.trim().isNotEmpty) {
        await SecureStorageService.saveBaseUrl(customUrl.trim());
      }

      await _apiClient.post(
        ApiConstants.sendOtp,
        body: {'email': email.trim()},
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.post(
        ApiConstants.verifyOtp,
        body: {
          'email': email.trim(),
          'otp': otp.trim(),
          'device_name': 'RajyoDarpan_Android_App',
        },
      );

      if (res != null && res['data'] != null) {
        final token = res['data']['token'];
        final userData = res['data']['user'];

        await SecureStorageService.saveToken(token);
        _currentUser = UserModel.fromJson(userData);
        await SecureStorageService.saveUserData(jsonEncode(_currentUser!.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      }

      throw ApiException('ওটিপি যাচাই করা যায়নি।');
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> checkAuthStatus() async {
    final token = await SecureStorageService.getToken();
    if (token == null || token.isEmpty) {
      _currentUser = null;
      notifyListeners();
      return;
    }

    try {
      final userJson = await SecureStorageService.getUserData();
      if (userJson != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
        notifyListeners();
      }

      // Refresh from server
      final res = await _apiClient.get(ApiConstants.user);
      if (res != null && res['data'] != null) {
        _currentUser = UserModel.fromJson(res['data']);
        await SecureStorageService.saveUserData(jsonEncode(_currentUser!.toJson()));
        notifyListeners();
      }
    } catch (e) {
      // If unauthorized, clear
      if (e is ApiException && e.statusCode == 401) {
        await logout();
      }
    }
  }

  Future<bool> login(String email, String password, {String? customUrl}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (customUrl != null && customUrl.trim().isNotEmpty) {
        await SecureStorageService.saveBaseUrl(customUrl.trim());
      }

      final res = await _apiClient.post(
        ApiConstants.login,
        body: {
          'email': email.trim(),
          'password': password,
          'device_name': 'RajyoDarpan_Android_App',
        },
      );

      if (res != null && res['data'] != null) {
        final token = res['data']['token'];
        final userData = res['data']['user'];

        await SecureStorageService.saveToken(token);
        _currentUser = UserModel.fromJson(userData);
        await SecureStorageService.saveUserData(jsonEncode(_currentUser!.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      }

      throw ApiException('লগইন সম্পন্ন করা যায়নি।');
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConstants.logout);
    } catch (_) {}

    await SecureStorageService.clearAll();
    _currentUser = null;
    notifyListeners();
  }
}
