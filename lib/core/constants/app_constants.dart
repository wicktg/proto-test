class AppConstants {
  static const List<int> sessionDurations = [25, 45, 60, 90];
  static const methodChannel = 'proto/session';
  static const eventChannel = 'proto/events';
  static const methodStartSession = 'startSession';
  static const methodStopSession = 'stopSession';
  static const methodSaveSession = 'saveSession';
  static const methodGetHistory = 'getSessionHistory';
  static const methodCheckPermissions = 'checkPermissions';
  static const methodOpenAccessibility = 'openAccessibilitySettings';
  static const methodOpenOverlay = 'openOverlaySettings';
  static const methodOpenNotification = 'openNotificationSettings';
  static const prefOnboardingDone = 'onboarding_done';
  static const prefUserName = 'user_name';
  static const prefGradeLevel = 'grade_level';
  static const prefMainDistraction = 'main_distraction';
  static const prefStudyGoalHours = 'study_goal_hours';
  static const prefDefaultSessionMins = 'default_session_mins';
  static const prefAllowlist = 'channel_allowlist';
  static const List<String> shortsBlockLines = [
    "Shorts are short. Your future is long.",
    "That dopamine hit isn't worth it.",
    "60 seconds of Shorts = 10 minutes of lost focus.",
    "Your future self is watching. Make them proud.",
    "Not now. You've got things to build.",
    "The algorithm wants your attention. Don't give it.",
    "Back to the feed. Back to the grind.",
    "You came to learn. Shorts can wait.",
  ];
}
