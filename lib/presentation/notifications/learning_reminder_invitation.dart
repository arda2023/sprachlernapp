import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../widgets/action_buttons.dart';
import '../providers/notification_provider.dart';

/// Place on a completion surface after a genuine, saved learning success.
class LearningReminderInvitation extends ConsumerStatefulWidget {
  const LearningReminderInvitation({super.key, this.fallback});

  final Widget? fallback;

  @override
  ConsumerState<LearningReminderInvitation> createState() =>
      _LearningReminderInvitationState();
}

class _LearningReminderInvitationState
    extends ConsumerState<LearningReminderInvitation> {
  LearningReminderScope? _scope;
  bool _checking = false;
  bool _claimed = false;
  bool _finished = false;

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationProvider);
    final scope = notifications.scope;
    final current = ModalRoute.isCurrentOf(context) ?? true;
    _scope ??= scope;
    if (_finished || (scope != null && scope != _scope)) {
      return const SizedBox.shrink();
    }
    if (_claimed) {
      return scope != null && scope == _scope
          ? _card(context, scope)
          : const SizedBox.shrink();
    }
    if (_checking) return const SizedBox.shrink();
    if (notifications.canInvite && scope != null && current) {
      _checking = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_claim(scope));
      });
      return const SizedBox.shrink();
    }
    return widget.fallback ?? const SizedBox.shrink();
  }

  Future<void> _claim(LearningReminderScope scope) async {
    final current = ModalRoute.isCurrentOf(context) ?? true;
    final accepted =
        current &&
        await ref
            .read(notificationProvider.notifier)
            .claimLearningInvitation(scope);
    if (!mounted) return;
    setState(() {
      _claimed = accepted;
      _checking = false;
    });
  }

  Widget _card(BuildContext context, LearningReminderScope scope) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.raisedInk,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Ans Üben erinnern?',
                style: AppType.chrome(
                  size: 17,
                  weight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Zur gewählten Uhrzeit kommt ein kurzer Hinweis wie „Zeit für ein paar Wörter“.',
              style: AppType.chrome(size: 15, color: colors.textMuted),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                PrimaryActionButton(
                  label: 'Erinnerungen aktivieren',
                  onPressed: () {
                    setState(() => _finished = true);
                    unawaited(
                      ref
                          .read(notificationProvider.notifier)
                          .enableFromInvitation(scope),
                    );
                  },
                ),
                OutlineActionButton(
                  label: 'Später',
                  onPressed: () => setState(() => _finished = true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
