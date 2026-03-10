import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/providers/home_provider.dart';
import '../../session/providers/session_provider.dart';

class SessionSummaryScreen extends ConsumerWidget {
  final int durationMinutes;
  final int blockedCount;

  const SessionSummaryScreen({
    super.key,
    required this.durationMinutes,
    required this.blockedCount,
  });

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0) return '${hours}h ${mins}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  String _encouragement() {
    if (blockedCount == 0) return 'Clean session.';
    if (blockedCount <= 5) return 'Nice focus.';
    return 'Beast mode.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeLabel = _formatDuration(durationMinutes);
    final encouragement = _encouragement();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),

              // Headline
              Text(
                'Session\nComplete',
                style: Theme.of(context).textTheme.displayMedium,
              ),

              const SizedBox(height: 12),

              // Encouragement line
              Text(
                encouragement,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: AppColors.accent,
                    ),
              ),

              const SizedBox(height: 48),

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _BigStatCard(
                      label: 'Time studied',
                      value: timeLabel,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _BigStatCard(
                      label: 'Blocked',
                      value: blockedCount.toString(),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Done button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(homeProvider.notifier).load();
                    ref.read(sessionProvider.notifier).resetToIdle();
                    context.go('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Done',
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: AppColors.background,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigStatCard extends StatelessWidget {
  final String label;
  final String value;

  const _BigStatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.displayMedium!.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 40,
                ),
          ),
        ],
      ),
    );
  }
}
