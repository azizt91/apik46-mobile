import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apik_mobile/data/repositories/wifi_repository.dart';
import 'package:dio/dio.dart';

final wifiRepositoryProvider = Provider<WiFiRepository>((ref) {
  final dio = Dio(); 
  // Pastikan Anda sudah mengatur BaseOptions/Interceptors Dio secara global jika perlu
  return WiFiRepository(dio);
});

// Provider untuk mengambil data awal (GET)
final wifiSettingsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(wifiRepositoryProvider);
  return await repository.getWiFiSettings();
});

// Notifier untuk aksi Update (POST)
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
      rethrow; // Rethrow agar UI tahu ada error
    }
  }

  Future<void> changePassword(String password) async {
    state = const AsyncValue.loading();
    try {
      await _repository.changePassword(password);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final wifiUpdateProvider = StateNotifierProvider<WiFiUpdateNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(wifiRepositoryProvider);
  return WiFiUpdateNotifier(repository);
});