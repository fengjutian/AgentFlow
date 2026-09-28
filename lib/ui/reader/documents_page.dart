/// Document library — lists imported PDFs/EPUBs with import and delete actions.
///
/// Each document tile shows title, type badge, parse status and section count.
/// Tapping opens the reader; long-press shows a delete confirmation.
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/document/document.dart';
import '../../core/document/document_service.dart';
import '../../l10n/l10n.dart';

class DocumentsPage extends ConsumerStatefulWidget {
  const DocumentsPage({super.key});

  @override
  ConsumerState<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends ConsumerState<DocumentsPage> {
  bool _importing = false;

  Future<void> _importDocument() async {
    final workspaceId = ref.read(activeWorkspaceProvider);
    if (workspaceId == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;

    setState(() => _importing = true);
    try {
      final importService = await ref.read(documentImportServiceProvider.future);
      await importService.import(DocumentImportRequest(
        workspaceId: workspaceId,
        sourcePath: file.path!,
        displayName: file.name,
      ));
      if (mounted) setState(() {}); // Refresh list.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.importFailed(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspaceId = ref.watch(activeWorkspaceProvider);
    final store = ref.watch(documentStoreProvider);
    return Scaffold(
      floatingActionButton: workspaceId != null
          ? FloatingActionButton.extended(
              onPressed: _importing ? null : _importDocument,
              icon: _importing
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.file_upload_outlined),
              label: Text(_importing ? context.l10n.importing : context.l10n.import),
            )
          : null,
      body: workspaceId == null
          ? Center(child: Text(context.l10n.selectWorkspaceFirst))
          : FutureBuilder<List<AgentDocument>>(
              future: store.forWorkspace(workspaceId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final documents = snapshot.data ?? const <AgentDocument>[];
                if (documents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.library_books_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(context.l10n.noImportedDocuments,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(context.l10n.importDocumentHint,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
                    itemCount: documents.length,
                    itemBuilder: (context, index) => _DocumentTile(
                      document: documents[index],
                      store: store,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _DocumentTile extends ConsumerWidget {
  const _DocumentTile({required this.document, required this.store});

  final AgentDocument document;
  final DocumentStore store;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final title = document.title.isEmpty
        ? document.displayName
        : document.title;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(
          document.type == DocumentType.pdf
              ? Icons.picture_as_pdf
              : Icons.menu_book,
          color: theme.colorScheme.primary,
        ),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${document.type.name.toUpperCase()} · '
          '${document.parseStatus.name} · '
          '${document.sectionCount} sections',
          style: theme.textTheme.bodySmall,
        ),
        trailing: _StatusChip(status: document.parseStatus),
        onTap: () {
          final router = ref.read(routerProvider);
          router.push(Uri(
            path: '/documents/reader',
            queryParameters: {'id': document.id},
          ).toString());
        },
        onLongPress: () => _confirmDelete(context, ref),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteDocumentTitle),
        content: Text(context.l10n.deleteDocumentDescription(document.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      await store.delete(document.id);
    });
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final DocumentParseStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      DocumentParseStatus.ready => ('Ready', Colors.green),
      DocumentParseStatus.parsing => ('Parsing', Colors.orange),
      DocumentParseStatus.pending => ('Pending', Colors.grey),
      DocumentParseStatus.failed => ('Failed', Colors.red),
      DocumentParseStatus.ocrRequired => ('OCR needed', Colors.deepOrange),
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: color.withValues(alpha: 0.15),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
