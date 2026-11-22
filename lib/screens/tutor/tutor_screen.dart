import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/premium_offer.dart';
import '../../domain/tutor.dart';
import '../../presentation/providers/premium_access_provider.dart';
import '../../presentation/providers/tutor_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_content_gate.dart';
import '../onboarding/widgets/account_sheet.dart';
import '../settings/settings_screen.dart';
import '../web/web_reading_viewport.dart';
import 'widgets/tutor_chrome.dart';
import 'widgets/tutor_feedback.dart';
import 'widgets/tutor_info_chip.dart';

class TutorScreen extends ConsumerStatefulWidget {
  const TutorScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context).push<void>(
        CupertinoPageRoute(
          builder: (_) => const WebReadingViewport(child: TutorScreen()),
          fullscreenDialog: true,
        ),
      );

  @override
  ConsumerState<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends ConsumerState<TutorScreen> {
  final _answer = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  var _results = GlobalKey();
  bool _preparing = true, _paywallOpen = false, _retrying = false;
  bool _accessChanged = false, _leaving = false;
  String? _startupError;
  TutorAvailability? _blocked;
  TutorSessionController? _session;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_prepare());
    });
  }

  Future<void> _prepare() async {
    if (_leaving) return;
    setState(() {
      _preparing = true;
      _startupError = null;
      _blocked = null;
      _accessChanged = false;
    });
    try {
      var access = await ref.read(tutorAvailabilityProvider.future);
      if (!mounted || _leaving) return;
      if (access == TutorAvailability.accountRequired) {
        await AccountSheet.show(context, AccountReason.signIn);
        if (!mounted || _leaving) return;
        ref.invalidate(tutorAvailabilityProvider);
        access = await ref.read(tutorAvailabilityProvider.future);
      }
      if (!mounted || _leaving) return;
      if (access == TutorAvailability.consentRequired) {
        // The existing, revocable AI switch owns consent. Returning here
        // rechecks it; merely opening Settings never grants permission.
        await SettingsScreen.open(context);
        if (!mounted || _leaving) return;
        ref.invalidate(tutorAvailabilityProvider);
        access = await ref.read(tutorAvailabilityProvider.future);
      }
      if (!mounted || _leaving) return;
      if (access != TutorAvailability.available) {
        setState(() => _blocked = access);
        return;
      }
      await ref.read(tutorDependenciesProvider.future);
      if (!mounted || _leaving) return;
      _session = ref.read(tutorSessionControllerProvider.notifier);
      _session!.endRound();
      await _session!.startRound();
    } catch (_) {
      if (mounted) {
        setState(
          () => _startupError = 'Der AI-Tutor ist gerade nicht erreichbar. Bitte versuche es erneut.',
        );
      }
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  @override
  void dispose() {
    _answer.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _close() {
    _focus.unfocus();
    Navigator.of(context).maybePop();
  }

  void _changed(TutorSessionState? previous, TutorSessionState next) {
    if (_leaving) return;
    if (previous?.currentItem?.id != next.currentItem?.id) {
      // An outgoing card can still be fading out when the next answer arrives.
      _results = GlobalKey();
    }
    if (!_preparing &&
        !_leaving &&
        previous?.round.isNotEmpty == true &&
        next.round.isEmpty &&
        next.status != TutorSessionStatus.completed) {
      _focus.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_leaving) setState(() => _accessChanged = true);
      });
    }
    if (previous?.currentItem?.id != next.currentItem?.id ||
        (next.pendingAnswer != null &&
            next.pendingAnswer != previous?.pendingAnswer)) {
      _answer.text = next.pendingAnswer ?? '';
    }
    if (next.status == TutorSessionStatus.feedback &&
        previous?.lastAttempt?.attemptId != next.lastAttempt?.attemptId) {
      _focus.unfocus();
      switch (next.lastAttempt!.outcome) {
        case TutorOutcome.correct:
          HapticFeedback.successNotification();
        case TutorOutcome.acceptable:
          HapticFeedback.warningNotification();
        case TutorOutcome.incorrect:
          HapticFeedback.errorNotification();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealResults());
    }
    if (next.status == TutorSessionStatus.limitReached &&
        previous?.status != next.status &&
        next.premiumRequired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_offer());
      });
    }
    if (next.status == TutorSessionStatus.unavailable) _focus.unfocus();
  }

  void _revealResults() {
    if (!mounted ||
        _results.currentContext == null ||
        MediaQuery.textScalerOf(context).scale(17) <= 17) {
      return;
    }
    Scrollable.ensureVisible(
      _results.currentContext!,
      alignment: 0,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _offer() async {
    if (_paywallOpen || !mounted || _leaving) return;
    _focus.unfocus();
    _paywallOpen = true;
    try {
      final unlocked = await showPremiumContentPaywall(
        context,
        interest: 'AI-Tutor',
        reason: PremiumOfferReason.tutor,
      );
      if (mounted &&
          !_leaving &&
          unlocked &&
          ref.read(premiumContentAccessProvider)) {
        await _session?.retry();
      }
    } finally {
      _paywallOpen = false;
    }
  }

  Future<void> _act(TutorSessionState state) async {
    if (_preparing || _retrying || _leaving) return;
    if (_startupError != null || _blocked != null || _accessChanged) {
      if (_startupError != null) {
        ref.invalidate(tutorAvailabilityProvider);
        ref.invalidate(tutorDependenciesProvider);
      }
      await _prepare();
      return;
    }
    switch (state.status) {
      case TutorSessionStatus.answering:
        if (_answer.text.trim().isEmpty) return;
        _focus.unfocus();
        await _session?.submitAnswer(state.pendingAnswer ?? _answer.text);
      case TutorSessionStatus.feedback:
        if (_scroll.hasClients) _scroll.jumpTo(0);
        await _session?.next();
      case TutorSessionStatus.completed:
        _close();
      case TutorSessionStatus.limitReached:
        if (state.premiumRequired) {
          await _offer();
        } else {
          _close();
        }
      case TutorSessionStatus.offline || TutorSessionStatus.error:
        setState(() => _retrying = true);
        try {
          await _session?.retry();
        } finally {
          if (mounted) setState(() => _retrying = false);
        }
      case TutorSessionStatus.unavailable || TutorSessionStatus.idle:
        await _prepare();
      case TutorSessionStatus.loading || TutorSessionStatus.grading:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(tutorSessionControllerProvider, _changed);
    final state = ref.watch(tutorSessionControllerProvider);
    final colors = context.appColors;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final unsupported = _blocked == TutorAvailability.unsupportedLanguage;
    final busy =
        _preparing ||
        _retrying ||
        (!_accessChanged &&
            _startupError == null &&
            _blocked == null &&
            {
              TutorSessionStatus.idle,
              TutorSessionStatus.loading,
              TutorSessionStatus.grading,
            }.contains(state.status));
    final problem =
        _startupError ??
        (_accessChanged
            ? 'Konto, Sprache oder KI-Freigabe haben sich geändert. Bitte prüfe deinen Zugang.'
            : null) ??
        _accessMessage ??
        switch (state.status) {
          TutorSessionStatus.offline => 'Du bist gerade offline. Prüfe deine Verbindung und versuche es erneut.',
          TutorSessionStatus.error =>
            state.failure?.message ??
                'Der AI-Tutor ist gerade nicht erreichbar.',
          TutorSessionStatus.unavailable => 'Konto oder KI-Freigabe haben sich geändert. Bitte prüfe deinen Zugang.',
          TutorSessionStatus.limitReached =>
            state.premiumRequired
                ? 'Deine freien Sätze für heute sind aufgebraucht.'
                : 'Für heute ist Schluss. Morgen kannst du weiterüben.',
          _ => null,
        };
    final label = _accessChanged
        ? 'Zugang prüfen'
        : unsupported
        ? 'Fertig'
        : _startupError != null
        ? 'Erneut versuchen'
        : _blocked == TutorAvailability.accountRequired
        ? 'Anmelden'
        : _blocked == TutorAvailability.consentRequired
        ? 'Freigabe öffnen'
        : switch (state.status) {
            TutorSessionStatus.feedback =>
              state.isLastItem ? 'Fertig' : 'Weiter',
            TutorSessionStatus.completed => 'Fertig',
            TutorSessionStatus.offline ||
            TutorSessionStatus.error => 'Erneut versuchen',
            TutorSessionStatus.unavailable => 'Zugang prüfen',
            TutorSessionStatus.limitReached =>
              state.premiumRequired ? 'Premium ansehen' : 'Fertig',
            _ => 'Prüfen',
          };
    final showItem =
        !_preparing &&
        !_accessChanged &&
        _blocked == null &&
        _startupError == null &&
        state.currentItem != null &&
        state.status != TutorSessionStatus.completed &&
        state.status != TutorSessionStatus.unavailable;
    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _leaving = true;
          _session?.endRound();
        }
      },
      child: Scaffold(
        backgroundColor: colors.nightPage,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              TutorSessionBar(
                done: state.status == TutorSessionStatus.completed
                    ? state.total
                    : state.completed,
                total: state.total,
                onClose: _close,
              ),
              Expanded(
                child: SingleChildScrollView(
                  key: const Key('tutor-scroll'),
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: AnimatedSwitcher(
                    duration: reduced
                        ? Duration.zero
                        : const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, .025),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: showItem
                        ? _item(state, problem)
                        : state.status == TutorSessionStatus.completed &&
                              !_preparing &&
                              _blocked == null &&
                              _startupError == null
                        ? _completion(state)
                        : Padding(
                            key: ValueKey(problem ?? 'loading'),
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Semantics(
                              liveRegion: true,
                              child: Column(
                                children: [
                                  Text(
                                    problem == null
                                        ? 'Deine Runde wird vorbereitet'
                                        : unsupported
                                        ? 'Noch nicht verfügbar'
                                        : 'AI-Tutor',
                                    textAlign: TextAlign.center,
                                    style: AppType.editorial(
                                      size: 24,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  if (problem != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      problem,
                                      textAlign: TextAlign.center,
                                      style: AppType.chrome(
                                        size: 15,
                                        color: colors.textMuted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _answer,
                  builder: (context, value, _) => TutorActionButton(
                    key: const Key('tutor-action'),
                    label: label,
                    busy: busy,
                    onPressed:
                        busy ||
                            (state.status == TutorSessionStatus.answering &&
                                value.text.trim().isEmpty &&
                                _blocked == null &&
                                _startupError == null)
                        ? null
                        : unsupported
                        ? _close
                        : () => _act(state),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? get _accessMessage => switch (_blocked) {
    TutorAvailability.accountRequired =>
      'Melde dich mit einem bestätigten Konto an, um eigene Sätze zu üben.',
    TutorAvailability.consentRequired => 'Aktiviere „Private Lernkarten mit KI“ in den Einstellungen, um den AI-Tutor zu nutzen.',
    TutorAvailability.unsupportedLanguage =>
      'Für diese Sprache ist der AI-Tutor noch nicht verfügbar.',
    _ => null,
  };

  Widget _item(TutorSessionState state, String? problem) {
    final colors = context.appColors;
    final item = state.currentItem!;
    final attempt = state.lastAttempt;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final locked =
        state.status != TutorSessionStatus.answering ||
        state.pendingAnswer != null;
    return Container(
      key: ValueKey(item.id),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      decoration: BoxDecoration(
        color: colors.raisedInk,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TutorInfoChip(item: item),
          ),
          const SizedBox(height: 4),
          Text(
            stripTutorInstruction(item.promptDe),
            key: const Key('tutor-prompt'),
            style: AppType.editorial(
              size: 24,
              height: 1.2,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _AnswerSize(
            child: AnimatedContainer(
              key: const Key('tutor-answer-surface'),
              duration: reduced
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              width: double.infinity,
              decoration: BoxDecoration(
                color: attempt == null
                    ? colors.playback.withValues(alpha: .45)
                    : tutorOutcomeTint(colors, attempt.outcome),
                borderRadius: BorderRadius.circular(12),
                border: attempt == null
                    ? null
                    : Border.all(
                        color: tutorOutcomeColor(
                          colors,
                          attempt.outcome,
                        ).withValues(alpha: .55),
                      ),
              ),
              child: attempt == null
                  ? CupertinoTextField(
                      key: const Key('tutor-answer-field'),
                      controller: _answer,
                      focusNode: _focus,
                      placeholder: 'Deine Antwort …',
                      placeholderStyle: AppType.chrome(
                        size: 17,
                        color: colors.textMuted,
                      ),
                      style: AppType.chrome(
                        size: 17,
                        height: 1.35,
                        color: colors.textPrimary,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: null,
                      minLines: 2,
                      maxLines: 3,
                      maxLength: 300,
                      readOnly: locked,
                      autocorrect: false,
                      enableSuggestions: false,
                      smartDashesType: SmartDashesType.disabled,
                      smartQuotesType: SmartQuotesType.disabled,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (!locked) unawaited(_act(state));
                      },
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        attempt.answer,
                        key: const Key('tutor-readonly-answer'),
                        style: AppType.chrome(
                          size: 17,
                          height: 1.35,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
            ),
          ),
          if (attempt != null) ...[
            const SizedBox(height: 8),
            TutorFeedback(key: _results, attempt: attempt),
          ],
          if (problem != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                problem,
                style: AppType.chrome(size: 15, color: colors.textMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _completion(TutorSessionState state) {
    final colors = context.appColors;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final summary = state.summary;
    return Padding(
      key: const Key('tutor-completed'),
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          ExcludeSemantics(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: reduced ? 1 : 0, end: 1),
              duration: reduced
                  ? Duration.zero
                  : const Duration(milliseconds: 520),
              builder: (context, value, _) => Transform.scale(
                scale: .85 + .15 * Curves.easeOutBack.transform(value),
                child: CustomPaint(
                  size: const Size(64, 64),
                  painter: TutorVerdictPainter(
                    score: 2,
                    progress: value,
                    color: colors.success,
                    celebrate: !reduced,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Semantics(
            header: true,
            liveRegion: true,
            child: Text(
              'Runde geschafft',
              textAlign: TextAlign.center,
              style: AppType.editorial(size: 28, color: colors.textPrimary),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${summary?.total ?? state.completed} ${(summary?.total ?? state.completed) == 1 ? 'Satz' : 'Sätze'} geübt',
            style: AppType.chrome(size: 17, color: colors.textMuted),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              Text(
                '${summary?.correct ?? 0} richtig',
                style: AppType.chrome(size: 15, color: colors.success),
              ),
              Text(
                '${summary?.acceptable ?? 0} tolerierbar',
                style: AppType.chrome(size: 15, color: colors.active),
              ),
              if ((summary?.incorrect ?? 0) > 0)
                Text(
                  '${summary!.incorrect} noch üben',
                  style: AppType.chrome(size: 15, color: colors.error),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnswerSize extends StatelessWidget {
  const _AnswerSize({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery.disableAnimationsOf(context)
      ? child
      : AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: child,
        );
}
