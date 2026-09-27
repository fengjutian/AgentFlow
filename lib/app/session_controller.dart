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
  });

  final String? sessionId;
  final List<TranscriptMessage> messages;
  final List<ActivityItem> activity;
  final AgentPhase phase;
  final bool isRunning;
  final ApprovalRequest? pendingApproval;
  final String? error;

  bool get hasPendingApproval => pendingApproval != null;

  ChatState copyWith({
    String? sessionId,
    List<TranscriptMessage>? messages,
    List<ActivityItem>? activity,
    AgentPhase? phase,
    bool? isRunning,
    String? error,
  }) => ChatState(
    sessionId: sessionId ?? this.sessionId,
    messages: messages ?? this.messages,
    activity: activity ?? this.activity,
    phase: phase ?? this.phase,
    isRunning: isRunning ?? this.isRunning,
    pendingApproval: pendingApproval,
    error: error ?? this.error,
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
  );

  ChatState withError(String? message) => ChatState(
    sessionId: sessionId,
    messages: messages,
    activity: activity,
    phase: message == null ? phase : AgentPhase.error,
    isRunning: isRunning,
    pendingApproval: pendingApproval,
    error: message,
  );
}

class SessionController extends Notifier<ChatState> {
  AgentRun? _run;
  StreamSubscription<ApprovalRequest?>? _approvalSub;

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
    final messages = await _sessions.loadMessages(session.id);
    ref.read(activeSessionProvider.notifier).select(session.id);
    state = ChatState(sessionId: session.id, messages: messages);
  }

  /// Clears the view for a brand-new session in [workspaceId].
  void startNewSession() {
    _run?.cancel();
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
        workspace: WorkspaceContext(
          workspaceName: workspace.name,
          rootDirectory: workspace.rootDirectory,
          runtimeLabel: runtime.label,
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
      state = state.copyWith(isRunning: false);
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
      case AssistantMessageEvent(:final message):
        await _append(sessionId, TranscriptMessage.fromChat(message));
      case ToolFinishedEvent(:final result):
        await _append(sessionId, TranscriptMessage.fromToolResult(result));
      case ActivityUpdatedEvent(:final item):
        _upsertActivity(item);
      case ErrorEvent(:final message):
        state = state.withError(message);
      case RunCompletedEvent():
        state = state.withError(null).copyWith(phase: AgentPhase.completed);
      case ToolStartedEvent():
        break; // Activity row already added via ActivityUpdatedEvent.
      case ApprovalRequiredEvent():
        break; // Surfaced through ApprovalManager.pendingChanges.
      case AssistantTextEvent():
        break; // Reserved for future token streaming.
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
}

final NotifierProvider<SessionController, ChatState> sessionControllerProvider =
    NotifierProvider<SessionController, ChatState>(SessionController.new);
