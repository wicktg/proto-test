import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/session_provider.dart';

class ActiveModeScreen extends ConsumerStatefulWidget {
  const ActiveModeScreen({super.key});

  @override
  ConsumerState<ActiveModeScreen> createState() => _ActiveModeScreenState();
}

class _ActiveModeScreenState extends ConsumerState<ActiveModeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseOpacity = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _stop() async {
    await ref.read(sessionProvider.notifier).stopSession();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    // Navigate to summary when session is stopping
    ref.listen<SessionState>(sessionProvider, (prev, next) {
      if (next.status == SessionStatus.stopping && mounted) {
        context.go('/summary', extra: {
          'durationMinutes': next.durationMinutes,
          'blockedCount': next.blockedCount,
        });
        ref.read(sessionProvider.notifier).resetToIdle();
      }
    });

    final remaining = session.remainingSeconds;
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Study Mode',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Active',
                  style: Theme.of(context).textTheme.displayMedium!.copyWith(
                        color: AppColors.accent,
                      ),
                ),
              ),

              const Spacer(),

              // Pulse ring
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, child) => Transform.scale(
                  scale: _pulseScale.value,
                  child: Opacity(
                    opacity: _pulseOpacity.value,
                    child: child,
                  ),
                ),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        width: 2),
                    color: AppColors.accent.withValues(alpha: 0.06),
                  ),
                  child: Center(
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Countdown
              Text(
                timeStr,
                style: Theme.of(context).textTheme.displayLarge!.copyWith(
                      fontSize: 72,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -2,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'remaining',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: AppColors.textSecondary),
              ),

              const SizedBox(height: 48),

              // Blocked count
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.4),
                    end: Offset.zero,
                  ).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Text(
                  key: ValueKey(session.blockedCount),
                  '${session.blockedCount} distraction${session.blockedCount == 1 ? '' : 's'} blocked',
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                        color: session.blockedCount > 0
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),

              const Spacer(),

              // Stop button
              GestureDetector(
                onTap: _stop,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'End Session',
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 16,
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
