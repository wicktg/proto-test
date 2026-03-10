import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/edu_channels.dart';
import 'prefs_provider.dart';

class PrefsService {
  final SharedPreferences _prefs;
  PrefsService(this._prefs);

  bool get onboardingDone =>
      _prefs.getBool(AppConstants.prefOnboardingDone) ?? false;

  UserProfile get userProfile => UserProfile(
        name: _prefs.getString(AppConstants.prefUserName) ?? '',
        gradeLevel: _prefs.getString(AppConstants.prefGradeLevel) ?? '',
        mainDistraction:
            _prefs.getString(AppConstants.prefMainDistraction) ?? '',
        studyGoalHours:
            _prefs.getInt(AppConstants.prefStudyGoalHours) ?? 2,
        defaultSessionMins:
            _prefs.getInt(AppConstants.prefDefaultSessionMins) ?? 25,
      );

  List<String> get allowlist =>
      _prefs.getStringList(AppConstants.prefAllowlist) ??
      List.from(EduChannels.defaults);

  Future<void> saveUserProfile(UserProfile profile) async {
    await _prefs.setBool(AppConstants.prefOnboardingDone, true);
    await _prefs.setString(AppConstants.prefUserName, profile.name);
    await _prefs.setString(AppConstants.prefGradeLevel, profile.gradeLevel);
    await _prefs.setString(
        AppConstants.prefMainDistraction, profile.mainDistraction);
    await _prefs.setInt(
        AppConstants.prefStudyGoalHours, profile.studyGoalHours);
    await _prefs.setInt(
        AppConstants.prefDefaultSessionMins, profile.defaultSessionMins);
  }

  Future<void> saveAllowlist(List<String> channels) async {
    await _prefs.setStringList(AppConstants.prefAllowlist, channels);
  }
}

final prefsServiceProvider = Provider<PrefsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PrefsService(prefs);
});
