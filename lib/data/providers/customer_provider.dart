import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apik_mobile/data/repositories/customer_repository.dart';

final dashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(customerRepositoryProvider);
  return repository.getDashboard();
});

final tagihanProvider = FutureProvider.family.autoDispose<List<dynamic>, String?>((ref, status) async {
  final repository = ref.watch(customerRepositoryProvider);
  return repository.getTagihan(status: status);
});
