import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/presentation/notifications/learning_reminder_invitation.dart';
import 'package:sprachapp/presentation/providers/notification_provider.dart';
import 'package:sprachapp/theme/app_theme.dart';

const _scope = (owner: 'account-a', language: 'en');

class _Notifications extends NotificationController {
  int claims = 0;
  int permissionRequests = 0;

  @override
  NotificationState build() => const NotificationState(
    supported: true,
    ready: true,
    scope: _scope,
    canInvite: true,
  );

  @override
  Future<bool> claimLearningInvitation(LearningReminderScope scope) async {
    expect(scope, _scope);
    claims++;
    if (claims > 1) return false;
    state = const NotificationState(
      supported: true,
      ready: true,
      scope: _scope,
    );
    return true;
  }

  @override
  Future<void> enableFromInvitation(LearningReminderScope scope) async {
    expect(scope, _scope);
    permissionRequests++;
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('invitation asks permission only after an explicit tap', (
    tester,
  ) async {
    final controller = _Notifications();
    final success = ValueNotifier(false);
    addTearDown(success.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [notificationProvider.overrideWith(() => controller)],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: success,
              builder: (context, finished, _) => finished
                  ? const LearningReminderInvitation(
                      fallback: Text('Andere Aktion'),
                    )
                  : const Text('Übung läuft'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.claims, 0);
    expect(find.text('Erinnerungen aktivieren'), findsNothing);

    success.value = true;
    await tester.pumpAndSettle();
    expect(controller.claims, 1);
    expect(controller.permissionRequests, 0);
    expect(find.text('Andere Aktion'), findsNothing);
    await tester.tap(find.text('Erinnerungen aktivieren'));
    await tester.pumpAndSettle();
    expect(controller.permissionRequests, 1);
    expect(find.text('Erinnerungen aktivieren'), findsNothing);
    expect(find.text('Andere Aktion'), findsNothing);

    success.value = false;
    await tester.pumpAndSettle();
    success.value = true;
    await tester.pumpAndSettle();
    expect(controller.claims, 1);
    expect(find.text('Andere Aktion'), findsOneWidget);
  });
}
