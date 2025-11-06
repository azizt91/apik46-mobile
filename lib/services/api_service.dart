import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../config/api_config.dart';

class ApiService {
  late final Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      headers: ApiConfig.headers(),
    ));
    
    // Add logger for debugging
    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
    ));
  }
  
  // Set token for authenticated requests
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
  
  // Remove token
  void removeToken() {
    _dio.options.headers.remove('Authorization');
  }
  
  // Login
  Future<Response> login(String email, String password) async {
    try {
      return await _dio.post(
        ApiConfig.login,
        data: {
          'email': email,
          'password': password,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
  
  // Get current user
  Future<Response> getMe() async {
    try {
      return await _dio.get(ApiConfig.me);
    } catch (e) {
      rethrow;
    }
  }
  
  // Logout
  Future<Response> logout() async {
    try {
      return await _dio.post(ApiConfig.logout);
    } catch (e) {
      rethrow;
    }
  }
  
  // Get dashboard data
  Future<Response> getDashboard() async {
    try {
      return await _dio.get(ApiConfig.dashboard);
    } catch (e) {
      rethrow;
    }
  }
  
  // Get tagihan list
  Future<Response> getTagihan({String? status}) async {
    try {
      return await _dio.get(
        ApiConfig.tagihan,
        queryParameters: status != null ? {'status': status} : null,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  // Get tagihan detail
  Future<Response> getTagihanDetail(int id) async {
    try {
      return await _dio.get('${ApiConfig.tagihan}/$id');
    } catch (e) {
      rethrow;
    }
  }
  
  // Get riwayat pembayaran
  Future<Response> getRiwayat() async {
    try {
      return await _dio.get(ApiConfig.riwayat);
    } catch (e) {
      rethrow;
    }
  }
  
  // Get WiFi settings
  Future<Response> getWiFiSettings() async {
    try {
      return await _dio.get(ApiConfig.wifi);
    } catch (e) {
      rethrow;
    }
  }
  
  // Change WiFi SSID
  Future<Response> changeWiFiSSID(String ssid) async {
    try {
      return await _dio.post(
        ApiConfig.wifiChangeSSID,
        data: {'ssid': ssid},
      );
    } catch (e) {
      rethrow;
    }
  }
  
  // Change WiFi Password
  Future<Response> changeWiFiPassword(String password, String passwordConfirmation) async {
    try {
      return await _dio.post(
        ApiConfig.wifiChangePassword,
        data: {
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
  
  // Get WiFi change history
  Future<Response> getWiFiHistory() async {
    try {
      return await _dio.get(ApiConfig.wifiHistory);
    } catch (e) {
      rethrow;
    }
  }
  
  // Reset WiFi to default
  Future<Response> resetWiFiDefault() async {
    try {
      return await _dio.post(ApiConfig.wifiResetDefault);
    } catch (e) {
      rethrow;
    }
  }
  
  // Get payment methods
  Future<Response> getPaymentMethods() async {
    try {
      return await _dio.get(ApiConfig.paymentMethods);
    } catch (e) {
      rethrow;
    }
  }
}
