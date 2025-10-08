import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import '../widgets/auth_header.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../../../main.dart';
import '../models/user_model.dart';

/// Modern login screen with GetX state management
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const AuthHeader(
                title: 'Welcome Back',
                subtitle: 'Sign in to continue your chess journey',
              ),
              const SizedBox(height: 48),
              CustomTextField(
                label: 'Username',
                hint: 'Enter your username',
                prefixIcon: Icons.person_outline,
                onChanged: (value) => controller.username.value = value,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Obx(() => CustomTextField(
                    label: 'Password',
                    hint: 'Enter your password',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: controller.obscurePassword.value
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    onSuffixIconTap: controller.togglePasswordVisibility,
                    obscureText: controller.obscurePassword.value,
                    onChanged: (value) => controller.password.value = value,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  )),
              const SizedBox(height: 12),
              Obx(() {
                if (controller.errorMessage.value.isNotEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.errorMessage.value,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 32),
              Obx(() => CustomButton(
                    text: 'Sign In',
                    icon: Icons.login,
                    isLoading: controller.isLoading.value,
                    onPressed: () async {
                      final success = await controller.login();
                      if (success && context.mounted) {
                        // Load user data and navigate to home screen
                        final user = await UserPrefsService.loadUser();
                        if (user != null) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => MyHomePage(user: user),
                            ),
                            (route) => false,
                          );
                        }
                      }
                    },
                  )),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () {
                    // Navigate to forgot password
                  },
                  child: const Text(
                    'Forgot Password?',
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
    );
  }
}
