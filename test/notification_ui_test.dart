import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/data/billing/purchase_gateway.dart';
import 'package:sprachapp/data/notifications/notification_gateway.dart';
import 'package:sprachapp/domain/notification_schedule.dart';
import 'package:sprachapp/domain/trial_reminder.dart';
import 'package:sprachapp/presentation/providers/notification_provider.dart';
import 'package:sprachapp/presentation/providers/purchase_provider.dart';
import 'package:sprachapp/screens/onboarding/paywall_screen.dart';
import 'package:sprachapp/screens/settings/settings_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';

import 'fixtures/deck_repositories.dart';

class _Notifications extends NotificationController {
  _Notifications(this.initial);
  final NotificationState initial;
  final toggles = <bool>[];
  final times = <(int, int)>[];
  @override
  NotificationState build() => initial;
  @override
  Future<void> setLearningEnabled(bool enabled) async {
    toggles.add(enabled);
    state = NotificationState(
      supported: true,
      ready: true,
      permission: NotificationPermission.allowed,
      settings: state.settings.copyWith(enabled: enabled),
    );
  }

  @override
  Future<void> setLearningTime(int hour, int minute) async =>
      times.add((hour, minute));
}

class _Purchases extends PurchaseController {
  @override
  PurchaseState build() => const PurchaseState(
    phase: PurchasePhase.ready,
    selectedProductId: 'yearly',
    billingReady: true,
    products: [
      PurchaseProduct(
        productId: 'yearly',
        plan: PurchasePlan.yearly,
        localizedPrice: '49,99 €',
        localizedPeriod: 'pro Jahr',
        isRecommended: true,
        trialDays: 7,
      ),
    ],
  );
  @override
  Future<void> load() async {}
}

Widget _host(
  Widget screen,
  _Notifications notifications, {
  Brightness brightness = Brightness.light,
  double scale = 1,
}) => testScope(
  MaterialApp(
    theme: buildAppTheme(brightness: brightness),
    locale: const Locale('de'),
    supportedLocales: const [Locale('de')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: (_, child) => MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: screen,
  ),
  overrides: [
    notificationProvider.overrideWith(() => notifications),
    purchaseProvider.overrideWith(_Purchases.new),
  ],
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('settings reminder switch and time picker are usable', (
    tester,
  ) async {
    final notifications = _Notifications(
      const NotificationState(
        supported: true,
        ready: true,
        permission: NotificationPermission.allowed,
      ),
    );
    await tester.pumpWidget(_host(const SettingsScreen(), notifications));
    await tester.pumpAndSettle();
    final label = find.text('Lern-Benachrichtigungen');
    await tester.scrollUntilVisible(
      label,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(label);
    await tester.pumpAndSettle();
    expect(notifications.toggles, [true]);
    expect(find.text('19:00'), findsOneWidget);
    expect(
      find.text('Bald'),
      findsOneWidget,
      reason: 'Only the unchanged sound placeholder remains.',
    );
    await tester.ensureVisible(find.text('Uhrzeit'));
    await tester.tap(find.text('Uhrzeit'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(notifications.times, [(19, 0)]);
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets('reminder settings fit 2x text in ${brightness.name}', (
      tester,
    ) async {
      final notifications = _Notifications(
        const NotificationState(
          supported: true,
          ready: true,
          permission: NotificationPermission.allowed,
          settings: LearningReminderSettings(enabled: true),
        ),
      );
      await tester.pumpWidget(
        _host(
          const SettingsScreen(),
          notifications,
          brightness: brightness,
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Uhrzeit'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('19:00'), findsOneWidget);
    });
  }

  for (final (permission, scheduled) in [
    (NotificationPermission.denied, true),
    (NotificationPermission.allowed, false),
    (NotificationPermission.allowed, true),
  ]) {
    testWidgets(
      'no trial offer or reminder: permission $permission, legacy schedule $scheduled',
      (tester) async {
        final notifications = _Notifications(
          NotificationState(
            supported: true,
            ready: true,
            permission: permission,
            scheduledTrial: scheduled
                ? TrialReminderPlan(
                    productId: 'yearly',
                    expiresAt: DateTime.utc(2035, 1, 2),
                    remindAt: DateTime.utc(2035, 1, 1),
                    isSandbox: false,
                  )
                : null,
          ),
        );
        await tester.pumpWidget(
          _host(
            PaywallScreen(
              plan: (interest: 'Reisen', dailyGoal: 10),
              onContinue: () {},
            ),
            notifications,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Erinnerung'), findsNothing);
        expect(find.text('49,99 €'), findsNothing);
        expect(find.textContaining('kostenlos testen'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
