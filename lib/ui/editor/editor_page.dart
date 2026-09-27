library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/editor/editor_document.dart';
import '../../l10n/l10n.dart';

class EditorPage extends ConsumerStatefulWidget {
  const EditorPage({super.key, required this.path, required this.name});

  final String path;
  final String name;

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage> {
  final TextEditingController _text = TextEditingController();
  final ScrollController _editorScroll = ScrollController();
  final ScrollController _lineScroll = ScrollController();
  EditorDocument? _document;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  int _lineCount = 1;
  bool _syncingScroll = false;

  bool get _dirty => _document?.isDirty ?? false;

  @override
  void initState() {
    super.initState();
    _text.addListener(_onTextChanged);
    _editorScroll.addListener(_syncLineScroll);
    _load();
  }

  @override
  void dispose() {
    _text
      ..removeListener(_onTextChanged)
      ..dispose();
    _editorScroll.dispose();
    _lineScroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final runtime = await ref.read(runtimeProvider.future);
      if (runtime == null) throw StateError('Runtime unavailable.');
      final document = EditorDocument(path: widget.path, runtime: runtime);
      final content = await document.load();
      if (!mounted) return;
      _document = document;
      _text.value = TextEditingValue(
        text: content,
        selection: TextSelection.collapsed(offset: content.length),
      );
      setState(() {
        _lineCount = _countLines(content);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  void _onTextChanged() {
    final document = _document;
    if (document == null) return;
    document.update(_text.text);
    final lineCount = _countLines(_text.text);
    if (mounted) setState(() => _lineCount = lineCount);
  }

  void _syncLineScroll() {
    if (_syncingScroll || !_lineScroll.hasClients) return;
    _syncingScroll = true;
    final target = _editorScroll.offset.clamp(
      0.0,
      _lineScroll.position.maxScrollExtent,
    );
    _lineScroll.jumpTo(target);
    _syncingScroll = false;
  }

  Future<void> _save() async {
    final document = _document;
    if (document == null || _saving || !document.isDirty) return;
    setState(() => _saving = true);
    try {
      final result = await document.save();
      if (!mounted) return;
      if (result == EditorSaveResult.conflict) {
        await _resolveConflict(document);
      } else {
        _showMessage(context.l10n.fileSaved);
      }
    } catch (error) {
      if (mounted) _showMessage(context.l10n.failedToSave(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resolveConflict(EditorDocument document) async {
    final decision = await showDialog<_ConflictDecision>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.fileChangedTitle),
        content: Text(context.l10n.fileChangedDescription),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, _ConflictDecision.cancel),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _ConflictDecision.reload),
            child: Text(context.l10n.reload),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, _ConflictDecision.overwrite),
            child: Text(context.l10n.overwrite),
          ),
        ],
      ),
    );
    if (decision == _ConflictDecision.reload) {
      final content = await document.reload();
      _text.value = TextEditingValue(text: content);
    } else if (decision == _ConflictDecision.overwrite) {
      await document.overwrite();
      if (mounted) _showMessage(context.l10n.fileSaved);
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.l10n.unsavedChangesTitle),
            content: Text(context.l10n.unsavedChangesDescription),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.l10n.discard),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await _confirmDiscard();
        if (!context.mounted || !discard) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${_dirty ? '* ' : ''}${widget.name}'),
          actions: <Widget>[
            IconButton(
              tooltip: context.l10n.save,
              onPressed: _dirty && !_saving ? _save : null,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(context.l10n.cannotOpen(_error!)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: Text(context.l10n.retry)),
          ],
        ),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: scheme.surfaceContainerHighest,
          child: Text(
            widget.path,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.code.copyWith(color: scheme.outline),
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                width: 54,
                color: scheme.surfaceContainerLow,
                child: SingleChildScrollView(
                  controller: _lineScroll,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    List<String>.generate(
                      _lineCount,
                      (index) => '${index + 1}',
                    ).join('\n'),
                    textAlign: TextAlign.right,
                    style: AppTheme.code.copyWith(color: scheme.outline),
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: TextField(
                  controller: _text,
                  scrollController: _editorScroll,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top,
                  style: AppTheme.code,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _ConflictDecision { cancel, reload, overwrite }

int _countLines(String text) =>
    text.isEmpty ? 1 : '\n'.allMatches(text).length + 1;
