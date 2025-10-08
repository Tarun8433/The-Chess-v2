import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_mobile_field/intl_mobile_field.dart';
import 'package:simple_chess_board_usage/theme/my_colors.dart';
import '../controllers/register_controller.dart';
import '../widgets/auth_header.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../../../main.dart';
import '../models/user_model.dart';

/// Modern registration screen with GetX state management
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RegisterController());
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const AuthHeader(
                  title: 'Create Account',
                  subtitle: 'Join the chess community and start playing',
                ),
                const SizedBox(height: 40),
                CustomTextField(
                  label: 'Username',
                  hint: 'Choose a unique username',
                  prefixIcon: Icons.person_outline,
                  onChanged: (value) => controller.username.value = value,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Obx(() {
                  if (controller.checkingUsername.value) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Checking username availability...',
                            style: TextStyle(color: Colors.blue, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  } else if (controller.username.value.isNotEmpty) {
                    final available = controller.usernameAvailable.value;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: available
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: available
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            available
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            color: available ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            available
                                ? 'Username is available!'
                                : 'Username is taken',
                            style: TextStyle(
                              color: available ? Colors.green : Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                const SizedBox(height: 24),
                CustomTextField(
                  label: 'Email',
                  hint: 'Enter your email address',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) => controller.email.value = value,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!GetUtils.isEmail(value.trim())) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mobile Number',
                      style: TextStyle(
                        color: MyColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    IntlMobileField(
                      initialCountryCode: 'IN',
                      languageCode: 'en',
                      style: const TextStyle(color: MyColors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter phone number',
                        hintStyle:
                            TextStyle(color: MyColors.white.withOpacity(0.5)),
                        filled: true,
                        fillColor: MyColors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: MyColors.white.withOpacity(0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: MyColors.white.withOpacity(0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: MyColors.accent, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                      disableLengthCounter: true,
                      onCountryChanged: (country) {
                        controller.countryName.value = country.name ?? '';
                        controller.dialCode.value = country.dialCode ?? '';
                      },
                      onChanged: (mobile) {
                        controller.phoneNumber.value = mobile.number;
                        controller.dialCode.value =
                            mobile.countryCode ?? controller.dialCode.value;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Obx(() => CustomTextField(
                      label: 'Password',
                      hint: 'Create a strong password',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: controller.obscurePassword.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      onSuffixIconTap: controller.togglePasswordVisibility,
                      obscureText: controller.obscurePassword.value,
                      onChanged: (value) => controller.password.value = value,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a password';
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
                      text: 'Create Account',
                      icon: Icons.person_add,
                      isLoading: controller.isLoading.value,
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final success = await controller.register();
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
                        }
                      },
                    )),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
