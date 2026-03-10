import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class SessionSummaryScreen extends ConsumerStatefulWidget {
  final int durationMinutes;
  final int blockedCount;

  const SessionSummaryScreen({
    super.key,
    required this.durationMinutes,
    required this.blockedCount,
  });

  @override
  ConsumerState<SessionSummaryScreen> createState() =>
      _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends ConsumerState<SessionSummaryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slideUp;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideUp = Tween<double>(begin: 30, end: 0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _encouragement {
    if (widget.durationMinutes >= 60) return "That's a real session. Respect.";
    if (widget.durationMinutes >= 45) return "Solid work. Keep stacking days.";
    if (widget.durationMinutes >= 25) return "Pomodoro complete. One down.";
    return "Every minute counts. Good start.";
  }

  @override
  Widget build(BuildContext context) {
    final hours = widget.durationMinutes ~/ 60;
    final mins = widget.durationMinutes % 60;
    final timeStr = hours > 0
        ? '${hours}h ${mins}m'
        : '${widget.durationMinutes}m';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(0, _slideUp.value),
            child: child,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                Text(
                  'Session\ncomplete.',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _encouragement,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 56),

                // Stats cards
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.timer_outlined,
                        label: 'Focused for',
                        value: timeStr,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.block_rounded,
                        label: 'Blocked',
                        value: widget.blockedCount.toString(),
                        valueColor: widget.blockedCount > 0
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Done button
                GestureDetector(
                  onTap: () => context.go('/home'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
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
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

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
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(height: 16),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.displayMedium!.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                  fontSize: 40,
                ),
          ),
        ],
      ),
    );
  }
}
