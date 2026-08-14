import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        ApiService.authToken = token;
        await _fetchUserProfile();
      }
    } catch (e) {
      print('Failed to restore session: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Private helper to load profile and sync FCM tokens.
  Future<void> _fetchUserProfile() async {
    try {
      final UserModel? profile = await _apiService.getUserProfile();
      if (profile != null) {
        _currentUser = profile;
        
        // Fetch and register FCM token
        final String? fcmToken = await _notificationService.getFcmToken();
        if (fcmToken != null && fcmToken.isNotEmpty) {
          await _apiService.registerFcmToken(fcmToken);
          _currentUser = _currentUser?.copyWith(fcmToken: fcmToken);
        }
      } else {
        _errorMessage = 'Failed to load user profile from server.';
        await signOut();
      }
    } catch (e) {
      _errorMessage = 'Error loading session: $e';
      await signOut();
    }
  }

  /// Initiates password-based login and synchronizes with Backend.
  Future<bool> signInWithUsernameAndPassword(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.loginWithUsernameAndPassword(username, password);
      if (response != null && response['success'] == true) {
        final String token = response['token'];
        ApiService.authToken = token;

        // Save token to SharedPreferences for persistent session
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        _currentUser = UserModel.fromJson(response['user']);
        
        // Sync FCM token in the background
        final String? fcmToken = await _notificationService.getFcmToken();
        if (fcmToken != null && fcmToken.isNotEmpty) {
          await _apiService.registerFcmToken(fcmToken);
          _currentUser = _currentUser?.copyWith(fcmToken: fcmToken);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid username or password.';
      }
    } catch (e) {
      print('Login error: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Toggle locally bookmarked notice IDs list.
  void toggleLocalBookmark(String noticeId, bool isBookmarked) {
    if (_currentUser == null) return;
    
    final List<String> updatedBookmarks = List.from(_currentUser!.bookmarks);
    if (isBookmarked) {
      if (!updatedBookmarks.contains(noticeId)) {
        updatedBookmarks.add(noticeId);
      }
    } else {
      updatedBookmarks.remove(noticeId);
    }
    
    _currentUser = _currentUser!.copyWith(bookmarks: updatedBookmarks);
    notifyListeners();
  }

  /// Marks a notice as read on the backend and updates local user profile state.
  Future<void> markAsRead(String noticeId) async {
    if (_currentUser == null) return;
    if (_currentUser!.readNotices.contains(noticeId)) return; // already read

    // Optimistically update local user state
    final List<String> updatedRead = List.from(_currentUser!.readNotices)..add(noticeId);
    _currentUser = _currentUser!.copyWith(readNotices: updatedRead);
    notifyListeners();

    try {
      await _apiService.markNoticeAsRead(noticeId);
    } catch (e) {
      print('Failed to sync read status for notice $noticeId: $e');
    }
  }

  /// Perform sign-out operations.
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      
      ApiService.authToken = null;
      _currentUser = null;
    } catch (e) {
      _errorMessage = 'Sign out failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
