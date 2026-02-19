import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/call_provider.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'providers/cart_provider.dart';
import 'providers/community_feed_provider.dart';
import 'providers/language_provider.dart';
import 'providers/sticker_book_provider.dart';
import 'providers/child_security_code_provider.dart';
import 'providers/child_mode_session_provider.dart';
import 'providers/gamification_provider.dart';
import 'services/gamification_service.dart';
import 'services/children_service.dart';
import 'utils/router.dart';
import 'utils/theme.dart';
import 'widgets/call_connection_handler.dart';
import 'services/notification_service.dart';

const String _themeIdKey = 'app_theme_id';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await NotificationService().initialize();
    final prefs = await SharedPreferences.getInstance();
    final savedThemeId = prefs.getString(_themeIdKey);
    runApp(CogniCareApp(initialThemeId: savedThemeId));
  }, (error, stack) {
    // Voice playback errors from audioplayers (e.g. 404 on Render) are already
    // shown via SnackBar in chat; avoid logging as unhandled.
    if (error is PlatformException &&
        (error.code == 'DarwinAudioError' ||
            error.message?.contains('DarwinAudioError') == true)) {
      return;
    }
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      stack: stack,
      library: 'runZonedGuarded',
    ));
  });
}

class CogniCareApp extends StatefulWidget {
  const CogniCareApp({super.key, this.initialThemeId});

  final String? initialThemeId;

  @override
  State<CogniCareApp> createState() => _CogniCareAppState();
}

class _CogniCareAppState extends State<CogniCareApp> {
  late final AuthProvider _authProvider;
  late final ThemeProvider _themeProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _themeProvider = ThemeProvider(initialThemeId: widget.initialThemeId);
    _router = createAppRouter(_authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _themeProvider),
        ChangeNotifierProvider(create: (_) => CallProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CommunityFeedProvider()),
        ChangeNotifierProvider(create: (_) => StickerBookProvider()),
        ChangeNotifierProvider(create: (_) => ChildSecurityCodeProvider()),
        ChangeNotifierProvider(create: (_) => ChildModeSessionProvider()),
        ChangeNotifierProxyProvider<AuthProvider, GamificationProvider>(
          create: (context) {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final gamificationService = GamificationService(
              getToken: () async => authProvider.accessToken,
            );
            final childrenService = ChildrenService(
              getToken: () async => authProvider.accessToken,
            );
            return GamificationProvider(
              gamificationService: gamificationService,
              childrenService: childrenService,
            );
          },
          update: (context, authProvider, previous) {
            if (previous == null) {
              final gamificationService = GamificationService(
                getToken: () async => authProvider.accessToken,
              );
              final childrenService = ChildrenService(
                getToken: () async => authProvider.accessToken,
              );
              return GamificationProvider(
                gamificationService: gamificationService,
                childrenService: childrenService,
              );
            }
            return previous;
          },
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (_, auth, __) => Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) => PresencePinger(
            isAuthenticated: auth.isAuthenticated,
            child: CallConnectionHandler(
              child: MaterialApp.router(
                title: 'CogniCare',
                theme: AppTheme.lightTheme,
                routerConfig: _router,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: languageProvider.locale,
                debugShowCheckedModeBanner: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Calls [AuthService.updatePresence] periodically while the user is logged in
/// so they appear "online" in chat. Stops when logged out or disposed.
class PresencePinger extends StatefulWidget {
  const PresencePinger({
    super.key,
    required this.isAuthenticated,
    required this.child,
  });

  final bool isAuthenticated;
  final Widget child;

  @override
  State<PresencePinger> createState() => _PresencePingerState();
}

class _PresencePingerState extends State<PresencePinger> {
  Timer? _timer;

  void _startTimer() {
    _timer?.cancel();
    AuthService().updatePresence(); // Ping once so we're online right after login
    _timer = Timer.periodic(const Duration(minutes: 2), (_) async {
      await AuthService().updatePresence();
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.isAuthenticated) _startTimer();
  }

  @override
  void didUpdateWidget(PresencePinger oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAuthenticated != widget.isAuthenticated) {
      if (widget.isAuthenticated) {
        _startTimer();
      } else {
        _cancelTimer();
      }
    }
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
