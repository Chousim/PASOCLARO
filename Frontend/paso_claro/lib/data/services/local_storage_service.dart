import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/pasoclaro_models.dart';

/// Persists profile, language, voice preference, and offline checklist ticks
/// locally on the Android device (100% offline-capable).
class LocalStorageService {
  static const _keyProfile = 'pasoclaro_profile';
  static const _keyLanguage = 'pasoclaro_language';
  static const _keySlowVoice = 'pasoclaro_slow_voice';
  static const _keyOnboardingDone = 'pasoclaro_onboarding_done';
  static const _keyChecklistPrefix = 'pasoclaro_check_';

  Future<UserProfileType?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyProfile);
    if (stored == null) return null;
    return UserProfileType.fromId(stored);
  }

  Future<void> saveProfile(UserProfileType profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfile, profile.id);
  }

  Future<AppLanguage> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return AppLanguage.fromCode(prefs.getString(_keyLanguage));
  }

  Future<void> saveLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, language.code);
  }

  Future<bool> loadSlowVoice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySlowVoice) ?? true;
  }

  Future<void> saveSlowVoice(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySlowVoice, enabled);
  }

  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  Future<void> setOnboardingDone(bool done) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, done);
  }

  Future<Set<String>> loadCompletedItemIds(String guideId) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('$_keyChecklistPrefix$guideId');
    if (stored == null) return {};
    return stored.toSet();
  }

  Future<void> saveCompletedItemIds(String guideId, Set<String> itemIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      '$_keyChecklistPrefix$guideId',
      itemIds.toList(),
    );
  }
}
