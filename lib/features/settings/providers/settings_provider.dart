import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/prefs_service.dart';

class SettingsNotifier extends StateNotifier<List<String>> {
  final Ref _ref;

  SettingsNotifier(this._ref) : super([]) {
    state = _ref.read(prefsServiceProvider).allowlist;
  }

  Future<void> addChannel(String channel) async {
    final trimmed = channel.trim();
    if (trimmed.isEmpty || state.contains(trimmed)) return;
    final updated = [...state, trimmed];
    state = updated;
    await _ref.read(prefsServiceProvider).saveAllowlist(updated);
  }

  Future<void> removeChannel(String channel) async {
    final updated = state.where((c) => c != channel).toList();
    state = updated;
    await _ref.read(prefsServiceProvider).saveAllowlist(updated);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, List<String>>(
  (ref) => SettingsNotifier(ref),
);
