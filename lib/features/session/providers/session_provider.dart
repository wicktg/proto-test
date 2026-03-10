import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/keywords.dart';
import '../../../data/local/prefs_service.dart';

enum SessionStatus { idle, active, stopping }

class SessionState {
  final SessionStatus status;
  final int durationMinutes;
  final int remainingSeconds;
  final int blockedCount;
  final DateTime? startTime;

  const SessionState({
    this.status = SessionStatus.idle,
    this.durationMinutes = 25,
    this.remainingSeconds = 0,
    this.blockedCount = 0,
    this.startTime,
  });

  double get progress {
    final total = durationMinutes * 60;
    if (total == 0) return 0;
    return (total - remainingSeconds) / total;
  }

  SessionState copyWith({
    SessionStatus? status,
    int? durationMinutes,
    int? remainingSeconds,
    int? blockedCount,
    DateTime? startTime,
  }) =>
      SessionState(
        status: status ?? this.status,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        blockedCount: blockedCount ?? this.blockedCount,
        startTime: startTime ?? this.startTime,
      );
}

class SessionNotifier extends StateNotifier<SessionState> {
  final Ref _ref;
  Timer? _timer;
  StreamSubscription? _eventSub;

  static const _method = MethodChannel(AppConstants.methodChannel);
  static const _event = EventChannel(AppConstants.eventChannel);

  SessionNotifier(this._ref) : super(const SessionState());

  void setDuration(int minutes) =>
      state = state.copyWith(durationMinutes: minutes);

  Future<void> startSession() async {
    final prefs = _ref.read(prefsServiceProvider);
    try {
      await _method.invokeMethod(AppConstants.methodStartSession, {
        'durationMinutes': state.durationMinutes,
        'allowlist': prefs.allowlist,
        'keywords': EduKeywords.terms,
      });
    } catch (_) {}

    state = state.copyWith(
      status: SessionStatus.active,
      remainingSeconds: state.durationMinutes * 60,
      blockedCount: 0,
      startTime: DateTime.now(),
    );

    _startTimer();
    _listenEvents();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds <= 1) {
        _timer?.cancel();
        _endSession();
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  void _listenEvents() {
    _eventSub?.cancel();
    _eventSub = _event.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        final count = event['count'];
        if (count is int) state = state.copyWith(blockedCount: count);
      }
    });
  }

  Future<void> stopSession() async {
    _timer?.cancel();
    await _endSession();
  }

  Future<void> _endSession() async {
    _eventSub?.cancel();
    try {
      await _method.invokeMethod(AppConstants.methodStopSession);
      await _method.invokeMethod(AppConstants.methodSaveSession, {
        'startTime': state.startTime?.millisecondsSinceEpoch ?? 0,
        'endTime': DateTime.now().millisecondsSinceEpoch,
        'durationMinutes': state.durationMinutes,
        'blockedCount': state.blockedCount,
      });
    } catch (_) {}
    state = state.copyWith(status: SessionStatus.stopping);
  }

  void resetToIdle() {
    state = state.copyWith(
      status: SessionStatus.idle,
      remainingSeconds: 0,
      blockedCount: 0,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _eventSub?.cancel();
    super.dispose();
  }
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, SessionState>(
  (ref) => SessionNotifier(ref),
);
