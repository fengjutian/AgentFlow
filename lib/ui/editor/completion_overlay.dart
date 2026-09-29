/// IntelliSense-style code completion overlay for the editor.
///
/// Displays a filtered, navigable list of LSP completion items positioned
/// near the text cursor. Supports keyboard navigation (arrows, Tab/Enter
/// to accept, Esc to dismiss) and touch interaction.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/lsp/lsp_client.dart';
import '../../app/theme.dart';

/// A code completion popup overlay.
///
/// Typically rendered inside a [Stack] above the editor text field. The
/// overlay auto-filters items as the user types and fires [onAccept] with
/// the chosen completion's insert text.
class CompletionOverlay extends StatefulWidget {
  const CompletionOverlay({
    super.key,
    required this.items,
    required this.onAccept,
    required this.onDismiss,
    this.prefix = '',
    this.maxVisibleItems = 10,
  });

  /// Full list of completion items (from LSP response).
  final List<LspCompletionItem> items;

  /// Called when the user accepts a completion (with the insert text).
  final void Function(String insertText) onAccept;

  /// Called when the overlay is dismissed (Esc, click outside, etc.).
  final VoidCallback onDismiss;

  /// Characters typed after the trigger point — used to filter items.
  final String prefix;

  /// Maximum number of items visible at once.
  final int maxVisibleItems;

  @override
  State<CompletionOverlay> createState() => _CompletionOverlayState();
}

class _CompletionOverlayState extends State<CompletionOverlay> {
  late List<LspCompletionItem> _filtered;
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  static const double _itemHeight = 32.0;
  static const double _overlayWidth = 340.0;
  static const double _detailWidth = 260.0;

  @override
  void initState() {
    super.initState();
    _applyFilter(widget.prefix);
  }

  @override
  void didUpdateWidget(covariant CompletionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prefix != widget.prefix || oldWidget.items != widget.items) {
      _applyFilter(widget.prefix);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _applyFilter(String prefix) {
    if (prefix.isEmpty) {
      _filtered = widget.items;
    } else {
      final lower = prefix.toLowerCase();
      _filtered = widget.items.where((item) {
        final label = (item.filterText ?? item.label).toLowerCase();
        return label.contains(lower);
      }).toList();
      // Sort: exact prefix matches first, then fuzzy.
      _filtered.sort((a, b) {
        final aLabel = (a.sortText ?? a.label).toLowerCase();
        final bLabel = (b.sortText ?? b.label).toLowerCase();
        final aStarts = aLabel.startsWith(lower) ? 0 : 1;
        final bStarts = bLabel.startsWith(lower) ? 0 : 1;
        if (aStarts != bStarts) return aStarts.compareTo(bStarts);
        return aLabel.compareTo(bLabel);
      });
    }
    _selectedIndex = _filtered.isEmpty ? -1 : 0;
    _scrollToSelected();
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients || _selectedIndex < 0) return;
    final target = _selectedIndex * _itemHeight;
    final viewport = _scrollController.position.viewportDimension;
    final minScroll = _scrollController.position.minScrollExtent;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final desired = (target - viewport / 2).clamp(minScroll, maxScroll);
    _scrollController.animateTo(
      desired,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  }

  void _accept() {
    if (_selectedIndex < 0 || _selectedIndex >= _filtered.length) return;
    widget.onAccept(_filtered[_selectedIndex].effectiveInsertText);
  }

  void _moveSelection(int delta) {
    if (_filtered.isEmpty) return;
    setState(() {
      _selectedIndex = (_selectedIndex + delta)
          .clamp(0, _filtered.length - 1);
    });
    _scrollToSelected();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        _moveSelection(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _moveSelection(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.tab:
      case LogicalKeyboardKey.enter:
        _accept();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        widget.onDismiss();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_filtered.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onDismiss();
      });
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final visibleCount =
        _filtered.length.clamp(1, widget.maxVisibleItems);
    final listHeight = visibleCount * _itemHeight;
    final selectedItem =
        _selectedIndex >= 0 && _selectedIndex < _filtered.length
            ? _filtered[_selectedIndex]
            : null;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(6),
        color: theme.colorScheme.surfaceContainerHigh,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Completion list.
            SizedBox(
              width: _overlayWidth,
              height: listHeight,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _filtered.length,
                itemExtent: _itemHeight,
                itemBuilder: (context, index) => _CompletionItemTile(
                  item: _filtered[index],
                  isSelected: index == _selectedIndex,
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    _accept();
                  },
                ),
              ),
            ),
            // Detail panel.
            if (selectedItem?.detail != null ||
                selectedItem?.documentation != null)
              Container(
                width: _detailWidth,
                height: listHeight,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: theme.dividerColor),
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selectedItem!.detail != null)
                        Text(
                          selectedItem.detail!,
                          style: AppTheme.code.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontSize: 11,
                          ),
                        ),
                      if (selectedItem.detail != null &&
                          selectedItem.documentation != null)
                        const SizedBox(height: 6),
                      if (selectedItem.documentation != null)
                        Text(
                          selectedItem.documentation!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 8,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A single row in the completion list.
class _CompletionItemTile extends StatelessWidget {
  const _CompletionItemTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final LspCompletionItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : Colors.transparent,
        child: Row(
          children: [
            _CompletionKindIcon(kind: item.kind),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                item.label,
                style: AppTheme.code.copyWith(
                  fontSize: 12,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (item.detail != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  item.detail!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Maps LSP completion kinds to Material icons.
class _CompletionKindIcon extends StatelessWidget {
  const _CompletionKindIcon({required this.kind});
  final LspCompletionKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = switch (kind) {
      LspCompletionKind.method ||
      LspCompletionKind.function_ ||
      LspCompletionKind.constructor_ =>
        (Icons.functions, Colors.purple),
      LspCompletionKind.field ||
      LspCompletionKind.property =>
        (Icons.crop_square, Colors.teal),
      LspCompletionKind.variable => (Icons.code, Colors.blue),
      LspCompletionKind.class_ ||
      LspCompletionKind.struct =>
        (Icons.class_, Colors.orange),
      LspCompletionKind.interface_ => (Icons.settings_input_component, Colors.orange),
      LspCompletionKind.module => (Icons.view_module, Colors.green),
      LspCompletionKind.enum_ ||
      LspCompletionKind.enumMember =>
        (Icons.list, Colors.brown),
      LspCompletionKind.keyword => (Icons.vpn_key, Colors.red.shade400),
      LspCompletionKind.snippet => (Icons.snippet_folder, Colors.indigo),
      LspCompletionKind.constant => (Icons.lock, Colors.grey),
      LspCompletionKind.file ||
      LspCompletionKind.folder =>
        (Icons.insert_drive_file, Colors.amber),
      LspCompletionKind.color => (Icons.palette, Colors.pink),
      LspCompletionKind.reference => (Icons.link, Colors.cyan),
      LspCompletionKind.operator_ => (Icons.settings, Colors.grey),
      LspCompletionKind.typeParameter => (Icons.type_specimen, Colors.indigo),
      _ => (Icons.text_fields, theme.colorScheme.onSurfaceVariant),
    };
    return Icon(icon, size: 14, color: color);
  }
}
