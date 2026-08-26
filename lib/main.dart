import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'core/constants.dart';
import 'providers/auth_provider.dart';
import 'providers/notice_provider.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/notice_detail_screen.dart';
import 'screens/search_screen.dart';
import 'screens/bookmarks_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/about_screen.dart';

// Declare GoRouter configuration globally to access for notification navigation
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const SplashScreen();
      },
    ),
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: '/home',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: '/notice/:id',
      builder: (BuildContext context, GoRouterState state) {
        final String noticeId = state.pathParameters['id'] ?? '';
        return NoticeDetailScreen(noticeId: noticeId);
      },
    ),
    GoRoute(
      path: '/search',
      builder: (BuildContext context, GoRouterState state) {
        return const SearchScreen();
      },
    ),
    GoRoute(
      path: '/bookmarks',
      builder: (BuildContext context, GoRouterState state) {
        return const BookmarksScreen();
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) {
        return const SettingsScreen();
      },
    ),
    GoRoute(
      path: '/about',
      builder: (BuildContext context, GoRouterState state) {
        return const AboutScreen();
      },
    ),
  ],
);

// Top-level background message handler — must be a top-level function.
// Invoked by FCM when the app is terminated or in the background.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized in the background isolate
  await Firebase.initializeApp();
  print('Background FCM message received: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase on native platforms (Web uses REST + JWT directly)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();

      // Register background message handler BEFORE other FCM setup
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Initialize Push Notifications
      final NotificationService notificationService = NotificationService();
      await notificationService.init();
      
      // Bind click routing callback
      notificationService.onNotificationTap = (String noticeId) {
        if (noticeId.isNotEmpty) {
          _router.push('/notice/$noticeId');
        }
      };
    } catch (error) {
      print('Firebase initialization warning: $error');
    }
  } else {
    print('Firebase initialization skipped on Web platform.');
  }

  runApp(const CampusNotifyApp());
}

class CampusNotifyApp extends StatelessWidget {
  const CampusNotifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NoticeProvider()),
      ],
      child: MaterialApp.router(
        title: 'Sathyabama Placement Notice',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
      ),
    );
  }
}
