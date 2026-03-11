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
  late AnimationController _pulseController;
  late Animation<double> _pulseScale1;
  late Animation<double> _pulseScale2;
  late Animation<double> _pulseScale3;
  late Animation<double> _pulseOpacity1;
  late Animation<double> _pulseOpacity2;
  late Animation<double> _pulseOpacity3;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseScale1 = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _pulseOpacity1 = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _pulseScale2 = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOut),
      ),
    );
    _pulseOpacity2 = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOut),
      ),
    );

    _pulseScale3 = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _pulseOpacity3 = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SessionState>(sessionProvider, (previous, next) {
      if (next.status == SessionStatus.stopping && mounted) {
        context.go('/summary', extra: {
          'durationMinutes': next.durationMinutes,
          'blockedCount': next.blockedCount,
        });
        // resetToIdle() is intentionally NOT called here.
        // Calling state mutations inside ref.listen risks double-fires
        // during Riverpod's notification cycle. The summary screen's
        // Done button owns the idle reset.
      }
    });

    final session = ref.watch(sessionProvider);
    final remainingSeconds = session.remainingSeconds;
    final mins = remainingSeconds ~/ 60;
    final secs = remainingSeconds % 60;
    final timeString =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 48),

                // STUDY MODE label
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'STUDY MODE',
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: AppColors.accent,
                          letterSpacing: 3.0,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),

                const Spacer(),

                // Pulsing concentric circles
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer ring
                          Opacity(
                            opacity: _pulseOpacity3.value,
                            child: Transform.scale(
                              scale: _pulseScale3.value,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.accent,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Middle ring
                          Opacity(
                            opacity: _pulseOpacity2.value,
                            child: Transform.scale(
                              scale: _pulseScale2.value,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.accent,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Inner ring
                          Opacity(
                            opacity: _pulseOpacity1.value,
                            child: Transform.scale(
                              scale: _pulseScale1.value,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.accent,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Center dot
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Countdown timer
                Text(
                  timeString,
                  style: Theme.of(context).textTheme.displayLarge!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),

                const SizedBox(height: 16),

                // Distractions blocked
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.3),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Text(
                    key: ValueKey(session.blockedCount),
                    '${session.blockedCount} distractions blocked',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: session.blockedCount > 0
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                  ),
                ),

                const Spacer(),

                // Stop Session button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () =>
                        ref.read(sessionProvider.notifier).stopSession(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppColors.textPrimary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Stop Session',
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: AppColors.textPrimary,
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
      ),
    );
  }
}
