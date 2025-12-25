import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:apik_mobile/core/theme/app_colors.dart';
import 'package:apik_mobile/data/providers/customer_provider.dart';
import 'package:apik_mobile/data/providers/auth_provider.dart';
import 'package:apik_mobile/data/providers/notification_provider.dart';
import 'package:apik_mobile/features/customer/payment/presentation/widgets/payment_modal.dart';

// Helper function to safely parse number from dynamic value
num _parseNum(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}

class CustomerDashboardPage extends ConsumerWidget {
  const CustomerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
        },
        child: dashboardAsync.when(
          data: (data) {
            final pelanggan = data['pelanggan'] as Map<String, dynamic>? ?? {};
            final paket = data['paket'] as Map<String, dynamic>?;
            final summary = data['summary'] as Map<String, dynamic>? ?? {
              'unpaid': {'count': 0, 'total': 0},
              'paid': {'count': 0, 'total': 0},
            };
            final currentBill = data['current_month_bill'] as Map<String, dynamic>?;

            return CustomScrollView(
              slivers: [
                // Sticky Header
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  elevation: 0,
                  backgroundColor: Colors.white,
                  toolbarHeight: 70,
                  automaticallyImplyLeading: false,
                  title: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage: pelanggan['profile_picture'] != null
                            ? NetworkImage(pelanggan['profile_picture'])
                            : null,
                        child: pelanggan['profile_picture'] == null
                            ? Text(
                                (pelanggan['nama'] as String?)?.isNotEmpty == true
                                    ? pelanggan['nama'][0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Halo, ${pelanggan['nama'] ?? 'Pelanggan'}!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _NotificationIconButton(),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () => _showLogoutDialog(context, ref),
                        color: Colors.black87,
                      ),
                    ],
                  ),
                ),

                // Content
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Total Tagihan Card
                      _buildTotalTagihanCard(context, currentBill, currencyFormat),
                      
                      const SizedBox(height: 16),
                      
                      // Paket Aktif Card
                      if (paket != null)
                        _buildPaketAktifCard(paket, currencyFormat),
                      
                      const SizedBox(height: 24),
                      
                      // Riwayat Pembayaran Section
                      _buildRiwayatSection(context, summary, currencyFormat),
                      
                      const SizedBox(height: 80), // Bottom padding for nav
                    ]),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Memuat data...'),
              ],
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                  const SizedBox(height: 16),
                  Text(
                    error.toString().replaceAll('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(dashboardProvider),
                    child: const Text('Coba Lagi'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.read(authControllerProvider).logout(),
                    child: const Text('Logout'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push('/debug'),
                    style: TextButton.styleFrom(foregroundColor: Colors.orange),
                    child: const Text('🐛 Debug Info'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tidak'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authControllerProvider).logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTotalTagihanCard(BuildContext context, Map<String, dynamic>? bill, NumberFormat currencyFormat) {
    final isPaid = bill?['status'] == 'LS';
    final statusColor = isPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final statusBgColor = isPaid ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2);
    final statusText = isPaid ? 'Sudah Dibayar' : 'Belum Dibayar';
    final amount = _parseNum(bill?['tagihan']);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Tagihan Bulan Ini',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(amount),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isPaid && bill != null)
                ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => PaymentModal(bill: bill),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF135BEC),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0xFF135BEC).withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Bayar Sekarang',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaketAktifCard(Map<String, dynamic> paket, NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Paket Aktif',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: const [
                  Icon(
                    Icons.wifi,
                    size: 20,
                    color: Color(0xFF135BEC),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Terhubung',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF135BEC),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 12),
          Text(
            paket['nama_paket'] ?? 'Paket Tidak Diketahui',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${currencyFormat.format(_parseNum(paket['harga']))} / bulan',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatSection(BuildContext context, Map<String, dynamic> summary, NumberFormat currencyFormat) {
    final unpaid = summary['unpaid'] as Map<String, dynamic>? ?? {'count': 0, 'total': 0};
    final paid = summary['paid'] as Map<String, dynamic>? ?? {'count': 0, 'total': 0};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ringkasan Tagihan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {
                context.go('/customer/invoices');
              },
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF135BEC),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSummaryItem(
                'Belum Lunas',
                (unpaid['count'] ?? 0).toString(),
                currencyFormat.format(_parseNum(unpaid['total'])),
                const Color(0xFFEF4444),
                Icons.warning_amber_rounded,
                isFirst: true,
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: const Color(0xFFE2E8F0),
              ),
              _buildSummaryItem(
                'Lunas',
                (paid['count'] ?? 0).toString(),
                currencyFormat.format(_parseNum(paid['total'])),
                const Color(0xFF10B981),
                Icons.check_circle,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    String title,
    String count,
    String total,
    Color color,
    IconData icon, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count tagihan',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            total,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// Notification Icon with Badge
class _NotificationIconButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);

    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined),
          unreadCountAsync.when(
            data: (count) {
              if (count == 0) return const SizedBox.shrink();
              return Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      onPressed: () => context.push('/customer/notifications'),
      color: Colors.black87,
    );
  }
}
