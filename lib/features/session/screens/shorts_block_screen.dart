import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class ShortsBlockScreen extends ConsumerWidget {
  const ShortsBlockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wittyLine = AppConstants
        .shortsBlockLines[Random().nextInt(AppConstants.shortsBlockLines.length)];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Yellow accent bar instead of emoji
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 48),

              // Witty one-liner
              Text(
                wittyLine,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium!.copyWith(
                      height: 1.2,
                    ),
              ),

              const SizedBox(height: 20),

              // Subtext
              Text(
                "You're in Study Mode.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),

              const Spacer(flex: 2),

              // Back to Feed button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
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
    );
  }
}
