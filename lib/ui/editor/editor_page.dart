library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/editor/editor_document.dart';
import '../../core/editor/editor_search.dart';
import '../../core/editor/syntax_highlighter.dart';
import '../../l10n/l10n.dart';

/// Maximum file size that can be opened in the editor (1 MB).
const int _maxEditorFileSize = 1024 * 1024;

/// Formats a byte count as a human-readable string.
String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class EditorPage extends ConsumerStatefulWidget {
  const EditorPage({
    super.key,
    required this.path,
    required this.name,
    this.initialLine = 1,
    this.initialColumn = 1,
    this.embedded = false,
  });

  final String path;
  final String name;
  final int initialLine;
  final int initialColumn;
  final bool embedded;

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage>
    with WidgetsBindingObserver {
  late final SyntaxTextEditingController _text;
  final TextEditingController _search = TextEditingController();
  final TextEditingController _replacement = TextEditingController();
  final ScrollController _editorScroll = ScrollController();
  final ScrollController _lineScroll = ScrollController();
  final FocusNode _editorFocus = FocusNode();
  final FocusNode _searchFocus = FocusNode();
  final UndoHistoryController _undoHistory = UndoHistoryController();
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
    WidgetsBinding.instance.addObserver(this);
    _text = SyntaxTextEditingController(
      language: detectLanguage(widget.path),
    );
    _text.addListener(_onTextChanged);
    _search.addListener(_refreshMatches);
    _editorScroll.addListener(_syncLineScroll);
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _text.colors = isDark ? SyntaxColors.dark : SyntaxColors.light;
    _text.baseStyle = AppTheme.code;
  }

  @override
  void didUpdateWidget(covariant EditorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLine != widget.initialLine ||
        oldWidget.initialColumn != widget.initialColumn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_loading) _applyInitialLocation();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _dirty) {
      _saveDraft();
    }
  }

  @override
  void dispose() {
    if (_dirty) unawaited(_saveDraft(_text.text));
    WidgetsBinding.instance.removeObserver(this);
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
    _undoHistory.dispose();
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

      // Check file size before loading to avoid memory issues.
      final parent = p.dirname(widget.path);
      final fileName = p.basename(widget.path);
      final entries = await runtime.listFiles(parent);
      final entry = entries.where((e) => e.name == fileName).firstOrNull;
      if (entry != null && entry.size > _maxEditorFileSize) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = context.l10n.fileTooLarge(
            _formatBytes(entry.size),
            _formatBytes(_maxEditorFileSize),
          );
        });
        return;
      }

      final document = EditorDocument(path: widget.path, runtime: runtime);
      final content = await document.load();
      if (!mounted) return;

      // Check for binary content (null bytes or UTF-8 replacement chars).
      if (_isBinaryContent(content)) {
        setState(() {
          _loading = false;
          _error = context.l10n.binaryFileNotSupported;
        });
        return;
      }

      _document = document;

      // Check for a saved draft that is newer than the disk version.
      final draft = await _loadDraft();
      final effectiveText =
          (draft != null && draft != content) ? draft : content;

      _text.value = TextEditingValue(
        text: effectiveText,
        selection: TextSelection.collapsed(offset: effectiveText.length),
      );
      if (effectiveText != content) document.update(effectiveText);

      setState(() {
        _lineCount = _countLines(effectiveText);
        _loading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _applyInitialLocation();
      });

      // If a draft was restored, show a banner offering to discard it.
      if (effectiveText != content && mounted) {
        _showDraftRestoredBanner();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  void _applyInitialLocation() {
    final lineOffset = offsetForEditorLine(_text.text, widget.initialLine);
    if (lineOffset == null) return;
    final lineEnd = _text.text.indexOf('\n', lineOffset);
    final maxOffset = lineEnd < 0 ? _text.text.length : lineEnd;
    final offset = (lineOffset + widget.initialColumn - 1)
        .clamp(lineOffset, maxOffset)
        .toInt();
    _text.selection = TextSelection.collapsed(offset: offset);
    _editorFocus.requestFocus();
  }

  /// Returns true if the content appears to be binary.
  /// Checks for null bytes and Unicode replacement characters.
  bool _isBinaryContent(String content) {
    // Check first 8KB for binary indicators.
    const sampleSize = 8192;
    final sample = content.length > sampleSize
        ? content.substring(0, sampleSize)
        : content;
    // Null byte is a strong binary indicator.
    if (sample.contains('\x00')) return true;
    // U+FFFD (Unicode replacement character) indicates invalid UTF-8 decoding.
    if (sample.contains('\uFFFD')) return true;
    return false;
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

  // -- Draft persistence --------------------------------------------------

  Future<io.File> _draftFile() async {
    final dir = await getApplicationSupportDirectory();
    final draftsDir = io.Directory('${dir.path}/editor_drafts');
    if (!await draftsDir.exists()) {
      await draftsDir.create(recursive: true);
    }
    // Use a URL-safe hash of the path as the filename.
    final hash = base64Url.encode(utf8.encode(widget.path)).replaceAll('=', '');
    return io.File('${draftsDir.path}/$hash.txt');
  }

  Future<void> _saveDraft([String? draft]) async {
    final content = draft ?? _text.text;
    try {
      final file = await _draftFile();
      await file.writeAsString(content);
    } catch (_) {
      // Draft save is best-effort; never block the UI or surface errors.
    }
  }

  Future<String?> _loadDraft() async {
    try {
      final file = await _draftFile();
      if (await file.exists()) return await file.readAsString();
    } catch (_) {
      // Ignore draft read failures.
    }
    return null;
  }

  Future<void> _clearDraft() async {
    try {
      final file = await _draftFile();
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Ignore.
    }
  }

  void _showDraftRestoredBanner() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(context.l10n.draftRestored),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: context.l10n.discard,
          onPressed: () async {
            messenger.hideCurrentSnackBar();
            final content = _document != null
                ? await _document!.reload()
                : '';
            if (!mounted) return;
            _text.value = TextEditingValue(
              text: content,
              selection: TextSelection.collapsed(offset: content.length),
            );
            setState(() => _lineCount = _countLines(content));
            await _clearDraft();
          },
        ),
      ),
    );
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
        // Both 'saved' and 'verifiedWithChanges' mean the write succeeded.
        _showMessage(context.l10n.fileSaved);
        // Saved successfully — discard any lingering draft.
        await _clearDraft();
        // If verifiedWithChanges, reload the editor to show the current disk state.
        if (result == EditorSaveResult.verifiedWithChanges) {
          final content = document.text;
          _text.value = TextEditingValue(
            text: content,
            selection: TextSelection.collapsed(offset: content.length),
          );
          setState(() => _lineCount = _countLines(content));
        }
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
    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text('${_dirty ? '* ' : ''}${widget.name}'),
        actions: <Widget>[
          IconButton(
            tooltip: context.l10n.undo,
            onPressed: _loading || _error != null || !_undoHistory.value.canUndo
                ? null
                : () => _undoHistory.undo(),
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: context.l10n.redo,
            onPressed: _loading || _error != null || !_undoHistory.value.canRedo
                ? null
                : () => _undoHistory.redo(),
            icon: const Icon(Icons.redo),
          ),
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
    );
    if (widget.embedded) return scaffold;
    return PopScope<Object?>(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await _confirmDiscard();
        if (!context.mounted || !discard) return;
        Navigator.of(context).pop();
      },
      child: scaffold,
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
                  undoController: _undoHistory,
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
