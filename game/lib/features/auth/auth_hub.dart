import 'package:flutter/material.dart';
import 'package:simple_chess_board_usage/theme/my_colors.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthHub extends StatelessWidget {
  const AuthHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Join the Arena',
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(color: MyColors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              'Login or create a new account to play online.',
              style: TextStyle(color: MyColors.white),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: const Text('Login'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: const Text('Register'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}