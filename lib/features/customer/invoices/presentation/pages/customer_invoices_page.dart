import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:apik_mobile/core/theme/app_colors.dart';
import 'package:apik_mobile/data/providers/customer_provider.dart';

// Helper function to safely parse number from dynamic value
num _parseNum(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class CustomerInvoicesPage extends ConsumerStatefulWidget {
  final int initialTabIndex;
  final String? highlightInvoiceId;

  const CustomerInvoicesPage({
    super.key,
    this.initialTabIndex = 0,
    this.highlightInvoiceId,
  });

  @override
  ConsumerState<CustomerInvoicesPage> createState() => _CustomerInvoicesPageState();
}

class _CustomerInvoicesPageState extends ConsumerState<CustomerInvoicesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tagihan Saya'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Belum Lunas'),
            Tab(text: 'Riwayat Lunas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InvoiceList(status: 'BL'),
          _InvoiceList(status: 'LS'),
        ],
      ),
    );
  }
}

class _InvoiceList extends ConsumerWidget {
  final String status;

  const _InvoiceList({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagihanAsync = ref.watch(tagihanProvider(status));
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(tagihanProvider(status));
      },
      child: tagihanAsync.when(
        data: (tagihanList) {
          if (tagihanList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    status == 'BL' ? Icons.check_circle_outline : Icons.history,
                    size: 64,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    status == 'BL' ? 'Tidak ada tagihan belum lunas' : 'Belum ada riwayat pembayaran',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tagihanList.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = tagihanList[index];
              final isPaid = item['status'] == 'LS';
              final color = isPaid ? AppColors.success : AppColors.danger;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // TODO: Show detail or payment methods
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_getMonthName(_parseInt(item['bulan']))} ${item['tahun'] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isPaid ? 'Lunas' : 'Belum Dibayar',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                currencyFormat.format(_parseNum(item['tagihan'])),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                          if (isPaid && item['tgl_bayar'] != null) ...[
                            const Divider(height: 24),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Text(
                                  'Dibayar: ${item['tgl_bayar']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }
}
