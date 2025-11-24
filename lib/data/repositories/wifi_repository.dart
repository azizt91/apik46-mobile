import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apik_mobile/core/constants/api_constants.dart';

class WiFiRepository {
  final Dio _dio;

  WiFiRepository(this._dio);

  Future<Map<String, dynamic>> getWiFiSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/wifi',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }

      throw Exception(response.data['message'] ?? 'Gagal mengambil data WiFi');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan');
    }
  }

  Future<void> changeSSID(String ssid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/wifi/change-ssid',
        data: {'ssid': ssid},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return;
      }

      throw Exception(response.data['message'] ?? 'Gagal mengubah SSID');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['errors'];
        throw Exception(errors?['ssid']?[0] ?? 'Validation error');
      }
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan');
    }
  }

  Future<void> changePassword(String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/wifi/change-password',
        data: {'password': password},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return;
      }

      throw Exception(response.data['message'] ?? 'Gagal mengubah password');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['errors'];
        throw Exception(errors?['password']?[0] ?? 'Validation error');
      }
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan');
    }
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/wifi/history',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }

      throw Exception(response.data['message'] ?? 'Gagal mengambil riwayat');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan');
    }
  }

  Future<void> deleteHistory(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await _dio.delete(
        '${ApiConstants.baseUrl}/wifi/history/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return;
      }

      throw Exception(response.data['message'] ?? 'Gagal menghapus riwayat');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan');
    }
  }
  
  Future<List<dynamic>> getConnectedDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/wifi/connected-devices',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] ?? [];
      }

      return [];
    } catch (e) {
      // Return empty list on error instead of throwing
      return [];
    }
  }
}
