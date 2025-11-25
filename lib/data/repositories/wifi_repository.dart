import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apik_mobile/core/constants/api_constants.dart';

class WiFiRepository {
  final Dio _dio;

  WiFiRepository(this._dio);

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Sesi berakhir, silakan login kembali');
    return token;
  }

  Future<Map<String, dynamic>> getWiFiSettings() async {
    try {
      final token = await _getToken();
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/wifi',
        options: Options(
          headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Gagal mengambil data WiFi');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal terhubung ke server');
    }
  }

  Future<void> changeSSID(String ssid) async {
    try {
      final token = await _getToken();
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/wifi/change-ssid',
        data: {'ssid': ssid},
        options: Options(
          headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return;
      }
      throw Exception(response.data['message'] ?? 'Gagal mengubah SSID');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['errors'];
        throw Exception(errors?['ssid']?[0] ?? 'Validasi gagal');
      }
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan server');
    }
  }

  Future<void> changePassword(String password) async {
    try {
      final token = await _getToken();
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/wifi/change-password',
        data: {'password': password},
        options: Options(
          headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return;
      }
      throw Exception(response.data['message'] ?? 'Gagal mengubah password');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['errors'];
        throw Exception(errors?['password']?[0] ?? 'Validasi gagal');
      }
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan server');
    }
  }
}