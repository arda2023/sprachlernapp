import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';

void main() {
  test('activation barrier waits for all scopes and asynchronous close; new readers wait for resume', () async {
    var opens = 0;
    final closing = Completer<void>();
    final owner = RepositoryOwner<int>(
      () async => ++opens,
      (_) => closing.future,
    );
    final provider = FutureProvider<int>(owner.acquire, retry: (_, _) => null);
    final old = ProviderContainer();
    expect(await old.read(provider.future), 1);
    owner.pause();
    await expectLater(owner.closed(), throwsStateError);
    old.dispose();
    var closed = false;
    final barrier = owner.closed().then((_) => closed = true);
    await Future<void>.delayed(Duration.zero);
    expect(closed, false);
    closing.complete();
    await barrier;
    final next = ProviderContainer();
    final opening = next.read(provider.future);
    await Future<void>.delayed(Duration.zero);
    expect(opens, 1);
    owner.resume();
    expect(await opening, 2);
    next.dispose();
  });
}
