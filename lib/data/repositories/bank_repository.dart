import 'package:apik_mobile/core/constants/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BankRepository {
  final Dio _dio;

  BankRepository(this._dio);

  Future<List<Map<String, dynamic>>> getBanks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Token tidak ditemukan, silakan login kembali');
      }
      
      // Bank endpoint is at /api/bank (not under /api/mobile)
      final baseUrlWithoutMobile = ApiConstants.baseUrl.replaceAll('/mobile', '');
      
      final response = await _dio.get(
        '$baseUrlWithoutMobile/bank',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Response format: {"data": [...]}
        final dynamic responseData = response.data;
        
        if (responseData is Map && responseData['data'] != null) {
          final List<dynamic> banksData = responseData['data'];
          return banksData.map((bank) => bank as Map<String, dynamic>).toList();
        } else if (responseData is List) {
          return responseData.map((bank) => bank as Map<String, dynamic>).toList();
        }
      }

      throw Exception('Gagal mengambil data bank');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Sesi berakhir, silakan login kembali');
      }
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan');
    }
  }
}
