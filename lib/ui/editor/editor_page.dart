library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/editor/editor_document.dart';
import '../../core/editor/editor_search.dart';
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
  final TextEditingController _search = TextEditingController();
  final TextEditingController _replacement = TextEditingController();
  final ScrollController _editorScroll = ScrollController();
  final ScrollController _lineScroll = ScrollController();
  final FocusNode _editorFocus = FocusNode();
  final FocusNode _searchFocus = FocusNode();
  EditorDocument? _document;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  int _lineCount = 1;
  bool _syncingScroll = false;
  bool _showSearch = false;
  bool _showReplace = false;
  List<EditorMatch> _matches = const <EditorMatch>[];
  int _matchIndex = -1;

  bool get _dirty => _document?.isDirty ?? false;

  @override
  void initState() {
    super.initState();
    _text.addListener(_onTextChanged);
    _search.addListener(_refreshMatches);
    _editorScroll.addListener(_syncLineScroll);
    _load();
  }

  @override
  void dispose() {
    _text
      ..removeListener(_onTextChanged)
      ..dispose();
    _search
      ..removeListener(_refreshMatches)
      ..dispose();
    _replacement.dispose();
    _editorScroll.dispose();
    _lineScroll.dispose();
    _editorFocus.dispose();
    _searchFocus.dispose();
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
    if (mounted) {
      setState(() => _lineCount = lineCount);
      if (_showSearch) _refreshMatches(selectNearest: false);
    }
  }

  void _openSearch() {
    setState(() => _showSearch = true);
    _refreshMatches();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    setState(() {
      _showSearch = false;
      _showReplace = false;
      _matches = const <EditorMatch>[];
      _matchIndex = -1;
    });
    _editorFocus.requestFocus();
  }

  void _refreshMatches({bool selectNearest = true}) {
    final matches = findEditorMatches(_text.text, _search.text);
    var index = _matchIndex;
    if (matches.isEmpty) {
      index = -1;
    } else if (selectNearest || index < 0 || index >= matches.length) {
      index = nextEditorMatchIndex(matches, _text.selection.extentOffset);
    }
    if (!mounted) return;
    setState(() {
      _matches = matches;
      _matchIndex = index;
    });
    if (selectNearest && index >= 0) _selectMatch(index);
  }

  void _moveMatch({required bool backwards}) {
    if (_matches.isEmpty) return;
    final delta = backwards ? -1 : 1;
    final index = (_matchIndex + delta) % _matches.length;
    _selectMatch(index);
  }

  void _selectMatch(int index) {
    if (index < 0 || index >= _matches.length) return;
    final match = _matches[index];
    setState(() => _matchIndex = index);
    _text.selection = TextSelection(
      baseOffset: match.start,
      extentOffset: match.end,
    );
    _editorFocus.requestFocus();
  }

  void _replaceCurrent() {
    if (_matchIndex < 0 || _matchIndex >= _matches.length) return;
    final match = _matches[_matchIndex];
    final value = _text.value;
    final updated = value.text.replaceRange(
      match.start,
      match.end,
      _replacement.text,
    );
    _text.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(
        offset: match.start + _replacement.text.length,
      ),
    );
    _refreshMatches();
  }

  void _replaceAll() {
    final count = _matches.length;
    if (count == 0) return;
    final updated = replaceAllEditorMatches(
      _text.text,
      _search.text,
      _replacement.text,
    );
    _text.value = TextEditingValue(
      text: updated,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _refreshMatches();
    _showMessage(context.l10n.replacedOccurrences(count));
  }

  Future<void> _goToLine() async {
    final controller = TextEditingController();
    final line = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.goToLine),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.l10n.lineNumber,
            helperText: context.l10n.lineRange(_lineCount),
          ),
          onSubmitted: (value) => Navigator.pop(context, int.tryParse(value)),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text)),
            child: Text(context.l10n.go),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || line == null) return;
    final offset = offsetForEditorLine(_text.text, line);
    if (offset == null) {
      _showMessage(context.l10n.invalidLineNumber);
      return;
    }
    _text.selection = TextSelection.collapsed(offset: offset);
    _editorFocus.requestFocus();
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
              tooltip: context.l10n.search,
              onPressed: _loading || _error != null ? null : _openSearch,
              icon: const Icon(Icons.search),
            ),
            IconButton(
              tooltip: context.l10n.goToLine,
              onPressed: _loading || _error != null ? null : _goToLine,
              icon: const Icon(Icons.format_list_numbered),
            ),
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
        if (_showSearch) _buildSearchPanel(scheme),
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
                  focusNode: _editorFocus,
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

  Widget _buildSearchPanel(ColorScheme scheme) {
    final matchLabel = _matches.isEmpty
        ? context.l10n.noMatches
        : context.l10n.matchPosition(_matchIndex + 1, _matches.length);
    return Material(
      color: scheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(
                  tooltip: context.l10n.replace,
                  onPressed: () => setState(() => _showReplace = !_showReplace),
                  icon: Icon(
                    _showReplace
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _search,
                    focusNode: _searchFocus,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: context.l10n.search,
                      border: const OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _moveMatch(backwards: false),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 58, child: Text(matchLabel)),
                IconButton(
                  tooltip: context.l10n.previousMatch,
                  onPressed: _matches.isEmpty
                      ? null
                      : () => _moveMatch(backwards: true),
                  icon: const Icon(Icons.keyboard_arrow_up),
                ),
                IconButton(
                  tooltip: context.l10n.nextMatch,
                  onPressed: _matches.isEmpty
                      ? null
                      : () => _moveMatch(backwards: false),
                  icon: const Icon(Icons.keyboard_arrow_down),
                ),
                IconButton(
                  tooltip: context.l10n.close,
                  onPressed: _closeSearch,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (_showReplace) ...<Widget>[
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  const SizedBox(width: 48),
                  Expanded(
                    child: TextField(
                      controller: _replacement,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: context.l10n.replace,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.replace,
                    onPressed: _matches.isEmpty ? null : _replaceCurrent,
                    icon: const Icon(Icons.find_replace),
                  ),
                  IconButton(
                    tooltip: context.l10n.replaceAll,
                    onPressed: _matches.isEmpty ? null : _replaceAll,
                    icon: const Icon(Icons.playlist_add_check),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _ConflictDecision { cancel, reload, overwrite }

int _countLines(String text) =>
    text.isEmpty ? 1 : '\n'.allMatches(text).length + 1;
