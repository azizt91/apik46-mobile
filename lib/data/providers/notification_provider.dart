import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/notification_repository.dart';

// Provider for unread count - auto refresh
final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getUnreadCount();
});

// Provider for notification list
final notificationListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotifications();
});

// Controller for notification actions
final notificationControllerProvider = Provider<NotificationController>((ref) {
  return NotificationController(ref);
});

class NotificationController {
  final Ref _ref;

  NotificationController(this._ref);

  Future<bool> markAsRead(int notificationId) async {
    final repository = _ref.read(notificationRepositoryProvider);
    final result = await repository.markAsRead(notificationId);
    if (result) {
      // Refresh both providers
      _ref.invalidate(unreadNotificationCountProvider);
      _ref.invalidate(notificationListProvider);
    }
    return result;
  }

  Future<bool> markAllAsRead() async {
    final repository = _ref.read(notificationRepositoryProvider);
    final result = await repository.markAllAsRead();
    if (result) {
      // Refresh both providers
      _ref.invalidate(unreadNotificationCountProvider);
      _ref.invalidate(notificationListProvider);
    }
    return result;
  }

  void refresh() {
    _ref.invalidate(unreadNotificationCountProvider);
    _ref.invalidate(notificationListProvider);
  }
}
