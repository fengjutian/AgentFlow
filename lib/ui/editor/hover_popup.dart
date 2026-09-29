/// Hover information popup for the code editor.
///
/// Displays type signatures, documentation, and other information from the
/// language server when the user hovers over a symbol. Positioned above or
/// below the hovered symbol.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// A tooltip that shows hover information from the language server.
///
/// Automatically dismisses after [autoDismissDuration] or when the user
/// taps outside. Tap on the tooltip pins it open.
class HoverPopup extends StatefulWidget {
  const HoverPopup({
    super.key,
    required this.content,
    required this.onDismiss,
    this.autoDismissDuration = const Duration(seconds: 8),
  });

  /// Markdown-formatted hover content (from LSP).
  final String content;

  /// Called when the popup should be dismissed.
  final VoidCallback onDismiss;

  /// How long to show the popup before auto-dismissing.
  final Duration autoDismissDuration;

  @override
  State<HoverPopup> createState() => _HoverPopupState();
}

class _HoverPopupState extends State<HoverPopup> {
  Timer? _dismissTimer;
  bool _pinned = false;

  @override
  void initState() {
    super.initState();
    _startDismissTimer();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _startDismissTimer() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(widget.autoDismissDuration, () {
      if (!_pinned && mounted) {
        widget.onDismiss();
      }
    });
  }

  void _togglePin() {
    setState(() {
      _pinned = !_pinned;
      if (!_pinned) {
        _startDismissTimer();
      } else {
        _dismissTimer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      color: theme.colorScheme.surfaceContainerHigh,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 480,
          maxHeight: 280,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header bar with pin/close.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 16,
                    tooltip: _pinned ? 'Unpin' : 'Pin',
                    onPressed: _togglePin,
                    icon: Icon(
                      _pinned
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                      size: 14,
                      color: _pinned
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 16,
                    tooltip: 'Close',
                    onPressed: widget.onDismiss,
                    icon: Icon(
                      Icons.close,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Content.
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(10),
                child: SelectableText(
                  widget.content,
                  style: AppTheme.code.copyWith(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
