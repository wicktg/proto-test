import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/local/prefs_service.dart';

class OnboardingState {
  final String name;
  final String gradeLevel;
  final String mainDistraction;
  final int studyGoalHours;

  const OnboardingState({
    this.name = '',
    this.gradeLevel = '',
    this.mainDistraction = '',
    this.studyGoalHours = 0,
  });

  OnboardingState copyWith({
    String? name,
    String? gradeLevel,
    String? mainDistraction,
    int? studyGoalHours,
  }) =>
      OnboardingState(
        name: name ?? this.name,
        gradeLevel: gradeLevel ?? this.gradeLevel,
        mainDistraction: mainDistraction ?? this.mainDistraction,
        studyGoalHours: studyGoalHours ?? this.studyGoalHours,
      );

  bool get isComplete =>
      name.isNotEmpty &&
      gradeLevel.isNotEmpty &&
      mainDistraction.isNotEmpty &&
      studyGoalHours > 0;

  int get defaultSessionMins {
    if (studyGoalHours <= 1) return 25;
    if (studyGoalHours <= 2) return 45;
    if (studyGoalHours <= 3) return 60;
    return 90;
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final Ref _ref;
  OnboardingNotifier(this._ref) : super(const OnboardingState());

  void setName(String name) => state = state.copyWith(name: name.trim());
  void setGradeLevel(String grade) => state = state.copyWith(gradeLevel: grade);
  void setMainDistraction(String d) =>
      state = state.copyWith(mainDistraction: d);
  void setStudyGoalHours(int hours) =>
      state = state.copyWith(studyGoalHours: hours);

  Future<void> complete() async {
    final profile = UserProfile(
      name: state.name,
      gradeLevel: state.gradeLevel,
      mainDistraction: state.mainDistraction,
      studyGoalHours: state.studyGoalHours,
      defaultSessionMins: state.defaultSessionMins,
    );
    await _ref.read(prefsServiceProvider).saveUserProfile(profile);
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
  (ref) => OnboardingNotifier(ref),
);
