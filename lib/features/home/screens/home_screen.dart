import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../session/providers/session_provider.dart';
import '../../home/providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);
    final session = ref.watch(sessionProvider);

    final name = home.profile?.name ?? '';
    final isActive = session.status == SessionStatus.active;
    final hasAccessibility = home.permissions['accessibility'] == true;
    final hasOverlay = home.permissions['overlay'] == true;
    final permissionsGranted = hasAccessibility && hasOverlay;
    final selectedDuration = session.durationMinutes;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // Top row: greeting + settings gear
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      name.isNotEmpty ? 'Hey, $name.' : 'Hey.',
                      style: Theme.of(context).textTheme.displayMedium,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Fix 2C: IconButton exposes semantics automatically
                  IconButton(
                    onPressed: () => context.go('/settings'),
                    tooltip: 'Settings',
                    icon: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.settings_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Scrollable middle content — prevents overflow when
              // permission cards, CTA, and chips all stack together
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Permission warning cards
                      if (!hasAccessibility) ...[
                        _PermissionWarningCard(
                          title: 'Enable Accessibility',
                          description:
                              'Proto needs Accessibility permission to monitor YouTube and block distractions.',
                          onTap: () => ref
                              .read(homeProvider.notifier)
                              .openAccessibilitySettings(),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (!hasOverlay) ...[
                        _PermissionWarningCard(
                          title: 'Enable Overlay',
                          description:
                              'Proto needs Display Over Apps permission to show the block screen on YouTube.',
                          onTap: () => ref
                              .read(homeProvider.notifier)
                              .openOverlaySettings(),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (!hasAccessibility || !hasOverlay)
                        const SizedBox(height: 12),

                      // Main CTA button
                      if (isActive)
                        SizedBox(
                          width: double.infinity,
                          height: 72,
                          child: ElevatedButton(
                            onPressed: () => context.go('/active'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Resume Session',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium!
                                  .copyWith(
                                    color: AppColors.background,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 72,
                          child: ElevatedButton(
                            onPressed: permissionsGranted
                                ? () async {
                                    // Fix 1B+1C: startSession() returns false when
                                    // the Kotlin accessibility service isn't connected.
                                    // Do NOT navigate to Active Mode in that case.
                                    final started = await ref
                                        .read(sessionProvider.notifier)
                                        .startSession();
                                    if (!context.mounted) return;
                                    if (started) {
                                      context.go('/active');
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Accessibility Service isn\'t active. Re-enable it in Settings → Accessibility → Proto.',
                                          ),
                                          backgroundColor: AppColors.surface,
                                          duration: Duration(seconds: 4),
                                        ),
                                      );
                                      // Reload permission state so the warning
                                      // card re-appears if the service dropped.
                                      ref.read(homeProvider.notifier).load();
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.background,
                              disabledBackgroundColor: AppColors.surface,
                              side: const BorderSide(
                                  color: AppColors.accent, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Start Study Mode',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium!
                                  .copyWith(
                                    color: permissionsGranted
                                        ? AppColors.accent
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Duration chips (only when idle)
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
                          selectedDuration: selectedDuration,
                          onSelect: (mins) =>
                              ref.read(sessionProvider.notifier).setDuration(mins),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Stats row — always pinned at bottom, outside scroll view
              _StatsRow(
                focusedMinutes: home.todayFocusedMinutes,
                blockedCount: home.todayBlockedCount,
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionWarningCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onTap;

  const _PermissionWarningCard({
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: AppColors.accent,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 10),
                // Fix 2A: TextButton provides built-in semantics (role=button,
                // label). GestureDetector exposes nothing to TalkBack.
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Open Settings →',
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: AppColors.accent,
                          fontSize: 13,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationChips extends StatelessWidget {
  final int selectedDuration;
  final ValueChanged<int> onSelect;

  const _DurationChips({
    required this.selectedDuration,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.sessionDurations.map((duration) {
        final isSelected = selectedDuration == duration;
        // Fix 2A: Semantics wraps GestureDetector so TalkBack announces
        // the chip label and its selected state.
        return Semantics(
          label: '$duration minutes',
          button: true,
          selected: isSelected,
          child: GestureDetector(
            onTap: () => onSelect(duration),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSelected ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
              child: ExcludeSemantics(
                child: Text(
                  '$duration min',
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: isSelected
                            ? AppColors.background
                            : AppColors.textPrimary,
                      ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int focusedMinutes;
  final int blockedCount;

  const _StatsRow({
    required this.focusedMinutes,
    required this.blockedCount,
  });

  String _formatMinutes(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Focused today',
            value: _formatMinutes(focusedMinutes),
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
    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 8),
            ExcludeSemantics(
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
