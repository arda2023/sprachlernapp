import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Opens content readers only after bundled installation has finished.
class ContentStartupGate extends StatefulWidget {
  const ContentStartupGate({
    super.key,
    required this.initialize,
    required this.child,
  });

  final Future<void> Function() initialize;
  final Widget child;

  @override
  State<ContentStartupGate> createState() => _ContentStartupGateState();
}

class _ContentStartupGateState extends State<ContentStartupGate> {
  Timer? _hintTimer;
  bool _ready = false;
  bool _showHint = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // Render the first frame before starting potentially lengthy validation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initialize();
    });
  }

  Future<void> _initialize() async {
    setState(() => _failed = false);
    _hintTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _showHint = true);
    });
    try {
      await widget.initialize();
      if (mounted) setState(() => _ready = true);
    } catch (error, stack) {
      debugPrint('Inhalte konnten nicht vorbereitet werden: $error\n$stack');
      if (mounted) setState(() => _failed = true);
    } finally {
      _hintTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.child;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(brightness: Brightness.light),
      darkTheme: buildAppTheme(),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _failed
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Deine Wörter konnten nicht vorbereitet werden.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _initialize,
                          child: const Text('Erneut versuchen'),
                        ),
                      ],
                    )
                  : _showHint
                  ? Semantics(
                      liveRegion: true,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 24),
                          Text(
                            'Deine Wörter werden vorbereitet.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
