import 'dart:developer';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

/// Controller for login screen
class LoginController extends GetxController {
  // Observable state
  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final errorMessage = ''.obs;

  // Form state
  final username = ''.obs;
  final password = ''.obs;

  /// Toggle password visibility
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  /// Validate form
  bool validateForm() {
    if (username.value.trim().isEmpty) {
      errorMessage.value = 'Please enter username';
      return false;
    }
    if (password.value.trim().isEmpty) {
      errorMessage.value = 'Please enter password';
      return false;
    }
    if (password.value.length < 6) {
      errorMessage.value = 'Password must be at least 6 characters';
      return false;
    }
    errorMessage.value = '';
    return true;
  }

  /// Login user
  Future<bool> login() async {
    if (!validateForm()) return false;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await AuthService.loginUser(
        userName: username.value.trim(),
        password: password.value.trim(),
      );

      log('Login API Response - Success: ${response.success}');
      log('Login API Response - Message: ${response.message}');

      if (response.success && response.data != null) {
        log('Login API Response - User Data: ${response.data!.toJson()}');
        log('Login API Response - User Name: ${response.data!.name}');
        log('Login API Response - User Email: ${response.data!.emailAddress}');
        log('Login API Response - Customer Code: ${response.data!.customerCode}');

        await UserPrefsService.saveUser(response.data!);
        log('User data saved to SharedPreferences under key: user_record_json');

        Get.snackbar(
          'Success',
          response.message,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        return true;
      } else {
        log('Login API Response - Error: ${response.message}');
        errorMessage.value = response.message;
        Get.snackbar(
          'Error',
          response.message,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        return false;
      }
    } catch (e) {
      log('Login API Error - Exception: ${e.toString()}');
      errorMessage.value = 'An unexpected error occurred';
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Clear form
  void clearForm() {
    username.value = '';
    password.value = '';
    errorMessage.value = '';
    obscurePassword.value = true;
  }

  @override
  void onClose() {
    clearForm();
    super.onClose();
  }
}
