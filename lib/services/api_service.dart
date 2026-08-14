import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/notice.dart';
import '../models/user_model.dart';

class ApiService {
  static String? authToken;

  /// Helper to generate common headers including the JWT token.
  Future<Map<String, String>> _getHeaders() async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    
    return headers;
  }

  /// Sends the username and password to the backend for verification or auto-registration.
  Future<Map<String, dynamic>?> loginWithUsernameAndPassword(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Authentication failed.');
      }
    } catch (e) {
      print('Error logging in: $e');
      rethrow;
    }
  }

  /// Restores session using the JWT auth token.
  Future<UserModel?> getUserProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/me'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['user'] != null) {
          return UserModel.fromJson(data['user']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  /// Fetches notice lists, with optional category filtering.
  Future<List<Notice>> fetchNotices({String? category}) async {
    try {
      final headers = await _getHeaders();
      String url = ApiConfig.noticesEndpoint;
      if (category != null && category.isNotEmpty) {
        url += '?category=$category';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['notices'] != null) {
          return (data['notices'] as List)
              .map((json) => Notice.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching notices: $e');
      return [];
    }
  }

  /// Fetches a single notice by its Firestore ID.
  Future<Notice?> fetchNoticeById(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.noticesEndpoint}/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['notice'] != null) {
          return Notice.fromJson(data['notice']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching notice details: $e');
      return null;
    }
  }

  /// Searches notices by keywords.
  Future<List<Notice>> searchNotices(String query) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.noticesEndpoint}/search?q=${Uri.encodeComponent(query)}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['notices'] != null) {
          return (data['notices'] as List)
              .map((json) => Notice.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error searching notices: $e');
      return [];
    }
  }

  /// Registers user's FCM device token with backend.
  Future<bool> registerFcmToken(String fcmToken) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.fcmTokenEndpoint),
        headers: headers,
        body: jsonEncode({'fcmToken': fcmToken}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error registering FCM token: $e');
      return false;
    }
  }

  /// Bookmarks or removes bookmark for a notice.
  Future<bool> toggleBookmark(String noticeId, bool isBookmarked) async {
    try {
      final headers = await _getHeaders();
      final url = '${ApiConfig.bookmarksEndpoint}/$noticeId';
      
      final http.Response response;
      if (isBookmarked) {
        response = await http.post(Uri.parse(url), headers: headers);
      } else {
        response = await http.delete(Uri.parse(url), headers: headers);
      }

      return response.statusCode == 200;
    } catch (e) {
      print('Error toggling bookmark: $e');
      return false;
    }
  }

  /// Triggers a manual sync pipeline on the server (Admin feature).
  Future<Map<String, dynamic>> triggerManualSync() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.noticesEndpoint}/sync-now'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('Error triggering manual sync: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Request notice summary from AI summarizer.
  Future<String?> getAiSummary(String noticeBody) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.noticesEndpoint}/summarize'),
        headers: headers,
        body: jsonEncode({'body': noticeBody}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['summary'];
        }
      }
      return null;
    } catch (e) {
      print('Error fetching AI summary: $e');
      return null;
    }
  }

  /// Marks a notice as read on the backend database.
  Future<bool> markNoticeAsRead(String noticeId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/users/read/$noticeId'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking notice as read: $e');
      return false;
    }
  }
}
