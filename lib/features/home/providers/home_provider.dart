import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/local/prefs_service.dart';
import '../../../data/models/session_record.dart';
import '../../../data/models/user_profile.dart';

class HomeState {
  final UserProfile? profile;
  final List<SessionRecord> todaySessions;
  final Map<String, bool> permissions;
  final bool isLoading;

  const HomeState({
    this.profile,
    this.todaySessions = const [],
    this.permissions = const {},
    this.isLoading = true,
  });

  int get todayFocusedMinutes =>
      todaySessions.fold(0, (s, r) => s + r.durationMinutes);
  int get todayBlockedCount =>
      todaySessions.fold(0, (s, r) => s + r.blockedCount);
  bool get hasAllPermissions =>
      permissions['accessibility'] == true && permissions['overlay'] == true;

  HomeState copyWith({
    UserProfile? profile,
    List<SessionRecord>? todaySessions,
    Map<String, bool>? permissions,
    bool? isLoading,
  }) =>
      HomeState(
        profile: profile ?? this.profile,
        todaySessions: todaySessions ?? this.todaySessions,
        permissions: permissions ?? this.permissions,
        isLoading: isLoading ?? this.isLoading,
      );
}

class HomeNotifier extends StateNotifier<HomeState> {
  final Ref _ref;
  static const _ch = MethodChannel(AppConstants.methodChannel);

  HomeNotifier(this._ref) : super(const HomeState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final prefs = _ref.read(prefsServiceProvider);
    final profile = prefs.userProfile;

    List<SessionRecord> todaySessions = [];
    Map<String, bool> permissions = {};

    try {
      final raw = await _ch.invokeMethod(AppConstants.methodGetHistory);
      if (raw is List) {
        final now = DateTime.now();
        todaySessions = raw
            .cast<Map>()
            .map((m) => SessionRecord.fromMap(Map<String, dynamic>.from(m)))
            .where((s) =>
                s.startTime.year == now.year &&
                s.startTime.month == now.month &&
                s.startTime.day == now.day)
            .toList();
      }
      final perms =
          await _ch.invokeMethod(AppConstants.methodCheckPermissions);
      if (perms is Map) {
        permissions = Map<String, bool>.from(
          perms.map((k, v) => MapEntry(k.toString(), v == true)),
        );
      }
    } catch (_) {}

    state = state.copyWith(
      profile: profile,
      todaySessions: todaySessions,
      permissions: permissions,
      isLoading: false,
    );
  }

  Future<void> openAccessibilitySettings() async {
    try {
      await _ch.invokeMethod(AppConstants.methodOpenAccessibility);
    } catch (_) {}
  }

  Future<void> openOverlaySettings() async {
    try {
      await _ch.invokeMethod(AppConstants.methodOpenOverlay);
    } catch (_) {}
  }
}

final homeProvider =
    StateNotifierProvider<HomeNotifier, HomeState>(
  (ref) => HomeNotifier(ref),
);
