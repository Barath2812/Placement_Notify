import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/notice_provider.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushEnabled = true;
  String _fcmToken = 'Loading token...';
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
    _fetchFcmToken();
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool('notifications_push_enabled') ?? true;
    });
  }

  Future<void> _fetchFcmToken() async {
    final token = await _notificationService.getFcmToken();
    setState(() {
      _fcmToken = token ?? 'Failed to retrieve FCM token';
    });
  }

  Future<void> _togglePushNotifications(bool value) async {
    setState(() {
      _pushEnabled = value;
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_push_enabled', value);

    if (value) {
      await _notificationService.subscribeToTopic('college-notices');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscribed to notifications topic.')),
        );
      }
    } else {
      // Firebase Messaging doesn't have a direct unsubscribe API in basic client,
      // but we mock or call unsubscribe.
      await FirebaseMessaging.instance.unsubscribeFromTopic('college-notices');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unsubscribed from notifications topic.')),
        );
      }
    }
  }

  void _copyTokenToClipboard() {
    Clipboard.setData(ClipboardData(text: _fcmToken));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('FCM token copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final noticeProvider = Provider.of<NoticeProvider>(context);

    final String name = authProvider.currentUser?.name ?? '';
    final String email = authProvider.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 12),
          
          // User Card Profile Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Header: Preferences
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'PREFERENCES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
          ),

          // Notification Toggle
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive alerts for placement drives & exam updates'),
              value: _pushEnabled,
              onChanged: _togglePushNotifications,
              activeColor: AppColors.primary,
            ),
          ),

          // Cache Clearing
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.delete_sweep_outlined, color: Colors.amber),
              title: const Text('Clear Read Notice History'),
              subtitle: const Text('Mark all notices as unread'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('read_notice_ids');
                noticeProvider.readNoticeIds.clear();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Read history cleared successfully.')),
                  );
                }
              },
            ),
          ),

          const SizedBox(height: 24),

          // Header: Diagnostics
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'DEVELOPER DIAGNOSTICS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
          ),

          // FCM Token Copy Info
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.key, color: Colors.blueGrey),
              title: const Text('FCM Device Token'),
              subtitle: Text(
                _fcmToken,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
              trailing: const Icon(Icons.copy, size: 20),
              onTap: _copyTokenToClipboard,
            ),
          ),

          const SizedBox(height: 32),

          // Log Out button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.red),
                foregroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Log Out Account', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                await authProvider.signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
