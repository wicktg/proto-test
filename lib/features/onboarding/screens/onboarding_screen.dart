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
  final _pageController = PageController();
  final _nameController = TextEditingController();
  int _currentPage = 0;

  void _advanceTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage = page);
  }

  Future<void> _complete() async {
    final notifier = ref.read(onboardingProvider.notifier);
    await notifier.complete();
    if (mounted) context.go('/home');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            _ProgressDots(currentIndex: _currentPage),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Step 1: Name
                  _NameStep(
                    controller: _nameController,
                    onContinue: () {
                      final name = _nameController.text.trim();
                      if (name.isEmpty) return;
                      ref.read(onboardingProvider.notifier).setName(name);
                      _advanceTo(1);
                    },
                  ),
                  // Step 2: Grade level
                  _ChipStep(
                    question: "What grade are\nyou in?",
                    options: const [
                      'High School',
                      'College',
                      'Grad School',
                      'Other',
                    ],
                    onSelect: (value) {
                      ref
                          .read(onboardingProvider.notifier)
                          .setGradeLevel(value);
                      _advanceTo(2);
                    },
                  ),
                  // Step 3: Main distraction
                  _ChipStep(
                    question: "What distracts\nyou most?",
                    options: const [
                      'Shorts',
                      'Trending',
                      'Recommendations',
                      'All of it',
                    ],
                    onSelect: (value) {
                      ref
                          .read(onboardingProvider.notifier)
                          .setMainDistraction(value);
                      _advanceTo(3);
                    },
                  ),
                  // Step 4: Study goal
                  _ChipStep(
                    question: "How many hours do\nyou want to study today?",
                    options: const ['1 hr', '2 hrs', '3 hrs', '4+ hrs'],
                    hourValues: const [1, 2, 3, 4],
                    onSelect: (value) {
                      // value is the label; look up the hour integer
                      final index = ['1 hr', '2 hrs', '3 hrs', '4+ hrs']
                          .indexOf(value);
                      final hours = [1, 2, 3, 4][index < 0 ? 0 : index];
                      ref
                          .read(onboardingProvider.notifier)
                          .setStudyGoalHours(hours);
                      _complete();
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

class _ProgressDots extends StatelessWidget {
  final int currentIndex;
  const _ProgressDots({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final isActive = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent : AppColors.textSecondary,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _NameStep extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onContinue;
  const _NameStep({required this.controller, required this.onContinue});

  @override
  State<_NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<_NameStep> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 72),
          Text(
            "What's your name?",
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 48),
          TextField(
            controller: widget.controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                ),
            decoration: InputDecoration(
              hintText: 'Enter your name',
              hintStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 18,
                  ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.textSecondary, width: 1),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.accent, width: 2),
              ),
              border: const UnderlineInputBorder(),
            ),
            onSubmitted: (_) {
              if (_hasText) widget.onContinue();
            },
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _hasText ? widget.onContinue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                disabledBackgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Continue',
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: _hasText
                          ? AppColors.background
                          : AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ChipStep extends StatefulWidget {
  final String question;
  final List<String> options;
  final List<int>? hourValues;
  final ValueChanged<String> onSelect;

  const _ChipStep({
    required this.question,
    required this.options,
    required this.onSelect,
    this.hourValues,
  });

  @override
  State<_ChipStep> createState() => _ChipStepState();
}

class _ChipStepState extends State<_ChipStep> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 72),
          Text(
            widget.question,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: widget.options.map((option) {
              final isSelected = _selected == option;
              // Fix 2A: Semantics wrapper makes each chip discoverable and
              // activatable by TalkBack. GestureDetector alone exposes nothing.
              return Semantics(
                label: option,
                button: true,
                selected: isSelected,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selected = option);
                    Future.delayed(const Duration(milliseconds: 200), () {
                      widget.onSelect(option);
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                          isSelected ? AppColors.accent : AppColors.textSecondary,
                      width: 1,
                    ),
                  ),
                  child: ExcludeSemantics(
                    child: Text(
                      option,
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
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
