import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class ShortsBlockScreen extends ConsumerStatefulWidget {
  const ShortsBlockScreen({super.key});

  @override
  ConsumerState<ShortsBlockScreen> createState() => _ShortsBlockScreenState();
}

class _ShortsBlockScreenState extends ConsumerState<ShortsBlockScreen>
    with SingleTickerProviderStateMixin {
  late final String _line;
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _line = AppConstants
        .shortsBlockLines[Random().nextInt(AppConstants.shortsBlockLines.length)];
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeIn =
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _backToFeed() {
    // Send global back action via platform
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeIn,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.block_rounded,
                    color: AppColors.accent,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 40),

                // Label
                Text(
                  'Shorts blocked',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),

                // Witty line
                Text(
                  _line,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                        height: 1.3,
                      ),
                ),

                const Spacer(flex: 2),

                // Back button
                GestureDetector(
                  onTap: _backToFeed,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Back to Feed',
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
