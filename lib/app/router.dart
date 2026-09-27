/// Application routing (design doc §17).
///
/// A single [GoRouter] with a [StatefulShellRoute.indexedStack] over the four
/// tabs. `indexedStack` keeps each branch alive so an in-progress agent run in
/// the Chat tab is not torn down when the user peeks at Files or Terminal.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/chat/chat_page.dart';
import '../ui/files/files_page.dart';
import '../ui/editor/editor_page.dart';
import '../ui/reader/documents_page.dart';
import '../ui/reader/document_reader_page.dart';
import '../ui/settings/settings_page.dart';
import '../ui/terminal/terminal_page.dart';
import 'shell/app_shell.dart';
import '../l10n/l10n.dart';

final Provider<GoRouter> routerProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    initialLocation: '/chat',
    debugLogDiagnostics: false,
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) => AppShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/chat',
                name: 'chat',
                builder: (BuildContext context, GoRouterState state) =>
                    const ChatPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/files',
                name: 'files',
                builder: (BuildContext context, GoRouterState state) =>
                    const FilesPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'editor',
                    name: 'editor',
                    builder: (BuildContext context, GoRouterState state) =>
                        EditorPage(
                          path: state.uri.queryParameters['path'] ?? '',
                          name: state.uri.queryParameters['name'] ?? 'Editor',
                        ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/documents',
                name: 'documents',
                builder: (BuildContext context, GoRouterState state) =>
                    const DocumentsPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'reader',
                    name: 'document-reader',
                    builder: (BuildContext context, GoRouterState state) =>
                        DocumentReaderPage(
                          documentId: state.uri.queryParameters['id'] ?? '',
                        ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (BuildContext context, GoRouterState state) =>
                    const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      appBar: AppBar(title: Text(context.l10n.notFound)),
      body: Center(child: Text(context.l10n.noRouteFor('${state.uri}'))),
    ),
  );
});
