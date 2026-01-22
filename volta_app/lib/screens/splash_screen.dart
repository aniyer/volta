import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../theme/cyber_vibrant_theme.dart';

/// Animated splash screen with VOLTA branding
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Get household name from environment or use default
  static const String householdName = String.fromEnvironment(
    'HOUSEHOLD_NAME',
    defaultValue: 'Your Family',
  );

  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    // Wait for animation
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted) return;
    
    // Check if user is already logged in
    final auth = context.read<AuthService>();
    if (auth.isLoggedIn) {
      if (auth.user != null) {
        // Refresh user data to ensure valid session/updates
        auth.refreshUser(); 
      }
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CyberVibrantTheme.darkBase,
              Color(0xFF1E1B4B), // Deep purple tint
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated V logo
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: CyberVibrantTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: CyberVibrantTheme.withAlpha(CyberVibrantTheme.neonViolet, 0.8),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'V',
                    style: TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 300.ms),
              
              const SizedBox(height: 40),
              
              // VOLTA title
              Text(
                'VOLTA',
                style: CyberVibrantTheme.neonText(
                  fontSize: 48,
                  color: CyberVibrantTheme.neonViolet,
                ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 500.ms)
                  .slideY(begin: 0.3, curve: Curves.easeOut),
              
              const SizedBox(height: 16),
              
              // Tagline
              Text(
                'Spin the chore. Own the turn.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: CyberVibrantTheme.textSecondary,
                  letterSpacing: 1.5,
                ),
              )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 500.ms),
              
              const SizedBox(height: 60),
              
              // Household name
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: CyberVibrantTheme.withAlpha(CyberVibrantTheme.darkCard, 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: CyberVibrantTheme.withAlpha(CyberVibrantTheme.electricTeal, 0.3),
                  ),
                ),
                child: Text(
                  householdName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: CyberVibrantTheme.electricTeal,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 900.ms, duration: 500.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
              
              const SizedBox(height: 80),
              
              // Loading indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    CyberVibrantTheme.withAlpha(CyberVibrantTheme.neonViolet, 0.6),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 1200.ms, duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}
