import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:simple_chess_board_usage/theme/my_colors.dart';
import '../auth/models/user_model.dart';
import '../auth/views/auth_hub.dart';
import '../../main.dart';

/// Splash screen with login check and navigation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkLoginAndNavigate();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
  }

  Future<void> _checkLoginAndNavigate() async {
    // Wait for splash animation and minimum display time
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      // Check if user is logged in
      final isLoggedIn = await UserPrefsService.isLoggedIn();
      final user = await UserPrefsService.loadUser();

      log('Splash Screen - User logged in: $isLoggedIn');
      if (user != null) {
        log('Splash Screen - User loaded: ${user.userName} (${user.name})');
      }

      if (!mounted) return;

      if (isLoggedIn && user != null) {
        // User is logged in, navigate to home screen
        log('Splash Screen - Navigating to Home Screen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MyHomePage(user: user),
          ),
        );
      } else {
        // User is not logged in, navigate to auth hub
        log('Splash Screen - Navigating to Auth Hub');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const AuthHub(),
          ),
        );
      }
    } catch (e) {
      log('Splash Screen - Error checking login: $e');
      // On error, navigate to auth hub
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const AuthHub(),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MyColors.background,
              MyColors.tealGray,
              MyColors.background,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Chess icon with gradient
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          MyColors.accent,
                          MyColors.accent.withOpacity(0.6),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: MyColors.accent.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.castle,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // App title
                  Text(
                    'Chess Master',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: MyColors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                  ),
                  const SizedBox(height: 16),
                  // Subtitle
                  Text(
                    'Think. Plan. Conquer.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: MyColors.white.withOpacity(0.7),
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 60),
                  // Loading indicator
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        MyColors.accent.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
