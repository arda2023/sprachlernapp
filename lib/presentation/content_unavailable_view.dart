import 'package:flutter/cupertino.dart';

import '../domain/content.dart';
import '../theme/app_theme.dart';

class ContentUnavailableView extends StatelessWidget {
  const ContentUnavailableView({
    super.key,
    required this.error,
    required this.onRetry,
  });
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inhalte nicht verfügbar',
          style: AppType.editorial(
            color: context.appColors.textPrimary,
            size: 22,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          error is ContentUnavailable
              ? switch ((error as ContentUnavailable).reason) {
                  ContentUnavailableReason.missing =>
                    'Kein Inhaltspaket installiert.',
                  ContentUnavailableReason.corrupt =>
                    'Das Inhaltspaket ist beschädigt.',
                  ContentUnavailableReason.incompatible =>
                    'Das Inhaltspaket ist nicht kompatibel.',
                }
              : 'Die lokalen Daten konnten nicht geladen werden.',
          style: AppType.chrome(color: context.appColors.textPrimary),
        ),
        CupertinoButton(
          onPressed: onRetry,
          child: Text(
            'Erneut versuchen',
            style: AppType.chrome(color: context.appColors.textPrimary),
          ),
        ),
      ],
    ),
  );
}
