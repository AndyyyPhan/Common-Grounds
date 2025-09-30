import 'package:shared_preferences/shared_preferences.dart';

class LocalPrefs {
  static const _kOnboarded = 'onboarded';
  static Future<bool> hasOnboarded() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kOnboarded) ?? false;
  }

  static Future<void> setOnboarded(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kOnboarded, v);
  }
}
