import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apik_mobile/data/repositories/profile_repository.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dio = Dio();
  return ProfileRepository(dio);
});

// State notifier for profile updates
class ProfileUpdateNotifier extends StateNotifier<AsyncValue<void>> {
  final ProfileRepository _repository;

  ProfileUpdateNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> updateProfile({
    required String nama,
    required String email,
    required String whatsapp,
    required String alamat,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateProfile(
        nama: nama,
        email: email,
        whatsapp: whatsapp,
        alamat: alamat,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> uploadPhoto(XFile imageFile) async {
    state = const AsyncValue.loading();
    try {
      await _repository.uploadPhoto(imageFile);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final profileUpdateProvider = StateNotifierProvider<ProfileUpdateNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileUpdateNotifier(repository);
});
