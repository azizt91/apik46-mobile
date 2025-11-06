import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/pelanggan.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  
  Pelanggan? _user;
  bool _isLoading = false;
  String? _errorMessage;
  
  Pelanggan? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  
  // Initialize - Check if user is already logged in
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final token = await _authService.getToken();
      if (token != null) {
        _apiService.setToken(token);
        final cachedUser = await _authService.getUser();
        if (cachedUser != null) {
          _user = cachedUser;
          // Refresh user data from server
          await getMe();
        }
      }
    } catch (e) {
      debugPrint('Initialize error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.login(email, password);
      
      if (response.data['success'] == true) {
        final token = response.data['data']['token'];
        final userData = response.data['data']['pelanggan'];
        
        // Save token and user data
        await _authService.saveToken(token);
        _user = Pelanggan.fromJson(userData);
        await _authService.saveUser(_user!);
        
        // Set token for future requests
        _apiService.setToken(token);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.data['message'] ?? 'Login gagal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      if (e.response != null) {
        _errorMessage = e.response!.data['message'] ?? 'Login gagal';
      } else {
        _errorMessage = 'Koneksi gagal. Periksa internet Anda.';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Get current user
  Future<void> getMe() async {
    try {
      final response = await _apiService.getMe();
      
      if (response.data['success'] == true) {
        _user = Pelanggan.fromJson(response.data['data']);
        await _authService.saveUser(_user!);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Get me error: $e');
    }
  }
  
  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _apiService.logout();
    } catch (e) {
      debugPrint('Logout API error: $e');
    } finally {
      // Clear local data regardless of API call result
      await _authService.clearAuth();
      _apiService.removeToken();
      _user = null;
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
