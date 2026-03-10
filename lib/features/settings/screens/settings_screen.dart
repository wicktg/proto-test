import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _channelController = TextEditingController();

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  void _addChannel() {
    final text = _channelController.text.trim();
    if (text.isEmpty) return;
    ref.read(settingsProvider.notifier).addChannel(text);
    _channelController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final channels = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Allowlist',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'These channels are always shown, even in Study Mode',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),

          const SizedBox(height: 16),

          // Add channel row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _channelController,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: AppColors.textPrimary,
                        ),
                    decoration: InputDecoration(
                      hintText: 'Channel name',
                      hintStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.accent, width: 1.5),
                      ),
                    ),
                    onSubmitted: (_) => _addChannel(),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _addChannel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Add',
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: AppColors.background,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Channel list
          Expanded(
            child: channels.isEmpty
                ? Center(
                    child: Text(
                      'No channels added yet.',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 4),
                    itemCount: channels.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final channel = channels[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                channel,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            IconButton(
                              onPressed: () => ref
                                  .read(settingsProvider.notifier)
                                  .removeChannel(channel),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
