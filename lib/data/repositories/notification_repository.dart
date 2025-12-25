import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(Dio());
});

class NotificationRepository {
  final Dio _dio;

  NotificationRepository(this._dio) {
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

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(
        ApiConstants.notifications,
        options: options,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      debugPrint('NotificationRepository: Error getting notifications: $e');
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(
        ApiConstants.notificationsUnreadCount,
        options: options,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['unread_count'] ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('NotificationRepository: Error getting unread count: $e');
      return 0;
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      final options = await _getOptions();
      final response = await _dio.post(
        '${ApiConstants.notifications}/$notificationId/read',
        options: options,
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint('NotificationRepository: Error marking as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final options = await _getOptions();
      final response = await _dio.post(
        ApiConstants.notificationsReadAll,
        options: options,
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint('NotificationRepository: Error marking all as read: $e');
      return false;
    }
  }

  Future<bool> deleteAll() async {
    try {
      final options = await _getOptions();
      final response = await _dio.delete(
        ApiConstants.notificationsDeleteAll,
        options: options,
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint('NotificationRepository: Error deleting all: $e');
      return false;
    }
  }
}
