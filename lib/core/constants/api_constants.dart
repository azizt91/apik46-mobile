class ApiConstants {
  // Base URL - Change this based on your environment
  // Production URL
  static const String baseUrl = 'https://apikcorporation.my.id/api/mobile';
  
  // Auth Endpoints
  static const String login = '/login';
  static const String logout = '/logout';
  static const String me = '/me';
  
  // Customer Endpoints
  static const String dashboard = '/dashboard';
  static const String tagihan = '/tagihan';
  
  // Notification Endpoints
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String notificationsReadAll = '/notifications/read-all';
}
