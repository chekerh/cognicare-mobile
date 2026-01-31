import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../utils/theme.dart';

class OnboardingSlideData {
  final IconData icon;
  final String titleKey;
  final String descriptionKey;

  const OnboardingSlideData({
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
  });
}

class OnboardingSlide extends StatelessWidget {
  final OnboardingSlideData data;

  const OnboardingSlide({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              data.icon,
              size: 60,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            _getLocalizedText(localizations, data.titleKey),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.text,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Description
          Text(
            _getLocalizedText(localizations, data.descriptionKey),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.text.withOpacity(0.7),
                  height: 1.6,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getLocalizedText(AppLocalizations localizations, String key) {
    switch (key) {
      case 'onboardingWelcomeTitle':
        return localizations.onboardingWelcomeTitle;
      case 'onboardingWelcomeDescription':
        return localizations.onboardingWelcomeDescription;
      case 'onboardingFeaturesTitle':
        return localizations.onboardingFeaturesTitle;
      case 'onboardingFeaturesDescription':
        return localizations.onboardingFeaturesDescription;
      case 'onboardingAccessibilityTitle':
        return localizations.onboardingAccessibilityTitle;
      case 'onboardingAccessibilityDescription':
        return localizations.onboardingAccessibilityDescription;
      default:
        return '';
    }
  }
}