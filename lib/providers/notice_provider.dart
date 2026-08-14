import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notice.dart';
import '../services/api_service.dart';

class NoticeProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Notice> _notices = [];
  List<Notice> _searchResults = [];
  bool _isLoading = false;
  String _selectedCategory = 'Unread';
  
  // Local read notices set (saved in SharedPreferences)
  Set<String> _readNoticeIds = {};
  
  // Cache of AI summaries to prevent redundant API calls
  final Map<String, String> _aiSummaries = {};

  List<Notice> get notices {
    if (_selectedCategory == 'Read') {
      return _notices.where((n) => _readNoticeIds.contains(n.id)).toList();
    }
    // Default to 'Unread' (Not Read)
    return _notices.where((n) => !_readNoticeIds.contains(n.id)).toList();
  }

  List<Notice> get allNotices => _notices;
  List<Notice> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  Set<String> get readNoticeIds => _readNoticeIds;

  NoticeProvider() {
    _loadLocalCache();
  }

  /// Initial load of local cache (notices and read status).
  Future<void> _loadLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load read notice IDs
      final List<String>? readList = prefs.getStringList('read_notice_ids');
      if (readList != null) {
        _readNoticeIds = readList.toSet();
      }

      // Load cached notices
      final String? cachedJson = prefs.getString('cached_notices');
      if (cachedJson != null) {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        _notices = decoded.map((x) => Notice.fromJson(x)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading notice local cache: $e');
    }
  }

  /// Saves current notice feed to local storage for offline access.
  Future<void> _saveNoticesToCache(List<Notice> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonStr = jsonEncode(list.map((x) => x.toJson()).toList());
      await prefs.setString('cached_notices', jsonStr);
    } catch (e) {
      print('Error saving notices to local cache: $e');
    }
  }

  /// Refresh and fetch notices from backend.
  Future<void> refreshNotices() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<Notice> fetched = await _apiService.fetchNotices();
      if (fetched.isNotEmpty) {
        _notices = fetched;
        await _saveNoticesToCache(fetched);
      }
    } catch (e) {
      print('Notice fetch failed, using offline cache if available: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set the category filter.
  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Searches notices by queries.
  Future<void> search(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _searchResults = await _apiService.searchNotices(query);
    } catch (e) {
      print('Search failed: $e');
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marks a notice as read.
  Future<void> markAsRead(String noticeId, String userId) async {
    if (_readNoticeIds.contains(noticeId)) return;
    
    _readNoticeIds.add(noticeId);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('read_notice_ids_$userId', _readNoticeIds.toList());
      
      // Sync read status to backend database
      await _apiService.markNoticeAsRead(noticeId);
    } catch (e) {
      print('Error saving read status: $e');
    }
  }

  /// Toggles read/unread status.
  Future<void> toggleReadStatus(String noticeId, String userId) async {
    final bool isCurrentlyRead = _readNoticeIds.contains(noticeId);
    if (isCurrentlyRead) {
      _readNoticeIds.remove(noticeId);
    } else {
      _readNoticeIds.add(noticeId);
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('read_notice_ids_$userId', _readNoticeIds.toList());
      
      if (!isCurrentlyRead) {
        await _apiService.markNoticeAsRead(noticeId);
      }
    } catch (e) {
      print('Error updating read status: $e');
    }
  }

  /// Clears the local read cache and loads user-specific read statuses from both server and local storage.
  Future<void> loadUserReadNotices(String userId, List<String> serverReadIds) async {
    // Reset cache to server-side read list first to isolate from previous users
    _readNoticeIds = serverReadIds.toSet();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load user-scoped cache
      final List<String>? localList = prefs.getStringList('read_notice_ids_$userId');
      if (localList != null) {
        _readNoticeIds.addAll(localList);
        notifyListeners();
      }

      // Save the merged list back
      await prefs.setStringList('read_notice_ids_$userId', _readNoticeIds.toList());
    } catch (e) {
      print('Error loading user read notices: $e');
    }
  }

  /// Retrieves cached AI summary or fetches one from backend.
  Future<String> fetchAiSummary(String noticeId, String noticeBody) async {
    if (_aiSummaries.containsKey(noticeId)) {
      return _aiSummaries[noticeId]!;
    }

    try {
      final String? summary = await _apiService.getAiSummary(noticeBody);
      if (summary != null) {
        _aiSummaries[noticeId] = summary;
        notifyListeners();
        return summary;
      }
    } catch (e) {
      print('Failed to load AI summary: $e');
    }
    return 'Summary unavailable.';
  }

  /// Add/Remove bookmark via ApiService and update UI.
  Future<void> toggleBookmark(String noticeId, bool isBookmarked, Function(String, bool) onAuthUpdate) async {
    // Optimistic UI update
    onAuthUpdate(noticeId, isBookmarked);

    try {
      final bool success = await _apiService.toggleBookmark(noticeId, isBookmarked);
      if (!success) {
        // Revert on failure
        onAuthUpdate(noticeId, !isBookmarked);
      }
    } catch (e) {
      // Revert on failure
      onAuthUpdate(noticeId, !isBookmarked);
      print('Failed to toggle bookmark: $e');
    }
  }

  /// Trigger a manual sync on the server.
  Future<Map<String, dynamic>> triggerSync() async {
    final result = await _apiService.triggerManualSync();
    if (result['success'] == true) {
      await refreshNotices();
    }
    return result;
  }
}
