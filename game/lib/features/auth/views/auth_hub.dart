import 'package:flutter/material.dart';
import 'package:simple_chess_board_usage/theme/my_colors.dart';
import '../widgets/custom_button.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Modern authentication hub with gradient background
class AuthHub extends StatelessWidget {
  const AuthHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MyColors.background,
              MyColors.background.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Hero section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: MyColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.games_outlined,
                          size: 64,
                          color: MyColors.accent,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Join the Arena',
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: MyColors.white,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Connect with players worldwide, improve your skills, and climb the ranks in exciting chess matches.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: MyColors.white.withOpacity(0.7),
                              height: 1.6,
                            ),
                      ),
                      const SizedBox(height: 20),
                      // Features list
                      _buildFeatureItem(
                        icon: Icons.people_outline,
                        title: 'Play Online',
                        subtitle: 'Challenge players from around the world',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(
                        icon: Icons.leaderboard_outlined,
                        title: 'Track Progress',
                        subtitle: 'Monitor your stats and rankings',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(
                        icon: Icons.emoji_events_outlined,
                        title: 'Win Rewards',
                        subtitle: 'Earn achievements and climb the leaderboard',
                      ),
                    ],
                  ),
                ),
                // Action buttons
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Sign In',
                  icon: Icons.login,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Create Account',
                  icon: Icons.person_add,
                  isOutlined: true,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Continue as Guest',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: MyColors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: MyColors.accent, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: MyColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: MyColors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
