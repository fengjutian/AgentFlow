/// Language Server Protocol configuration and server presets.
///
/// Maps programming languages to their conventional language server commands and
/// arguments. Ships with sensible defaults; users can override per workspace.
library;

import '../editor/syntax_highlighter.dart';

/// Configuration for a single language server instance.
class LspServerConfig {
  const LspServerConfig({
    required this.languageId,
    required this.command,
    required this.arguments,
    this.environment = const <String, String>{},
    this.initializationOptions = const <String, dynamic>{},
    this.rootUri,
  });

  /// LSP language identifier (e.g. 'dart', 'python', 'typescript').
  final String languageId;

  /// Server executable (e.g. 'dart', 'pyright-langserver').
  final String command;

  /// Command-line arguments (e.g. ['language-server', '--stdio']).
  final List<String> arguments;

  /// Environment variables passed to the server process.
  final Map<String, String> environment;

  /// LSP initializationOptions sent in the initialize request.
  final Map<String, dynamic> initializationOptions;

  /// Workspace root URI. Set by the manager before launching.
  final String? rootUri;

  LspServerConfig copyWith({
    String? languageId,
    String? command,
    List<String>? arguments,
    Map<String, String>? environment,
    Map<String, dynamic>? initializationOptions,
    String? rootUri,
  }) =>
      LspServerConfig(
        languageId: languageId ?? this.languageId,
        command: command ?? this.command,
        arguments: arguments ?? this.arguments,
        environment: environment ?? this.environment,
        initializationOptions:
            initializationOptions ?? this.initializationOptions,
        rootUri: rootUri ?? this.rootUri,
      );
}

/// Default language server presets for common languages.
///
/// These assume the language server is available on PATH. On Android/Termux
/// runtimes, the user may need to install servers manually.
const Map<String, LspServerConfig> lspDefaultPresets = <String, LspServerConfig>{
  'dart': LspServerConfig(
    languageId: 'dart',
    command: 'dart',
    arguments: <String>['language-server', '--stdio'],
  ),
  'python': LspServerConfig(
    languageId: 'python',
    command: 'pyright-langserver',
    arguments: <String>['--stdio'],
  ),
  'typescript': LspServerConfig(
    languageId: 'typescript',
    command: 'typescript-language-server',
    arguments: <String>['--stdio'],
  ),
  'javascript': LspServerConfig(
    languageId: 'javascript',
    command: 'typescript-language-server',
    arguments: <String>['--stdio'],
  ),
  'rust': LspServerConfig(
    languageId: 'rust',
    command: 'rust-analyzer',
    arguments: <String>[],
  ),
  'go': LspServerConfig(
    languageId: 'go',
    command: 'gopls',
    arguments: <String>['serve'],
  ),
  'java': LspServerConfig(
    languageId: 'java',
    command: 'jdtls',
    arguments: <String>[],
  ),
  'kotlin': LspServerConfig(
    languageId: 'kotlin',
    command: 'kotlin-language-server',
    arguments: <String>[],
  ),
  'c': LspServerConfig(
    languageId: 'c',
    command: 'clangd',
    arguments: <String>[],
  ),
  'cpp': LspServerConfig(
    languageId: 'cpp',
    command: 'clangd',
    arguments: <String>[],
  ),
  'lua': LspServerConfig(
    languageId: 'lua',
    command: 'lua-language-server',
    arguments: <String>[],
  ),
  'html': LspServerConfig(
    languageId: 'html',
    command: 'vscode-html-language-server',
    arguments: <String>['--stdio'],
  ),
  'css': LspServerConfig(
    languageId: 'css',
    command: 'vscode-css-language-server',
    arguments: <String>['--stdio'],
  ),
  'json': LspServerConfig(
    languageId: 'json',
    command: 'vscode-json-language-server',
    arguments: <String>['--stdio'],
  ),
  'yaml': LspServerConfig(
    languageId: 'yaml',
    command: 'yaml-language-server',
    arguments: <String>['--stdio'],
  ),
};

/// Maps a [CodeLanguage] enum value to an LSP language identifier string.
String lspLanguageIdFor(CodeLanguage language) => switch (language) {
      CodeLanguage.dart => 'dart',
      CodeLanguage.javascript => 'javascript',
      CodeLanguage.typescript => 'typescript',
      CodeLanguage.python => 'python',
      CodeLanguage.java => 'java',
      CodeLanguage.kotlin => 'kotlin',
      CodeLanguage.rust => 'rust',
      CodeLanguage.go => 'go',
      CodeLanguage.cpp => 'cpp',
      CodeLanguage.c => 'c',
      CodeLanguage.swift => 'swift',
      CodeLanguage.ruby => 'ruby',
      CodeLanguage.shell => 'shellscript',
      CodeLanguage.yaml => 'yaml',
      CodeLanguage.json => 'json',
      CodeLanguage.html => 'html',
      CodeLanguage.css => 'css',
      CodeLanguage.sql => 'sql',
      CodeLanguage.markdown => 'markdown',
      CodeLanguage.xml => 'xml',
      CodeLanguage.toml => 'toml',
      CodeLanguage.unknown => '',
    };
