import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apik_mobile/data/repositories/wifi_repository.dart';
import 'package:dio/dio.dart';

final wifiRepositoryProvider = Provider<WiFiRepository>((ref) {
  final dio = Dio();
  return WiFiRepository(dio);
});

// WiFi settings provider
final wifiSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(wifiRepositoryProvider);
  return await repository.getWiFiSettings();
});

// WiFi history provider
final wifiHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(wifiRepositoryProvider);
  return await repository.getHistory();
});

// WiFi connected devices provider
final wifiConnectedDevicesProvider = FutureProvider<List<dynamic>>((ref) async {
  final repository = ref.watch(wifiRepositoryProvider);
  return await repository.getConnectedDevices();
});

// State notifier for WiFi updates
class WiFiUpdateNotifier extends StateNotifier<AsyncValue<void>> {
  final WiFiRepository _repository;

  WiFiUpdateNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> changeSSID(String ssid) async {
    state = const AsyncValue.loading();
    try {
      await _repository.changeSSID(ssid);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> changePassword(String password) async {
    state = const AsyncValue.loading();
    try {
      await _repository.changePassword(password);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteHistory(int id) async {
    // We don't set loading state here to avoid blocking the UI
    // The list will be refreshed after deletion
    try {
      await _repository.deleteHistory(id);
    } catch (e) {
      rethrow;
    }
  }
}

final wifiUpdateProvider = StateNotifierProvider<WiFiUpdateNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(wifiRepositoryProvider);
  return WiFiUpdateNotifier(repository);
});
