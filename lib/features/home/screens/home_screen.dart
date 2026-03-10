import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../session/providers/session_provider.dart';
import '../../home/providers/home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeProvider.notifier).load();
      // Sync default session duration from user profile
      final prefs = ref.read(homeProvider).profile;
      if (prefs != null) {
        ref
            .read(sessionProvider.notifier)
            .setDuration(prefs.defaultSessionMins);
      }
    });
  }

  Future<void> _toggleStudyMode() async {
    final session = ref.read(sessionProvider);
    if (session.status == SessionStatus.active) {
      await ref.read(sessionProvider.notifier).stopSession();
    } else {
      final home = ref.read(homeProvider);
      if (!home.hasAllPermissions) {
        _showPermissionsSheet();
        return;
      }
      await ref.read(sessionProvider.notifier).startSession();
      if (mounted) context.push('/active');
    }
  }

  void _showPermissionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PermissionsSheet(
        onAccessibility: () {
          ref.read(homeProvider.notifier).openAccessibilitySettings();
          Navigator.pop(context);
        },
        onOverlay: () {
          ref.read(homeProvider.notifier).openOverlaySettings();
          Navigator.pop(context);
        },
        permissions: ref.read(homeProvider).permissions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(homeProvider);
    final session = ref.watch(sessionProvider);
    final name = home.profile?.name ?? '';
    final selectedDuration = session.durationMinutes;
    final isActive = session.status == SessionStatus.active;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? 'Hey, $name.' : 'Hey.',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isActive ? 'Focus mode is on.' : 'Ready to focus?',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push('/settings'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.tune_rounded,
                          color: AppColors.textSecondary, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 64),

              // Main CTA
              GestureDetector(
                onTap: _toggleStudyMode,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.accent : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? AppColors.accent
                          : AppColors.divider,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isActive
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        size: 40,
                        color: isActive
                            ? AppColors.background
                            : AppColors.accent,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isActive ? 'Stop Study Mode' : 'Start Study Mode',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(
                              color: isActive
                                  ? AppColors.background
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Duration selector
              if (!isActive) ...[
                Text(
                  'Session length',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                _DurationChips(
                  selected: selectedDuration,
                  onSelect: (v) =>
                      ref.read(sessionProvider.notifier).setDuration(v),
                ),
              ],

              const Spacer(),

              // Today's stats
              _StatsRow(
                focusedMinutes: home.todayFocusedMinutes,
                blockedCount: home.todayBlockedCount,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationChips extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _DurationChips({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...AppConstants.sessionDurations.map((d) {
          final isSelected = selected == d;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.accent : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.divider,
                  ),
                ),
                child: Text(
                  '${d}m',
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: isSelected
                            ? AppColors.background
                            : AppColors.textPrimary,
                      ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int focusedMinutes;
  final int blockedCount;
  const _StatsRow(
      {required this.focusedMinutes, required this.blockedCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Time focused',
            value: focusedMinutes >= 60
                ? '${focusedMinutes ~/ 60}h ${focusedMinutes % 60}m'
                : '${focusedMinutes}m',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Blocked today',
            value: blockedCount.toString(),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(value,
              style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  )),
        ],
      ),
    );
  }
}

class _PermissionsSheet extends StatelessWidget {
  final VoidCallback onAccessibility;
  final VoidCallback onOverlay;
  final Map<String, bool> permissions;
  const _PermissionsSheet({
    required this.onAccessibility,
    required this.onOverlay,
    required this.permissions,
  });

  @override
  Widget build(BuildContext context) {
    final hasAccessibility = permissions['accessibility'] == true;
    final hasOverlay = permissions['overlay'] == true;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Permissions needed',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Proto needs these to monitor and block distractions.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          if (!hasAccessibility)
            _PermRow(
              icon: Icons.accessibility_new_rounded,
              title: 'Accessibility Service',
              subtitle: 'Monitors YouTube in the background',
              onTap: onAccessibility,
            ),
          if (!hasAccessibility && !hasOverlay)
            const SizedBox(height: 12),
          if (!hasOverlay)
            _PermRow(
              icon: Icons.layers_rounded,
              title: 'Display over apps',
              subtitle: 'Shows the block overlay on YouTube',
              onTap: onOverlay,
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _PermRow(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(icon, color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
