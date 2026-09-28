/// The chat/agent view-model (Riverpod [Notifier]).
///
/// Owns the transcript, the live Activity feed, the run phase and the pending
/// approval for the currently open session. It translates the engine's
/// [AgentEvent] stream into immutable [ChatState] snapshots and persists every
/// message, so reopening a session restores the full conversation with diffs and
/// terminal output intact.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/agent/agent_engine.dart';
import '../core/agent/agent_state.dart';
import '../core/approval/approval_manager.dart';
import '../core/context/context_manager.dart';
import '../core/message.dart';
import '../data/models.dart';
import '../runtime/runtime.dart';
import '../storage/repositories.dart';
import 'providers.dart';

/// Immutable snapshot of an open session.
class ChatState {
  const ChatState({
    this.sessionId,
    this.messages = const <TranscriptMessage>[],
    this.activity = const <ActivityItem>[],
    this.phase = AgentPhase.idle,
    this.isRunning = false,
    this.pendingApproval,
    this.error,
    this.streamingText,
  });

  final String? sessionId;
  final List<TranscriptMessage> messages;
  final List<ActivityItem> activity;
  final AgentPhase phase;
  final bool isRunning;
  final ApprovalRequest? pendingApproval;
  final String? error;

  /// In-progress assistant text being streamed token-by-token. Non-null while
  /// the model is actively generating; cleared once the complete message is
  /// persisted via [AssistantMessageEvent].
  final String? streamingText;

  bool get hasPendingApproval => pendingApproval != null;

  ChatState copyWith({
    String? sessionId,
    List<TranscriptMessage>? messages,
    List<ActivityItem>? activity,
    AgentPhase? phase,
    bool? isRunning,
    String? error,
    String? streamingText,
  }) => ChatState(
    sessionId: sessionId ?? this.sessionId,
    messages: messages ?? this.messages,
    activity: activity ?? this.activity,
    phase: phase ?? this.phase,
    isRunning: isRunning ?? this.isRunning,
    pendingApproval: pendingApproval,
    error: error ?? this.error,
    streamingText: streamingText ?? this.streamingText,
  );

  /// Sets/clears the pending approval (copyWith cannot express `null`).
  ChatState withPending(ApprovalRequest? request) => ChatState(
    sessionId: sessionId,
    messages: messages,
    activity: activity,
    phase: phase,
    isRunning: isRunning,
    pendingApproval: request,
    error: error,
    streamingText: streamingText,
  );

  ChatState withError(String? message) => ChatState(
    sessionId: sessionId,
    messages: messages,
    activity: activity,
    phase: message == null ? phase : AgentPhase.error,
    isRunning: isRunning,
    pendingApproval: pendingApproval,
    error: message,
    streamingText: streamingText,
  );

  /// Clears the in-progress streaming text (called when the complete message
  /// is persisted or when the run ends).
  ChatState clearStreaming() => ChatState(
    sessionId: sessionId,
    messages: messages,
    activity: activity,
    phase: phase,
    isRunning: isRunning,
    pendingApproval: pendingApproval,
    error: error,
  );
}

class SessionController extends Notifier<ChatState> {
  AgentRun? _run;
  StreamSubscription<ApprovalRequest?>? _approvalSub;

  /// Accumulated structural summary of trimmed conversation turns.
  /// Threaded across `send()` calls so the model retains awareness of
  /// earlier work that no longer fits the context window.
  String? _conversationSummary;

  @override
  ChatState build() {
    final approval = ref.watch(approvalManagerProvider);
    _approvalSub = approval.pendingChanges.listen(
      (ApprovalRequest? request) => state = state.withPending(request),
    );
    ref.onDispose(() {
      _approvalSub?.cancel();
      _run?.cancel();
    });
    return const ChatState();
  }

  SessionRepository get _sessions => ref.read(sessionRepositoryProvider);

  /// Loads an existing session's transcript (navigation from the session list).
  Future<void> openSession(Session session) async {
    _run?.cancel();
    _conversationSummary = null;
    final messages = await _sessions.loadMessages(session.id);
    ref.read(activeSessionProvider.notifier).select(session.id);
    state = ChatState(sessionId: session.id, messages: messages);
  }

  /// Clears the view for a brand-new session in [workspaceId].
  void startNewSession() {
    _run?.cancel();
    _conversationSummary = null;
    ref.read(activeSessionProvider.notifier).select(null);
    state = const ChatState();
  }

  /// Runs one user turn end-to-end.
  Future<void> send(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty || state.isRunning) return;

    final workspace = ref.read(currentWorkspaceProvider);
    if (workspace == null) {
      state = state.withError('Select or create a workspace before chatting.');
      return;
    }

    final session = await _ensureSession(workspace, prompt);
    final history = <ChatMessage>[
      for (final m in state.messages) m.toChatMessage(),
    ];

    final userMessage = TranscriptMessage(
      role: MessageRole.user,
      content: prompt,
      createdAt: DateTime.now(),
    );
    await _sessions.appendMessage(session.id, userMessage);

    state = ChatState(
      sessionId: session.id,
      messages: <TranscriptMessage>[...state.messages, userMessage],
      activity: const <ActivityItem>[],
      phase: AgentPhase.thinking,
      isRunning: true,
    );

    try {
      final runtime = await resolveRuntime(workspace);
      final config = await ref.read(activeModelConfigProvider.future);
      final memoryBlock = await ref
          .read(memoryManagerProvider)
          .renderContextBlock(workspace.id);
      final projectSummary = await _buildProjectSummary(runtime);
      final registry = registryForWorkspace(
        workspace,
        ref.read(toolRegistryProvider),
      );

      final approval = ref.read(approvalManagerProvider);
      approval.autoApprove = workspace.autoApprove;

      final request = AgentRunRequest(
        userMessage: prompt,
        history: history,
        config: config,
        runtime: runtime,
        registry: registry,
        workspaceId: workspace.id,
        sessionId: session.id,
        conversationSummary: _conversationSummary,
        workspace: WorkspaceContext(
          workspaceName: workspace.name,
          rootDirectory: workspace.rootDirectory,
          runtimeLabel: runtime.label,
          projectSummary: projectSummary,
          memoryBlock: memoryBlock,
        ),
      );

      final run = ref.read(agentEngineProvider).runTurn(request);
      _run = run;
      await for (final AgentEvent event in run.events) {
        await _applyEvent(event, session.id);
      }
      await run.done;
    } catch (e, st) {
      state = state.withError('Run failed: $e\n$st');
    } finally {
      _run = null;
      state = state.clearStreaming().copyWith(isRunning: false);
      await _sessions.touch(session.id, status: state.phase.name);
      ref.invalidate(sessionsProvider(workspace.id));
    }
  }

  /// Approves or denies the currently pending tool call.
  void respondToApproval(ApprovalDecision decision) {
    ref.read(approvalManagerProvider).resolve(decision);
  }

  /// Requests cancellation of the in-flight run.
  void cancel() => _run?.cancel();

  /// Deletes a session and clears the view if it was the active one.
  Future<void> deleteSession(Session session) async {
    if (_run != null && state.sessionId == session.id) {
      _run!.cancel();
    }
    await _sessions.delete(session.id);
    if (state.sessionId == session.id) {
      _conversationSummary = null;
      ref.read(activeSessionProvider.notifier).select(null);
      state = const ChatState();
    }
    ref.invalidate(sessionsProvider(session.workspaceId));
  }

  Future<Session> _ensureSession(Workspace workspace, String prompt) async {
    final existingId = state.sessionId;
    if (existingId != null) {
      final existing = await _sessions.byId(existingId);
      if (existing != null) return existing;
    }
    final now = DateTime.now();
    final session = Session(
      id: newId(),
      workspaceId: workspace.id,
      createdAt: now,
      updatedAt: now,
      title: _titleFrom(prompt),
    );
    await _sessions.upsert(session);
    ref.read(activeSessionProvider.notifier).select(session.id);
    return session;
  }

  Future<void> _applyEvent(AgentEvent event, String sessionId) async {
    switch (event) {
      case PhaseChangedEvent(:final phase):
        state = state.copyWith(phase: phase);
      case AssistantTextEvent(:final text):
        // Update the in-progress streaming text for real-time UI rendering.
        state = state.copyWith(streamingText: text);
      case AssistantMessageEvent(:final message):
        // The complete message is ready — persist it and clear streaming text.
        await _append(sessionId, TranscriptMessage.fromChat(message));
        state = state.clearStreaming();
      case ToolFinishedEvent(:final result):
        await _append(sessionId, TranscriptMessage.fromToolResult(result));
      case ActivityUpdatedEvent(:final item):
        _upsertActivity(item);
      case ErrorEvent(:final message):
        state = state.withError(message);
      case RunCompletedEvent():
        state = state.withError(null).copyWith(phase: AgentPhase.completed);
      case SummaryUpdatedEvent(:final summary):
        // Capture the structural summary so the next turn preserves it.
        _conversationSummary = summary;
      case ToolStartedEvent():
        break; // Activity row already added via ActivityUpdatedEvent.
      case ApprovalRequiredEvent():
        break; // Surfaced through ApprovalManager.pendingChanges.
    }
  }

  Future<void> _append(String sessionId, TranscriptMessage message) async {
    await _sessions.appendMessage(sessionId, message);
    state = state.copyWith(
      messages: <TranscriptMessage>[...state.messages, message],
    );
  }

  void _upsertActivity(ActivityItem item) {
    final list = <ActivityItem>[...state.activity];
    final index = list.indexWhere((ActivityItem a) => a.id == item.id);
    if (index >= 0) {
      list[index] = item;
    } else {
      list.add(item);
    }
    state = state.copyWith(activity: list);
  }

  String _titleFrom(String prompt) {
    final firstLine = prompt.split('\n').first.trim();
    if (firstLine.length <= 42) {
      return firstLine.isEmpty ? 'New session' : firstLine;
    }
    return '${firstLine.substring(0, 42)}…';
  }

  /// Builds a brief project summary from the workspace root for context
  /// injection. Reads key manifest files (README, package.json, pubspec,
  /// Cargo.toml, etc.) up to a total character budget.
  Future<String> _buildProjectSummary(Runtime runtime) async {
    const maxChars = 2000;
    const keyFiles = <String>[
      'README.md',
      'README',
      'pubspec.yaml',
      'package.json',
      'Cargo.toml',
      'go.mod',
      'pyproject.toml',
      'build.gradle',
      'build.gradle.kts',
      'pom.xml',
      'Makefile',
    ];

    final buffer = StringBuffer();
    try {
      final entries = await runtime.listFiles('.');
      final topLevel = entries
          .where((e) => !e.name.startsWith('.'))
          .map((e) => e.name)
          .take(40)
          .join(', ');
      if (topLevel.isNotEmpty) {
        buffer.writeln('Top-level: $topLevel');
      }
    } catch (_) {
      // listing may fail on some runtimes — that's fine
    }

    for (final name in keyFiles) {
      if (buffer.length >= maxChars) break;
      try {
        final content = await runtime.readFile(name);
        if (content.trim().isEmpty) continue;
        final remaining = maxChars - buffer.length;
        final excerpt = content.length > remaining
            ? '${content.substring(0, remaining)}…'
            : content;
        buffer.writeln('--- $name ---');
        buffer.writeln(excerpt.trim());
      } catch (_) {
        // file doesn't exist or can't be read — skip
      }
    }
    return buffer.toString().trim();
  }
}

final NotifierProvider<SessionController, ChatState> sessionControllerProvider =
    NotifierProvider<SessionController, ChatState>(SessionController.new);
