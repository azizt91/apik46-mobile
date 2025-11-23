import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apik_mobile/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class ProfileRepository {
  final Dio _dio;

  ProfileRepository(this._dio);

  Future<Map<String, dynamic>> updateProfile({
    required String nama,
    required String email,
    required String whatsapp,
    required String alamat,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await _dio.put(
        '${ApiConstants.baseUrl}/profile',
        data: {
          'nama': nama,
          'email': email,
          'whatsapp': whatsapp,
          'alamat': alamat,
        },
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

      throw Exception(response.data['message'] ?? 'Gagal update profile');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['errors'];
        throw Exception(errors?.values.first[0] ?? 'Validation error');
      }
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan');
    }
  }

  Future<String> uploadPhoto(File imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final baseUrlWithoutMobile = ApiConstants.baseUrl.replaceAll('/mobile', '');
      final uri = Uri.parse('$baseUrlWithoutMobile/mobile/profile/photo');

      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      
      request.files.add(await http.MultipartFile.fromPath('photo', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = response.body;
        // Parse JSON manually if needed
        return data; // Return photo URL
      }

      throw Exception('Gagal upload foto');
    } catch (e) {
      throw Exception('Error upload foto: $e');
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await _dio.put(
        '${ApiConstants.baseUrl}/profile/password',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmPassword,
        },
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

      throw Exception(response.data['message'] ?? 'Gagal ganti password');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        throw Exception(e.response?.data['message'] ?? 'Password lama tidak sesuai');
      }
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan');
    }
  }
}
