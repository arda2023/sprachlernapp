import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/widgets/launch_splash.dart';

class _Ready extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

final _ready = NotifierProvider<_Ready, bool>(_Ready.new);

/// Counts its own taps, so a remount (lost state) is visible.
class _Counter extends StatefulWidget {
  const _Counter();
  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int taps = 0;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => taps++),
    child: Text('taps $taps'),
  );
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<ProviderContainer> pumpCurtain(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: LaunchCurtain(
            ready: (ref) => ref.watch(_ready),
            child: const _Counter(),
          ),
        ),
      ),
    );
    return container;
  }

  testWidgets('The curtain comes back while content loads and keeps the '
      'app underneath', (tester) async {
    final container = await pumpCurtain(tester);
    expect(find.byType(LaunchSplash), findsOneWidget);
    expect(find.byType(_Counter), findsNothing);

    // The intro runs on a real stopwatch (started on first use), not on the
    // test clock.
    LaunchSplash.clock.start();
    await tester.runAsync(() => Future<void>.delayed(LaunchSplash.intro));
    container.read(_ready.notifier).set(true);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(LaunchSplash), findsNothing);
    await tester.tap(find.text('taps 0'));
    await tester.pump();
    expect(find.text('taps 1'), findsOneWidget);

    // Another language starts loading: the splash covers the app again.
    container.read(_ready.notifier).set(false);
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(LaunchSplash), findsOneWidget);
    expect(find.text('taps 1'), findsOneWidget);

    container.read(_ready.notifier).set(true);
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(LaunchSplash), findsNothing);
    expect(find.text('taps 1'), findsOneWidget);    // Let the first-launch safety timer run out.
    await tester.pump(LaunchCurtain.maxWait);
  });
}
