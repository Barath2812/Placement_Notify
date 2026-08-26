import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? get _fcm {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseMessaging.instance;
      }
    } catch (_) {}
    return null;
  }

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Callback when a notification is tapped, sending the noticeId
  void Function(String noticeId)? onNotificationTap;

  /// High importance notification channel definition for Android 8.0+
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'campus_notices_channel', 
    'Campus Notices', 
    description: 'Notifications for new college announcements and updates.',
    importance: Importance.max,
    playSound: true,
  );

  /// Initializes both FCM streams and local notification displays.
  Future<void> init() async {
    final fcm = _fcm;
    if (fcm == null) {
      print('Firebase not initialized. NotificationService runs in mock mode.');
      return;
    }

    // 1. Request notification permissions (required for iOS and Android 13+)
    await requestPermissions();

    // 2. Local Notifications Setup
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final String? payload = response.payload;
        if (payload != null && payload.isNotEmpty && onNotificationTap != null) {
          onNotificationTap!(payload);
        }
      },
    );

    // Create high importance channel for Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3. Configure FCM Callbacks
    
    // Foreground Messages: Shows notification popups using local notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground notification received: ${message.messageId}');
      _showLocalNotification(message);
    });

    // Background Taps: Fires when app is running in background and tapped
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification tapped from background state: ${message.messageId}');
      _handleMessageTap(message);
    });

    // Terminated Taps: Fires when app was completely closed and launched via notification tap
    final RemoteMessage? initialMessage = await fcm.getInitialMessage();
    if (initialMessage != null) {
      print('Notification tapped from terminated state: ${initialMessage.messageId}');
      // Delayed slightly to allow router initialization
      Future.delayed(const Duration(seconds: 1), () {
        _handleMessageTap(initialMessage);
      });
    }

    // 4. Subscribe to topic
    await subscribeToTopic('college-notices');
  }

  /// Request permissions dynamically.
  Future<void> requestPermissions() async {
    final fcm = _fcm;
    if (fcm == null) return;
    
    await fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  /// Subscribes the device to college-notices topic.
  Future<void> subscribeToTopic(String topic) async {
    final fcm = _fcm;
    if (fcm == null) return;

    try {
      await fcm.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic $topic: $e');
    }
  }

  /// Fetches FCM token for client logging.
  Future<String?> getFcmToken() async {
    final fcm = _fcm;
    if (fcm == null) return 'mock_fcm_token_xyz';

    try {
      // VAPID key is used for Web push notifications
      return await fcm.getToken(
        vapidKey: 'BIyTHehjzp1FeIWk5VhL0lNrwkI-5cdgg96X3zoV5SEJjxXDjt6858USs87N0AKBLlQNRTZ9kGLoE8W1iqFcj8o',
      );
    } catch (e) {
      print('Error fetching FCM token: $e');
      return null;
    }
  }

  /// Handles internal routing dispatch when notification is tapped.
  void _handleMessageTap(RemoteMessage message) {
    final String? noticeId = message.data['noticeId'];
    if (noticeId != null && noticeId.isNotEmpty && onNotificationTap != null) {
      onNotificationTap!(noticeId);
    }
  }

  /// Triggers local OS notification prompt when received in foreground.
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    final AndroidNotification? android = message.notification?.android;
    final String? noticeId = message.data['noticeId'];

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: noticeId,
      );
    }
  }
}
