/// Shared document-context bridge between the Reader and Chat tabs.
///
/// When the user taps "Ask Agent" in the document reader, the current section
/// text is placed into [readerContextProvider]. The chat page watches it and
/// pre-fills the input field so the user can immediately ask a question about
/// the section.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A pending document-context query from the Reader.
class ReaderContext {
  const ReaderContext({
    required this.documentTitle,
    required this.sectionLocator,
    required this.sectionTitle,
    required this.text,
  });

  final String documentTitle;
  final String sectionLocator;
  final String sectionTitle;

  /// First 4000 chars of the section plain text (enough for most prompts).
  final String text;

  /// Renders a prompt preamble the model can use as grounding context.
  String renderPrompt() {
    final label = sectionTitle.isNotEmpty
        ? '[$documentTitle — $sectionTitle ($sectionLocator)]'
        : '[$documentTitle — $sectionLocator]';
    return 'Context from document:\n$label\n\n$text';
  }
}

/// Notifier that holds a pending [ReaderContext] until the Chat page consumes
/// it. The Reader sets it; the Chat page reads and clears it.
class ReaderContextNotifier extends Notifier<ReaderContext?> {
  @override
  ReaderContext? build() => null;

  /// Sets a pending context from the Reader.
  void set(ReaderContext ctx) => state = ctx;

  /// Consumes and clears the context (called by Chat page).
  ReaderContext? consume() {
    final ctx = state;
    state = null;
    return ctx;
  }
}

/// Holds a pending [ReaderContext] until the Chat page consumes it.
final readerContextProvider =
    NotifierProvider<ReaderContextNotifier, ReaderContext?>(
  ReaderContextNotifier.new,
);
