import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apik_mobile/data/repositories/bank_repository.dart';
import 'package:dio/dio.dart';

final bankRepositoryProvider = Provider<BankRepository>((ref) {
  final dio = Dio();
  return BankRepository(dio);
});

final banksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final bankRepository = ref.watch(bankRepositoryProvider);
  return await bankRepository.getBanks();
});
