import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/presentation/content_startup_gate.dart';

void main() {
  testWidgets('slow installation is visible and defers reader construction', (
    tester,
  ) async {
    final completion = Completer<void>();
    var childBuilds = 0;
    await tester.pumpWidget(
      ContentStartupGate(
        initialize: () => completion.future,
        child: Builder(
          builder: (_) {
            childBuilds++;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(childBuilds, 0);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Deine Wörter werden vorbereitet.'), findsOneWidget);
    expect(childBuilds, 0);
    completion.complete();
    await tester.pump();
    expect(childBuilds, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('unchanged startup finishes before showing a loading hint', (
    tester,
  ) async {
    await tester.pumpWidget(
      ContentStartupGate(
        initialize: () async {},
        child: const SizedBox(key: ValueKey('ready')),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('ready')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('failed initialization blocks readers and can be retried', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      ContentStartupGate(
        initialize: () async {
          if (++attempts == 1) throw StateError('test failure');
        },
        child: const SizedBox(key: ValueKey('ready')),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('ready')), findsNothing);
    expect(find.text('Erneut versuchen'), findsOneWidget);
    await tester.tap(find.text('Erneut versuchen'));
    await tester.pump();
    expect(attempts, 2);
    expect(find.byKey(const ValueKey('ready')), findsOneWidget);
  });
}
