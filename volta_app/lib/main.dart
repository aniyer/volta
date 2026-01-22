import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketbase/pocketbase.dart';
import 'theme/cyber_vibrant_theme.dart';
import 'services/pocketbase_service.dart';
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/mission_submit_screen.dart';
import 'screens/review_queue_screen.dart';
import 'screens/bazaar_screen.dart';
import 'screens/profile_screen.dart';

import 'screens/leaderboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final authData = prefs.getString('pb_auth');
  debugPrint('MAIN: Auth data loading. Length: ${authData?.length ?? 0}');
  debugPrint('MAIN: Auth data preview: ${authData?.substring(0, min(50, authData.length))}...');
  
  final store = AsyncAuthStore(
    save: (String data) async {
      debugPrint('MAIN: Saving auth data. Length: ${data.length}');
      await prefs.setString('pb_auth', data);
    },
    initial: authData,
  );
  
  runApp(VoltaApp(authStore: store));
}

class VoltaApp extends StatelessWidget {
  final AuthStore authStore;
  
  const VoltaApp({super.key, required this.authStore});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // PocketBase singleton
        Provider<PocketBaseService>(
          create: (_) => PocketBaseService(authStore),
        ),
        // Auth service with change notifier
        ChangeNotifierProvider<AuthService>(
          create: (context) => AuthService(
            context.read<PocketBaseService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'VOLTA',
        debugShowCheckedModeBanner: false,
        theme: CyberVibrantTheme.theme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/leaderboard': (context) => const LeaderboardScreen(),
          '/submit': (context) => const MissionSubmitScreen(),
          '/review': (context) => const ReviewQueueScreen(),
          '/bazaar': (context) => const BazaarScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}
