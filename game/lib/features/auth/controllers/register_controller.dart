import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

/// Controller for registration screen
class RegisterController extends GetxController {
  // Observable state
  final isLoading = false.obs;
  final checkingUsername = false.obs;
  final usernameAvailable = false.obs;
  final obscurePassword = true.obs;
  final errorMessage = ''.obs;

  // Form state
  final username = ''.obs;
  final email = ''.obs;
  final password = ''.obs;
  final phoneNumber = ''.obs;
  final dialCode = ''.obs;
  final countryName = ''.obs;

  Worker? _debounceWorker;

  @override
  void onInit() {
    super.onInit();
    // Auto-check username availability with debounce
    _debounceWorker = debounce<String>(
      username,
      (_) => checkUsernameAvailability(),
      time: const Duration(milliseconds: 600),
    );
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  /// Check username availability
  Future<void> checkUsernameAvailability() async {
    final current = username.value.trim();
    if (current.isEmpty) {
      checkingUsername.value = false;
      usernameAvailable.value = false;
      return;
    }

    checkingUsername.value = true;
    try {
      final available = await AuthService.isUsernameAvailable(current);
      usernameAvailable.value = available;
    } catch (e) {
      usernameAvailable.value = false;
    } finally {
      checkingUsername.value = false;
    }
  }

  /// Validate form
  bool validateForm() {
    if (username.value.trim().isEmpty) {
      errorMessage.value = 'Please enter username';
      return false;
    }
    if (!usernameAvailable.value) {
      errorMessage.value = 'Username is not available';
      return false;
    }
    if (email.value.trim().isEmpty) {
      errorMessage.value = 'Please enter email';
      return false;
    }
    if (!GetUtils.isEmail(email.value.trim())) {
      errorMessage.value = 'Please enter valid email';
      return false;
    }
    if (phoneNumber.value.trim().isEmpty) {
      errorMessage.value = 'Please enter phone number';
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

  /// Register user
  Future<bool> register() async {
    if (!validateForm()) return false;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await AuthService.registerUser(
        userName: username.value.trim(),
        password: password.value.trim(),
        mobileNo: phoneNumber.value.trim(),
        emailAddress: email.value.trim(),
        countryCode: dialCode.value.replaceAll('+', ''),
        countryName: countryName.value.trim(),
      );

      if (response.success && response.data != null) {
        await UserPrefsService.saveUser(response.data!);
        Get.snackbar(
          'Success',
          response.message,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        return true;
      } else {
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
    email.value = '';
    password.value = '';
    phoneNumber.value = '';
    dialCode.value = '';
    countryName.value = '';
    errorMessage.value = '';
    usernameAvailable.value = false;
    obscurePassword.value = true;
  }

  @override
  void onClose() {
    _debounceWorker?.dispose();
    clearForm();
    super.onClose();
  }
}
