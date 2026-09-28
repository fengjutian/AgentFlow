/// Document reader — displays PDF pages or EPUB chapters with TOC navigation.
///
/// Shows the extracted text from parsed sections. For PDFs each section is a
/// page; for EPUBs each section is a chapter. A drawer provides table of
/// contents navigation and an "Ask Agent" button to send the current section
/// context to the chat.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/document/document.dart';
import '../../l10n/l10n.dart';
import 'reader_context.dart';

class DocumentReaderPage extends ConsumerStatefulWidget {
  const DocumentReaderPage({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<DocumentReaderPage> createState() => _DocumentReaderPageState();
}

class _DocumentReaderPageState extends ConsumerState<DocumentReaderPage> {
  AgentDocument? _document;
  List<DocumentSection> _sections = const <DocumentSection>[];
  int _currentIndex = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = ref.read(documentStoreProvider);
    try {
      final doc = await store.byId(widget.documentId);
      if (doc == null) {
        setState(() {
          _error = context.l10n.documentNotFound;
          _loading = false;
        });
        return;
      }
      final sections = await store.sections(widget.documentId);
      // Restore reading position (DOC-07).
      final savedIndex = doc.lastSectionIndex;
      final initialIndex = (savedIndex != null &&
              savedIndex >= 0 &&
              savedIndex < sections.length)
          ? savedIndex
          : 0;
      setState(() {
        _document = doc;
        _sections = sections;
        _currentIndex = initialIndex;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _document == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.reader)),
        body: Center(child: Text(_error ?? context.l10n.unknownError)),
      );
    }
    final title = _document!.title.isEmpty
        ? _document!.displayName
        : _document!.title;
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (_sections.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  context.l10n.pageIndicator(_currentIndex + 1, _sections.length),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.toc),
            tooltip: context.l10n.tableOfContents,
            onPressed: _sections.isEmpty ? null : _showToc,
          ),
        ],
      ),
      body: _sections.isEmpty
          ? Center(child: Text(context.l10n.noExtractedText))
          : _buildSectionView(),
      bottomNavigationBar: _sections.length > 1
          ? BottomAppBar(
              height: 48,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed:
                        _currentIndex > 0 ? () => _goTo(_currentIndex - 1) : null,
                  ),
                  Expanded(
                    child: Slider(
                      value: _currentIndex.toDouble(),
                      min: 0,
                      max: (_sections.length - 1).toDouble(),
                      divisions: _sections.length - 1,
                      label: '${_currentIndex + 1}',
                      onChanged: (v) => _goTo(v.round()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentIndex < _sections.length - 1
                        ? () => _goTo(_currentIndex + 1)
                        : null,
                  ),
                ],
              ),
            )
          : null,
      floatingActionButton: FloatingActionButton.small(
        onPressed: _showAgentActions,
        tooltip: context.l10n.askAgentAboutSection,
        child: const Icon(Icons.smart_toy_outlined),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSectionView() {
    final section = _sections[_currentIndex];
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                section.title,
                style: theme.textTheme.titleMedium,
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              section.locator,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(
            section.plainText.isEmpty
                ? context.l10n.noExtractableText
                : section.plainText,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }

  void _goTo(int index) {
    if (index < 0 || index >= _sections.length) return;
    setState(() => _currentIndex = index);
    // Persist reading position (DOC-07).
    ref.read(documentStoreProvider).saveReadingPosition(
      widget.documentId,
      index,
    );
  }

  void _showToc() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, controller) => ListView.builder(
          controller: controller,
          itemCount: _sections.length,
          itemBuilder: (context, index) {
            final section = _sections[index];
            final label = section.title.isEmpty
                ? section.locator
                : section.title;
            return ListTile(
              dense: true,
              selected: index == _currentIndex,
              leading: Text(
                '${index + 1}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              title: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                section.locator,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              onTap: () {
                Navigator.pop(context);
                _goTo(index);
              },
            );
          },
        ),
      ),
    );
  }

  void _showAgentActions() {
    final docTitle = _document!.title.isEmpty
        ? _document!.displayName
        : _document!.title;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.smart_toy_outlined),
              title: Text(context.l10n.askAboutThisSection),
              subtitle: Text(context.l10n.sendSectionToAgent),
              onTap: () {
                Navigator.pop(sheetContext);
                _sendToChat(
                  docTitle: docTitle,
                  instruction: context.l10n.explainThisSection,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.summarize_outlined),
              title: Text(context.l10n.summarizeThisSection),
              onTap: () {
                Navigator.pop(sheetContext);
                _sendToChat(
                  docTitle: docTitle,
                  instruction: context.l10n.summarizeSectionConcisely,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: Text(context.l10n.extractKeyConcepts),
              onTap: () {
                Navigator.pop(sheetContext);
                _sendToChat(
                  docTitle: docTitle,
                  instruction: context.l10n.extractKeyConceptsDescription,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendToChat({required String docTitle, required String instruction}) {
    final section = _sections[_currentIndex];
    final text = section.plainText.length > 4000
        ? '${section.plainText.substring(0, 4000)}…'
        : section.plainText;
    final ctx = ReaderContext(
      documentTitle: docTitle,
      sectionLocator: section.locator,
      sectionTitle: section.title,
      text: text,
    );
    ref.read(readerContextProvider.notifier).set(ctx);
    // Navigate to the chat tab.
    final router = ref.read(routerProvider);
    router.go('/chat');
  }
}
