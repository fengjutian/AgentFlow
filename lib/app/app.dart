/// The root widget: a [MaterialApp.router] wired to Riverpod.
///
/// Keeps theming and router subscription in one place so `main.dart` stays a
/// two-liner and the widget tree is trivially testable via [ProviderScope]
/// overrides.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class AgentFlowApp extends ConsumerWidget {
  const AgentFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'AgentFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
