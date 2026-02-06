import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/community_feed_provider.dart';
import 'providers/language_provider.dart';
import 'utils/router.dart';
import 'utils/theme.dart';

void main() {
  runApp(const CogniCareApp());
}

class CogniCareApp extends StatefulWidget {
  const CogniCareApp({super.key});

  @override
  State<CogniCareApp> createState() => _CogniCareAppState();
}

class _CogniCareAppState extends State<CogniCareApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = createAppRouter(_authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => CommunityFeedProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) => MaterialApp.router(
          title: 'CogniCare',
          theme: AppTheme.lightTheme,
          routerConfig: _router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: languageProvider.locale,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
