import 'package:flutter/cupertino.dart';

import '../../../theme/app_theme.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.flag,
    required this.languageName,
    required this.onProfile,
    required this.onSettings,
  });

  final String flag;
  final String languageName;
  final VoidCallback onProfile;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LanguageChip(flag: flag, name: languageName),
        const Spacer(),
        _HeaderIcon(
          icon: CupertinoIcons.person_crop_circle,
          label: 'Profil',
          onTap: onProfile,
        ),
        _HeaderIcon(
          icon: CupertinoIcons.gear_alt,
          label: 'Einstellungen',
          onTap: onSettings,
        ),
      ],
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({required this.flag, required this.name});

  final String flag;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Zielsprache: $name',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.hairline),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$flag  $name',
          style: AppType.chrome(
            size: 13,
            weight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label: label,
          excludeSemantics: true,
          child: Icon(icon, size: 24, color: AppColors.textMuted),
        ),
      ),
    );
  }
}
