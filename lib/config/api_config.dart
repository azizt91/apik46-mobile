class ApiConfig {
  // Base URL
  static const String baseUrl = 'https://apikcorporation.my.id/api/mobile';
  // static const String baseUrl = 'http://10.0.2.2/apik46/public/api/mobile'; // For Android Emulator
  // static const String baseUrl = 'http://localhost/apik46/public/api/mobile'; // For iOS Simulator
  
  // Timeout
  static const Duration timeout = Duration(seconds: 30);
  
  // Endpoints
  static const String login = '/login';
  static const String logout = '/logout';
  static const String me = '/me';
  static const String dashboard = '/dashboard';
  static const String tagihan = '/tagihan';
  static const String riwayat = '/riwayat';
  static const String wifi = '/wifi';
  static const String wifiChangeSSID = '/wifi/change-ssid';
  static const String wifiChangePassword = '/wifi/change-password';
  static const String wifiHistory = '/wifi/history';
  static const String wifiResetDefault = '/wifi/reset-default';
  static const String paymentMethods = '/payment-methods';
  
  // Headers
  static Map<String, String> headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
