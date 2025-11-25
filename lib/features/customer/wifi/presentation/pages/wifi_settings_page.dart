import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apik_mobile/core/theme/app_colors.dart';
import 'package:apik_mobile/data/providers/wifi_provider.dart';

class WifiSettingsPage extends ConsumerStatefulWidget {
  const WifiSettingsPage({super.key});

  @override
  ConsumerState<WifiSettingsPage> createState() => _WifiSettingsPageState();
}

class _WifiSettingsPageState extends ConsumerState<WifiSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // State variables
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isInitialized = false;
  String? _currentSSID; // Untuk mengecek apakah SSID benar-benar berubah

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    // 1. Validasi Form Frontend
    if (!_formKey.currentState!.validate()) return;

    final newSsid = _ssidController.text.trim();
    final newPassword = _passwordController.text.trim();

    // 2. Cek apakah ada perubahan nyata
    final isSsidChanged = newSsid.isNotEmpty && newSsid != _currentSSID;
    final isPasswordChanged = newPassword.isNotEmpty;

    if (!isSsidChanged && !isPasswordChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada perubahan yang dilakukan')),
      );
      return;
    }

    // 3. Konfirmasi Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simpan Perubahan?'),
        content: const Text(
          'Koneksi WiFi Anda akan terputus sebentar. Setelah berhasil, Anda perlu menghubungkan ulang perangkat ke WiFi baru.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Ya, Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 4. Eksekusi API
    try {
      final notifier = ref.read(wifiUpdateProvider.notifier);

      // Skenario A: Hanya Ganti SSID
      if (isSsidChanged) {
        await notifier.changeSSID(newSsid);
      }

      // Skenario B: Ganti Password (bisa berjalan setelah SSID, atau sendiri)
      if (isPasswordChanged) {
        await notifier.changePassword(newPassword);
      }

      if (!mounted) return;

      // Sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan WiFi berhasil diubah. Router akan restart.'),
          backgroundColor: AppColors.success,
        ),
      );

      // Refresh Data & Bersihkan Form Password
      ref.invalidate(wifiSettingsProvider);
      _passwordController.clear();
      _confirmPasswordController.clear();
      
      // Update current SSID agar tidak dianggap berubah lagi
      if (isSsidChanged) {
        setState(() {
          _currentSSID = newSsid;
        });
      }

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
    final isUpdating = ref.watch(wifiUpdateProvider).isLoading;

    // Logic Pre-fill data
    wifiAsync.whenData((wifi) {
      if (!_isInitialized && wifi['ssid'] != null) {
        _ssidController.text = wifi['ssid'];
        _currentSSID = wifi['ssid']; // Simpan state awal
        _isInitialized = true;
      }
    });

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
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _isInitialized = false;
          ref.invalidate(wifiSettingsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoSection(),
              const SizedBox(height: 16),
              
              wifiAsync.when(
                data: (wifi) => _buildChangeForm(wifi, isUpdating),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => _buildErrorCard(error.toString()),
              ),
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
              Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Informasi Penting',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem('Kosongkan kolom Password jika hanya ingin mengubah nama WiFi.'),
          _buildInfoItem('Perubahan membutuhkan waktu 1-2 menit hingga router restart.'),
          _buildInfoItem('Setelah berhasil, Anda harus login ulang ke WiFi baru.'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.blue[900], height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeForm(Map<String, dynamic> wifi, bool isUpdating) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... (Bagian Header Icon Router sama seperti sebelumnya) ...
             Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.router, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Konfigurasi WiFi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // SSID Field
            const Text('Nama WiFi (SSID)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _ssidController,
              enabled: !isUpdating,
              decoration: InputDecoration(
                hintText: 'Masukkan Nama WiFi Baru',
                prefixIcon: const Icon(Icons.wifi),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Nama WiFi tidak boleh kosong';
                if (value.length < 3) return 'SSID minimal 3 karakter';
                return null;
              },
            ),
            
            const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider()),
            
            const Text('Ganti Password (Opsional)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            
            // Password Field
            TextFormField(
              controller: _passwordController,
              enabled: !isUpdating,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password Baru',
                hintText: 'Kosongkan jika tidak ingin mengubah',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty && value.length < 8) {
                  return 'Password minimal 8 karakter';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Confirm Password Field
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _passwordController,
              builder: (context, value, child) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                
                return TextFormField(
                  controller: _confirmPasswordController,
                  enabled: !isUpdating,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password Baru',
                    prefixIcon: const Icon(Icons.verified_user),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                  validator: (confirmValue) {
                    if (_passwordController.text.isNotEmpty && confirmValue != _passwordController.text) {
                      return 'Password tidak sama';
                    }
                    return null;
                  },
                );
              },
            ),

            const SizedBox(height: 24),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isUpdating ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isUpdating 
                  ? const SizedBox(
                      height: 20, width: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Simpan Perubahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
              ),
            ),
          ],
        ),
      ),
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
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 48),
          const SizedBox(height: 12),
          Text(
            'Gagal Memuat Data',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[900]),
          ),
          const SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center, style: TextStyle(color: Colors.red[900])),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(wifiSettingsProvider),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}