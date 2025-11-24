import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apik_mobile/core/theme/app_colors.dart';
import 'package:apik_mobile/data/providers/wifi_provider.dart';
import 'package:intl/intl.dart';

class WifiSettingsPage extends ConsumerStatefulWidget {
  const WifiSettingsPage({super.key});

  @override
  ConsumerState<WifiSettingsPage> createState() => _WifiSettingsPageState();
}

class _WifiSettingsPageState extends ConsumerState<WifiSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final ssid = _ssidController.text.trim();
    final password = _passwordController.text.trim();

    if (ssid.isEmpty && password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal isi salah satu: SSID atau Password'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      // Change SSID if filled
      if (ssid.isNotEmpty) {
        await ref.read(wifiUpdateProvider.notifier).changeSSID(ssid);
      }

      // Change password if filled
      if (password.isNotEmpty) {
        await ref.read(wifiUpdateProvider.notifier).changePassword(password);
      }

      if (!mounted) return;

      // Refresh WiFi settings
      ref.invalidate(wifiSettingsProvider);
      ref.invalidate(wifiHistoryProvider);

      // Clear form
      _ssidController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan WiFi berhasil diubah'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wifiAsync = ref.watch(wifiSettingsProvider);
    final historyAsync = ref.watch(wifiHistoryProvider);
    final connectedDevicesAsync = ref.watch(wifiConnectedDevicesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: const Text('Pengaturan WiFi'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark, // Dark icons for light background
          statusBarBrightness: Brightness.light, // For iOS
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(wifiSettingsProvider);
          ref.invalidate(wifiHistoryProvider);
          ref.invalidate(wifiConnectedDevicesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Section
              _buildInfoSection(),
              
              const SizedBox(height: 16),
              
              // Current WiFi Info
              wifiAsync.when(
                data: (wifi) => _buildCurrentWiFiInfo(wifi),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorCard(error.toString()),
              ),
              
              const SizedBox(height: 16),
              
              // Connected Devices
              _buildConnectedDevicesSection(connectedDevicesAsync),
              
              const SizedBox(height: 24),
              
              // Change Form
              _buildChangeForm(),
              
              const SizedBox(height: 24),
              
              // History Section
              _buildHistorySection(historyAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Informasi Penting',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem('Perubahan SSID dan password akan diterapkan ke router WiFi Anda'),
          _buildInfoItem('Proses perubahan membutuhkan waktu 1-2 menit'),
          _buildInfoItem('Setelah berhasil, hubungkan ulang perangkat Anda ke WiFi dengan nama dan password baru'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.blue[700])),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.blue[900]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWiFiInfo(Map<String, dynamic> wifi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi WiFi Saat Ini',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _buildWiFiInfoRow(Icons.wifi, 'Nama WiFi (SSID)', wifi['ssid'] ?? '-'),
          const SizedBox(height: 12),
          _buildWiFiInfoRow(Icons.lock_outline, 'Password WiFi', wifi['password'] ?? '-'),
          const SizedBox(height: 12),
          _buildWiFiInfoRow(Icons.router, 'IP Address', wifi['ip_address'] ?? '-'),
        ],
      ),
    );
  }

  Widget _buildWiFiInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedDevicesSection(AsyncValue<List<dynamic>> devicesAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.devices, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Perangkat Terhubung',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () {
                  ref.invalidate(wifiConnectedDevicesProvider);
                },
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          devicesAsync.when(
            data: (devices) {
              if (devices.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Icon(Icons.wifi_off, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada perangkat terhubung',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return Column(
                children: [
                  ...devices.map((device) => _buildDeviceItem(device)).toList(),
                  const SizedBox(height: 8),
                  Text(
                    'Total: ${devices.length} perangkat',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Gagal memuat data perangkat',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceItem(Map<String, dynamic> device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_android, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  device['device_name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDeviceInfoRow('IP', device['ip_address'] ?? '-'),
          const SizedBox(height: 4),
          _buildDeviceInfoRow('MAC', device['mac_address'] ?? '-'),
          const SizedBox(height: 4),
          _buildDeviceInfoRow('Type', device['type'] ?? '-'),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 12)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChangeForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ganti SSID & Password',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            
            // SSID Field
            TextFormField(
              controller: _ssidController,
              decoration: InputDecoration(
                labelText: 'Nama WiFi Baru (SSID)',
                hintText: 'Contoh: WiFi_Rumah-Saya (opsional)',
                helperText: 'Kosongkan jika tidak ingin mengubah SSID',
                helperMaxLines: 2,
                prefixIcon: const Icon(Icons.wifi),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (value.length < 3) {
                    return 'SSID minimal 3 karakter';
                  }
                  if (value.length > 32) {
                    return 'SSID maksimal 32 karakter';
                  }
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password WiFi Baru',
                hintText: 'Minimal 8 karakter (opsional)',
                helperText: 'Kosongkan jika tidak ingin mengubah password. Minimal 8 karakter jika diisi',
                helperMaxLines: 2,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (value.length < 8) {
                    return 'Password minimal 8 karakter';
                  }
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Confirm Password Field
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Konfirmasi Password',
                hintText: 'Ketik ulang password (jika diisi)',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (_passwordController.text.isNotEmpty) {
                  if (value != _passwordController.text) {
                    return 'Password tidak sama';
                  }
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Simpan Perubahan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(AsyncValue<List<Map<String, dynamic>>> historyAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riwayat Perubahan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          historyAsync.when(
            data: (history) {
              if (history.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Belum ada riwayat perubahan',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                );
              }
              
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length > 5 ? 5 : history.length,
                separatorBuilder: (context, index) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final item = history[index];
                  return _buildHistoryItem(item);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text(
                'Gagal memuat riwayat',
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final type = item['type'] ?? '';
    final status = item['status'] ?? 'success';
    final description = item['description'] ?? '';
    final newValue = item['new_value'] ?? '';
    final changedAt = item['changed_at'] != null 
        ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(item['changed_at']))
        : '-';
    
    IconData icon;
    Color iconColor;
    String title;
    
    if (type == 'ssid') {
      icon = Icons.wifi;
      iconColor = Colors.blue;
      title = 'Ganti SSID';
    } else if (type == 'password') {
      icon = Icons.lock_outline;
      iconColor = Colors.orange;
      title = 'Ganti Password';
    } else {
      icon = Icons.refresh;
      iconColor = Colors.green;
      title = 'Reset ke Default';
    }

    // Status styling
    Color statusColor;
    String statusText;
    if (status == 'success') {
      statusColor = Colors.green;
      statusText = 'Berhasil';
    } else if (status == 'processing') {
      statusColor = Colors.orange;
      statusText = 'Diproses';
    } else {
      statusColor = Colors.red;
      statusText = 'Gagal';
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _deleteHistory(item['id']),
                        child: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (newValue.isNotEmpty && type == 'ssid') ...[
                const SizedBox(height: 2),
                Text(
                  newValue,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
              if (description.isNotEmpty && status == 'failed') ...[
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                changedAt,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red[900]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteHistory(int id) async {
    try {
      await ref.read(wifiUpdateProvider.notifier).deleteHistory(id);
      ref.invalidate(wifiHistoryProvider);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Riwayat berhasil dihapus'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}
