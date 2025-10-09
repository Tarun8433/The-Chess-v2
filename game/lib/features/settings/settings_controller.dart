import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  static const String _keySoundEnabled = 'sound_enabled';

  final RxBool soundEnabled = true.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getBool(_keySoundEnabled);
      if (v != null) {
        soundEnabled.value = v;
      }
    } catch (_) {
      // Ignore load errors; default stays true
    }
  }

  Future<void> setSoundEnabled(bool enabled) async {
    soundEnabled.value = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySoundEnabled, enabled);
    } catch (_) {
      // Ignore persistence errors
    }
  }
}