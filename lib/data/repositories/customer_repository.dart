import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(Dio());
});

class CustomerRepository {
  final Dio _dio;

  CustomerRepository(this._dio) {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  Future<Options> _getOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(
        ApiConstants.dashboard,
        options: options,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load dashboard');
      }
    } catch (e) {
      throw Exception('Failed to load dashboard: $e');
    }
  }

  Future<List<dynamic>> getTagihan({String? status}) async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(
        ApiConstants.tagihan,
        queryParameters: status != null ? {'status': status} : null,
        options: options,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load tagihan');
      }
    } catch (e) {
      throw Exception('Failed to load tagihan: $e');
    }
  }
}
