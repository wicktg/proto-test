import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/prefs_service.dart';

class SettingsNotifier extends StateNotifier<List<String>> {
  final Ref _ref;
  SettingsNotifier(this._ref) : super([]) {
    _load();
  }

  void _load() {
    state = _ref.read(prefsServiceProvider).allowlist;
  }

  Future<void> addChannel(String ch) async {
    final t = ch.trim();
    if (t.isEmpty || state.contains(t)) return;
    state = [...state, t];
    await _ref.read(prefsServiceProvider).saveAllowlist(state);
  }

  Future<void> removeChannel(String ch) async {
    state = state.where((c) => c != ch).toList();
    await _ref.read(prefsServiceProvider).saveAllowlist(state);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, List<String>>(
  (ref) => SettingsNotifier(ref),
);
