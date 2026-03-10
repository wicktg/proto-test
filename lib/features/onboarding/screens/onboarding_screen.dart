import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  final _nameCtrl = TextEditingController();
  int _page = 0;

  void _next() {
    if (_page < 3) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
      setState(() => _page++);
    }
  }

  Future<void> _finish() async {
    await ref.read(onboardingProvider.notifier).complete();
    if (mounted) context.go('/home');
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _Dots(current: _page),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _NameStep(controller: _nameCtrl, onNext: () {
                    final name = _nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    ref.read(onboardingProvider.notifier).setName(name);
                    _next();
                  }),
                  _ChipStep(
                    question: "What grade are\nyou in?",
                    options: const [
                      'High School',
                      'College',
                      'Grad School',
                      'Other',
                    ],
                    onSelect: (v) {
                      ref.read(onboardingProvider.notifier).setGradeLevel(v);
                      _next();
                    },
                  ),
                  _ChipStep(
                    question: "What kills your\nfocus most?",
                    options: const [
                      'Shorts',
                      'Trending',
                      'Recommendations',
                      'All of it',
                    ],
                    onSelect: (v) {
                      ref
                          .read(onboardingProvider.notifier)
                          .setMainDistraction(v);
                      _next();
                    },
                  ),
                  _ChipStep(
                    question: "Daily study\ngoal?",
                    options: const ['1 hour', '2 hours', '3 hours', '4+ hours'],
                    onSelect: (v) {
                      final hours = int.tryParse(v.split(' ').first) ?? 4;
                      ref
                          .read(onboardingProvider.notifier)
                          .setStudyGoalHours(hours);
                      _finish();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int current;
  const _Dots({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? AppColors.accent : AppColors.textSecondary,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _NameStep extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onNext;
  const _NameStep({required this.controller, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 64),
          Text(
            "What do\nwe call you?",
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 48),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: Theme.of(context)
                .textTheme
                .displayMedium!
                .copyWith(color: AppColors.accent, fontSize: 32),
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: Theme.of(context).textTheme.displayMedium!.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                    fontSize: 32,
                  ),
              border: InputBorder.none,
              enabledBorder: const UnderlineInputBorder(
                borderSide:
                    BorderSide(color: AppColors.divider, width: 1),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide:
                    BorderSide(color: AppColors.accent, width: 2),
              ),
            ),
            onSubmitted: (_) => onNext(),
          ),
          const Spacer(),
          _ContinueButton(onTap: onNext),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ChipStep extends StatefulWidget {
  final String question;
  final List<String> options;
  final ValueChanged<String> onSelect;
  const _ChipStep(
      {required this.question,
      required this.options,
      required this.onSelect});

  @override
  State<_ChipStep> createState() => _ChipStepState();
}

class _ChipStepState extends State<_ChipStep> {
  String? selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 64),
          Text(widget.question,
              style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 48),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: widget.options.map((opt) {
              final isSelected = selected == opt;
              return GestureDetector(
                onTap: () {
                  setState(() => selected = opt);
                  Future.delayed(const Duration(milliseconds: 200), () {
                    widget.onSelect(opt);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    opt,
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: isSelected
                              ? AppColors.background
                              : AppColors.textPrimary,
                        ),
                  ),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ContinueButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          'Continue',
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: AppColors.background,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
