/// The Agent chat screen (design doc §20).
///
/// Composes the transcript, the live Agent Activity panel, the approval prompt
/// and the input bar. It is a thin view over [SessionController]: it renders
/// [ChatState] and forwards user intents (send / approve / cancel / new session).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/session_controller.dart';
import '../../core/approval/approval_manager.dart';
import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../workspace/workspace_sheet.dart';
import 'widgets/activity_panel.dart';
import 'widgets/approval_card.dart';
import 'widgets/message_views.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    ref.read(sessionControllerProvider.notifier).send(text);
  }

  @override
  Widget build(BuildContext context) {
    // Reset the transcript whenever the user switches workspace.
    ref.listen<String?>(activeWorkspaceProvider, (
      String? previous,
      String? next,
    ) {
      if (previous != next) {
        ref.read(sessionControllerProvider.notifier).startNewSession();
      }
    });

    final chat = ref.watch(sessionControllerProvider);
    final workspace = ref.watch(currentWorkspaceProvider);

    // Keep the newest message in view.
    ref.listen(sessionControllerProvider, (ChatState? _, ChatState next) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });

    return Scaffold(
      appBar: AppBar(
        title: const WorkspacePickerButton(),
        actions: <Widget>[
          _ModelChip(),
          IconButton(
            tooltip: context.l10n.sessions,
            icon: const Icon(Icons.history),
            onPressed: workspace == null
                ? null
                : () => _openSessions(context, workspace.id),
          ),
          IconButton(
            tooltip: context.l10n.newSession,
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: workspace == null
                ? null
                : () => ref
                      .read(sessionControllerProvider.notifier)
                      .startNewSession(),
          ),
        ],
      ),
      body: workspace == null
          ? const _EmptyWorkspaceHint()
          : Column(
              children: <Widget>[
                Expanded(child: _Transcript(chat: chat)),
                if (chat.error != null) _ErrorBanner(message: chat.error!),
                if (chat.activity.isNotEmpty || chat.isRunning)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ActivityPanel(
                      items: chat.activity,
                      phase: chat.phase,
                    ),
                  ),
                if (chat.hasPendingApproval)
                  ApprovalCard(
                    request: chat.pendingApproval!,
                    onDecision: (ApprovalDecision d) => ref
                        .read(sessionControllerProvider.notifier)
                        .respondToApproval(d),
                  ),
                _InputBar(
                  controller: _input,
                  isRunning: chat.isRunning,
                  onSubmit: _submit,
                  onCancel: () =>
                      ref.read(sessionControllerProvider.notifier).cancel(),
                ),
              ],
            ),
    );
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(0.0); // reverse: true → offset 0 is the newest message.
  }

  Future<void> _openSessions(BuildContext context, String workspaceId) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) =>
          _SessionsSheet(workspaceId: workspaceId),
    );
  }
}

/// Full-screen prompt shown when no workspace is selected yet.
class _EmptyWorkspaceHint extends ConsumerWidget {
  const _EmptyWorkspaceHint();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.folder_off_outlined, size: 56, color: scheme.outline),
            const SizedBox(height: 16),
            Text(
              context.l10n.noWorkspaceSelected,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.workspaceRequiredDescription,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => showWorkspacePicker(context),
              icon: const Icon(Icons.folder_open),
              label: Text(context.l10n.selectOrCreateWorkspace),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelChip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(activeModelConfigProvider).value;
    if (config == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: '${config.label} · ${config.model}',
        child: Chip(
          visualDensity: VisualDensity.compact,
          avatar: Icon(
            config.provider == 'mock'
                ? Icons.science_outlined
                : Icons.cloud_outlined,
            size: 16,
            color: scheme.primary,
          ),
          label: Text(
            config.provider == 'mock' ? 'Demo' : config.model,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ),
    );
  }
}

class _Transcript extends StatelessWidget {
  const _Transcript({required this.chat});
  final ChatState chat;

  @override
  Widget build(BuildContext context) {
    if (chat.messages.isEmpty) {
      return const _Welcome();
    }
    final messages = chat.messages.reversed.toList(growable: false);
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: messages.length,
      itemBuilder: (BuildContext context, int i) =>
          MessageView(message: messages[i]),
    );
  }
}

class _Welcome extends ConsumerWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.smart_toy_outlined, size: 48, color: scheme.primary),
            const SizedBox(height: 12),
            Text(
              context.l10n.giveAgentTask,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.agentTaskDescription,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: 20),
            for (final example in <String>[
              context.l10n.exampleAnalyze,
              context.l10n.exampleConfiguration,
              context.l10n.examplePerformance,
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () => ref
                      .read(sessionControllerProvider.notifier)
                      .send(example),
                  child: Text(example, textAlign: TextAlign.center),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline, color: scheme.onErrorContainer, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.isRunning,
    required this.onSubmit,
    required this.onCancel,
  });

  final TextEditingController controller;
  final bool isRunning;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => isRunning ? null : onSubmit(),
                decoration: InputDecoration(
                  hintText: context.l10n.describeTask,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            isRunning
                ? IconButton.filledTonal(
                    tooltip: context.l10n.stop,
                    onPressed: onCancel,
                    icon: const Icon(Icons.stop_circle_outlined),
                  )
                : IconButton.filled(
                    tooltip: context.l10n.send,
                    onPressed: onSubmit,
                    icon: const Icon(Icons.send),
                  ),
          ],
        ),
      ),
    );
  }
}

class _SessionsSheet extends ConsumerWidget {
  const _SessionsSheet({required this.workspaceId});
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider(workspaceId));
    final activeId = ref.watch(activeSessionProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  context.l10n.sessions,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    ref
                        .read(sessionControllerProvider.notifier)
                        .startNewSession();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.newLabel),
                ),
              ],
            ),
            const SizedBox(height: 8),
            sessions.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (Object e, _) => Text(context.l10n.failedToLoad(e)),
              data: (List<Session> list) {
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(context.l10n.noSessions),
                  );
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: list.length,
                    itemBuilder: (BuildContext context, int i) {
                      final s = list[i];
                      return ListTile(
                        leading: Icon(
                          s.id == activeId
                              ? Icons.chat
                              : Icons.chat_bubble_outline,
                        ),
                        title: Text(
                          s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(_relative(context, s.updatedAt)),
                        onTap: () async {
                          await ref
                              .read(sessionControllerProvider.notifier)
                              .openSession(s);
                          if (context.mounted) Navigator.pop(context);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _relative(BuildContext context, DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return context.l10n.justNow;
    if (diff.inHours < 1) return context.l10n.minutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return context.l10n.hoursAgo(diff.inHours);
    return context.l10n.daysAgo(diff.inDays);
  }
}
