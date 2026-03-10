class UserProfile {
  final String name;
  final String gradeLevel;
  final String mainDistraction;
  final int studyGoalHours;
  final int defaultSessionMins;

  const UserProfile({
    required this.name,
    required this.gradeLevel,
    required this.mainDistraction,
    required this.studyGoalHours,
    required this.defaultSessionMins,
  });

  UserProfile copyWith({
    String? name,
    String? gradeLevel,
    String? mainDistraction,
    int? studyGoalHours,
    int? defaultSessionMins,
  }) =>
      UserProfile(
        name: name ?? this.name,
        gradeLevel: gradeLevel ?? this.gradeLevel,
        mainDistraction: mainDistraction ?? this.mainDistraction,
        studyGoalHours: studyGoalHours ?? this.studyGoalHours,
        defaultSessionMins: defaultSessionMins ?? this.defaultSessionMins,
      );
}
