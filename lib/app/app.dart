/// The root widget: a [MaterialApp.router] wired to Riverpod.
///
/// Keeps theming and router subscription in one place so `main.dart` stays a
/// two-liner and the widget tree is trivially testable via [ProviderScope]
/// overrides.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/generated/app_localizations.dart';
import '../core/legal/privacy_consent.dart';
import '../ui/legal/privacy_consent_page.dart';
import 'router.dart';
import 'theme.dart';

class AgentFlowApp extends ConsumerStatefulWidget {
  const AgentFlowApp({super.key});

  @override
  ConsumerState<AgentFlowApp> createState() => _AgentFlowAppState();
}

class _AgentFlowAppState extends ConsumerState<AgentFlowApp> {
  final PrivacyConsentStore _consentStore = const PrivacyConsentStore();
  late Future<bool> _consent = _consentStore.hasConsent();

  Future<void> _grantConsent() async {
    await _consentStore.grant();
    if (mounted) setState(() => _consent = Future<bool>.value(true));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _consent,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _materialApp(
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.data != true) {
          return _materialApp(home: PrivacyConsentPage(onAgree: _grantConsent));
        }
        final router = ref.watch(routerProvider);
        return MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          localizationsDelegates: _delegates,
          supportedLocales: AppLocalizations.supportedLocales,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          routerConfig: router,
        );
      },
    );
  }

  MaterialApp _materialApp({required Widget home}) => MaterialApp(
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    localizationsDelegates: _delegates,
    supportedLocales: AppLocalizations.supportedLocales,
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: ThemeMode.system,
    home: home,
  );

  static const List<LocalizationsDelegate<dynamic>> _delegates =
      <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];
}
