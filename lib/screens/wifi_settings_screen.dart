import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class WiFiSettingsScreen extends StatefulWidget {
  const WiFiSettingsScreen({Key? key}) : super(key: key);

  @override
  State<WiFiSettingsScreen> createState() => _WiFiSettingsScreenState();
}

class _WiFiSettingsScreenState extends State<WiFiSettingsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _wifiData;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _loadWiFiSettings();
  }

  Future<void> _loadWiFiSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await _apiService.getWiFiSettings(token);
      
      if (response['success']) {
        setState(() {
          _wifiData = response['data'];
          _isLoading = false;
        });
        
        // Load history
        _loadHistory();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(
        msg: 'Gagal memuat data: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _loadHistory() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) return;

      final response = await _apiService.getWiFiHistory(token);
      
      if (response['success']) {
        setState(() {
          _history = response['data'];
        });
      }
    } catch (e) {
      // Silent fail for history
    }
  }

  Future<void> _showChangeSSIDDialog() async {
    final TextEditingController ssidController = TextEditingController(
      text: _wifiData?['ssid'] ?? '',
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama WiFi (SSID)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan nama WiFi baru:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ssidController,
              decoration: InputDecoration(
                labelText: 'SSID',
                hintText: 'Contoh: APIK-WiFi-001',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.wifi),
              ),
              maxLength: 32,
            ),
            const SizedBox(height: 8),
            const Text(
              '• Minimal 3 karakter\n'
              '• Maksimal 32 karakter\n'
              '• Hanya huruf, angka, - dan _',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newSSID = ssidController.text.trim();
              
              if (newSSID.isEmpty) {
                Fluttertoast.showToast(msg: 'SSID tidak boleh kosong');
                return;
              }
              
              if (newSSID.length < 3) {
                Fluttertoast.showToast(msg: 'SSID minimal 3 karakter');
                return;
              }

              Navigator.pop(context);
              await _changeSSID(newSSID);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeSSID(String newSSID) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await _apiService.changeWiFiSSID(token, newSSID);
      
      if (response['success']) {
        Fluttertoast.showToast(
          msg: 'SSID berhasil diubah',
          backgroundColor: Colors.green,
        );
        _loadWiFiSettings();
      } else {
        throw Exception(response['message'] ?? 'Gagal mengubah SSID');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool _obscurePassword = true;
    bool _obscureConfirm = true;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ubah Password WiFi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan password WiFi baru:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setDialogState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                maxLength: 63,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setDialogState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Minimal 8 karakter\n'
                '• Maksimal 63 karakter',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPassword = passwordController.text;
                final confirmPassword = confirmPasswordController.text;
                
                if (newPassword.isEmpty) {
                  Fluttertoast.showToast(msg: 'Password tidak boleh kosong');
                  return;
                }
                
                if (newPassword.length < 8) {
                  Fluttertoast.showToast(msg: 'Password minimal 8 karakter');
                  return;
                }
                
                if (newPassword != confirmPassword) {
                  Fluttertoast.showToast(msg: 'Password tidak cocok');
                  return;
                }

                Navigator.pop(context);
                await _changePassword(newPassword);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePassword(String newPassword) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await _apiService.changeWiFiPassword(token, newPassword);
      
      if (response['success']) {
        Fluttertoast.showToast(
          msg: 'Password WiFi berhasil diubah',
          backgroundColor: Colors.green,
        );
        _loadWiFiSettings();
      } else {
        throw Exception(response['message'] ?? 'Gagal mengubah password');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _showResetConfirmation() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset ke Default?'),
        content: const Text(
          'WiFi akan direset ke pengaturan default:\n\n'
          '• SSID: APIK-[ID]\n'
          '• Password: apik[ID]\n\n'
          'Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetToDefault();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetToDefault() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await _apiService.resetWiFiToDefault(token);
      
      if (response['success']) {
        Fluttertoast.showToast(
          msg: 'WiFi berhasil direset ke default',
          backgroundColor: Colors.green,
        );
        
        // Show new credentials
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('WiFi Direset'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pengaturan WiFi baru:'),
                const SizedBox(height: 12),
                _buildInfoRow('SSID', response['data']['ssid']),
                _buildInfoRow('Password', response['data']['password']),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        
        _loadWiFiSettings();
      } else {
        throw Exception(response['message'] ?? 'Gagal reset WiFi');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan WiFi'),
        backgroundColor: const Color(0xFF6B4CE6),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWiFiSettings,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Settings Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6B4CE6).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.wifi,
                                    color: Color(0xFF6B4CE6),
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pengaturan Saat Ini',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'WiFi Anda',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildSettingItem(
                              icon: Icons.wifi_tethering,
                              label: 'SSID (Nama WiFi)',
                              value: _wifiData?['ssid'] ?? 'Belum diatur',
                            ),
                            const SizedBox(height: 12),
                            _buildSettingItem(
                              icon: Icons.lock,
                              label: 'Password',
                              value: _wifiData?['password'] != null ? '••••••••' : 'Belum diatur',
                            ),
                            const SizedBox(height: 12),
                            _buildSettingItem(
                              icon: Icons.security,
                              label: 'Keamanan',
                              value: _wifiData?['security_type'] ?? 'WPA2-PSK',
                            ),
                            if (_wifiData?['last_changed'] != null) ...[
                              const SizedBox(height: 12),
                              _buildSettingItem(
                                icon: Icons.access_time,
                                label: 'Terakhir Diubah',
                                value: _formatDate(_wifiData!['last_changed']),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Action Buttons
                    const Text(
                      'Aksi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildActionButton(
                      icon: Icons.edit,
                      label: 'Ubah Nama WiFi (SSID)',
                      color: Colors.blue,
                      onTap: _showChangeSSIDDialog,
                    ),
                    const SizedBox(height: 8),
                    _buildActionButton(
                      icon: Icons.vpn_key,
                      label: 'Ubah Password WiFi',
                      color: Colors.green,
                      onTap: _showChangePasswordDialog,
                    ),
                    const SizedBox(height: 8),
                    _buildActionButton(
                      icon: Icons.refresh,
                      label: 'Reset ke Default',
                      color: Colors.orange,
                      onTap: _showResetConfirmation,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // History Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Riwayat Perubahan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: _loadHistory,
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    if (_history.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Belum ada riwayat perubahan',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ..._history.map((item) => _buildHistoryItem(item)).toList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    IconData icon;
    Color color;
    
    switch (item['type']) {
      case 'ssid':
        icon = Icons.wifi_tethering;
        color = Colors.blue;
        break;
      case 'password':
        icon = Icons.vpn_key;
        color = Colors.green;
        break;
      default:
        icon = Icons.settings;
        color = Colors.grey;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          item['type'] == 'ssid' ? 'Ubah SSID' : 'Ubah Password',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item['type'] == 'ssid')
              Text('${item['old_value']} → ${item['new_value']}'),
            Text(
              _formatDate(item['changed_at']),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(
            item['changed_by'] == 'customer' ? 'Anda' : 'Admin',
            style: const TextStyle(fontSize: 11),
          ),
          backgroundColor: item['changed_by'] == 'customer' 
              ? Colors.blue.withOpacity(0.1)
              : Colors.orange.withOpacity(0.1),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays == 0) {
        if (diff.inHours == 0) {
          return '${diff.inMinutes} menit yang lalu';
        }
        return '${diff.inHours} jam yang lalu';
      } else if (diff.inDays == 1) {
        return 'Kemarin';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} hari yang lalu';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }
}
