/// The Agent Core (design doc §7–§9).
///
/// [AgentEngine.runTurn] executes the observe → think → act → observe loop as an
/// event [Stream] rather than a blocking call. Every meaningful step is emitted
/// as an [AgentEvent]: phase changes, complete assistant turns, live Activity
/// rows, tool start/finish, approval requests and errors. This is what makes the
/// agent observable (design doc §3.2) and lets the exact same run feed the chat
/// transcript, the Activity panel, persistence and tests.
library;

import 'dart:async';

import '../../runtime/runtime.dart';
import '../../tools/agent_tool.dart';
import '../../tools/tool_registry.dart';
import '../approval/approval_manager.dart';
import '../context/context_manager.dart';
import '../message.dart';
import '../model/model_provider.dart';
import '../model/provider_factory.dart';
import 'agent_state.dart';

/// Everything needed to execute one user turn.
class AgentRunRequest {
  const AgentRunRequest({
    required this.userMessage,
    required this.workspace,
    required this.config,
    required this.runtime,
    this.history = const <ChatMessage>[],
    this.registry,
    this.workspaceId,
    this.sessionId,
    this.conversationSummary,
    this.maxIterations = 25,
  });

  final String userMessage;
  final List<ChatMessage> history;
  final WorkspaceContext workspace;
  final ModelConfig config;
  final Runtime runtime;
  final ToolRegistry? registry;
  final String? workspaceId;
  final String? sessionId;
  final String? conversationSummary;

  /// Hard stop on loop iterations so a confused model cannot spin forever.
  final int maxIterations;
}

/// A handle to an in-flight run: its [events], a [done] future and [cancel].
class AgentRun {
  AgentRun({
    required this.events,
    required this.done,
    required void Function() onCancel,
  }) : _cancel = onCancel;

  final Stream<AgentEvent> events;
  final Future<void> done;
  final void Function() _cancel;

  bool _cancelled = false;
  bool get isCancelled => _cancelled;

  /// Requests cancellation. The loop stops at the next safe checkpoint and any
  /// pending approval is auto-denied.
  void cancel() {
    _cancelled = true;
    _cancel();
  }
}

class AgentEngine {
  AgentEngine({
    required ModelProviderFactory providerFactory,
    required ApprovalManager approvalManager,
    required ToolRegistry defaultRegistry,
    ContextManager? contextManager,
  })  : _providerFactory = providerFactory,
        _approvalManager = approvalManager,
        _defaultRegistry = defaultRegistry,
        _contextManager = contextManager ?? ContextManager();

  final ModelProviderFactory _providerFactory;
  final ApprovalManager _approvalManager;
  final ToolRegistry _defaultRegistry;
  final ContextManager _contextManager;

  /// Starts a run and returns immediately with an [AgentRun] handle.
  AgentRun runTurn(AgentRunRequest request) {
    final controller = StreamController<AgentEvent>();
    final done = Completer<void>();
    var cancelled = false;

    void cancel() {
      cancelled = true;
      // Unblock a waiting approval so the loop can unwind.
      _approvalManager.resolve(ApprovalDecision.deny);
    }

    unawaited(_loop(request, controller, () => cancelled).whenComplete(() {
      if (!done.isCompleted) done.complete();
      if (!controller.isClosed) controller.close();
    }));

    return AgentRun(events: controller.stream, done: done.future, onCancel: cancel);
  }

  Future<void> _loop(
    AgentRunRequest request,
    StreamController<AgentEvent> sink,
    bool Function() isCancelled,
  ) async {
    final registry = request.registry ?? _defaultRegistry;
    final provider = _providerFactory.providerFor(request.config);
    final toolContext = ToolContext(
      runtime: request.runtime,
      workingDirectory: request.workspace.rootDirectory,
      workspaceId: request.workspaceId,
      sessionId: request.sessionId,
    );

    final messages = <ChatMessage>[
      ...request.history,
      ChatMessage.user(request.userMessage),
    ];

    var phase = AgentPhase.idle;
    void setPhase(AgentPhase next) {
      if (next != phase) {
        phase = next;
        sink.add(PhaseChangedEvent(next));
      }
    }

    var toolCallCount = 0;
    var conversationSummary = request.conversationSummary;

    try {
      for (var iteration = 0;
          iteration < request.maxIterations;
          iteration++) {
        if (isCancelled()) {
          setPhase(AgentPhase.cancelled);
          return;
        }

        setPhase(AgentPhase.thinking);
        final buildResult = _contextManager.build(
          workspace: request.workspace,
          history: messages,
          registry: registry,
          config: request.config,
          conversationSummary: conversationSummary,
        );
        // Carry the structural summary forward so subsequent iterations and
        // future turns preserve awareness of trimmed context.
        if (buildResult.droppedSummary != null) {
          conversationSummary = buildResult.droppedSummary;
          sink.add(SummaryUpdatedEvent(conversationSummary!));
        }

        final ModelResponse response;
        try {
          response = await provider.generate(buildResult.request);
        } on ModelException catch (e) {
          sink.add(ErrorEvent(e.message));
          setPhase(AgentPhase.error);
          return;
        }

        final assistant = ChatMessage(
          role: MessageRole.assistant,
          content: response.content,
          toolCalls: response.toolCalls,
        );
        messages.add(assistant);
        sink.add(AssistantMessageEvent(assistant));

        if (!response.hasToolCalls) {
          setPhase(AgentPhase.completed);
          sink.add(RunCompletedEvent(
            finalText: response.content,
            toolCallCount: toolCallCount,
          ));
          return;
        }

        // Surface the planning phase so the Activity UI shows the agent
        // deliberating on what to do next (design doc §9).
        setPhase(AgentPhase.planning);

        for (final call in response.toolCalls) {
          if (isCancelled()) break;
          toolCallCount++;
          final result = await _executeToolCall(
            call: call,
            registry: registry,
            toolContext: toolContext,
            sink: sink,
            setPhase: setPhase,
            isCancelled: isCancelled,
            runtimeLabel: request.runtime.label,
          );
          messages.add(ChatMessage.fromToolResult(result));
          setPhase(AgentPhase.observing);
        }
      }

      sink.add(ErrorEvent(
        'Stopped after ${request.maxIterations} iterations without a final '
        'answer. Try breaking the task into smaller steps.',
      ));
      setPhase(AgentPhase.error);
    } catch (e, st) {
      sink.add(ErrorEvent('Agent error: $e', stackTrace: st.toString()));
      setPhase(AgentPhase.error);
    }
  }

  Future<ToolResult> _executeToolCall({
    required ToolCall call,
    required ToolRegistry registry,
    required ToolContext toolContext,
    required StreamController<AgentEvent> sink,
    required void Function(AgentPhase) setPhase,
    required bool Function() isCancelled,
    String? runtimeLabel,
  }) async {
    final tool = registry.lookup(call.name);
    final label = tool?.describeCall(call.arguments) ?? call.name;
    final base = ActivityItem(
      id: call.id.isEmpty ? call.name : call.id,
      label: label,
      status: ActivityStatus.running,
      toolCallId: call.id,
    );
    sink.add(ActivityUpdatedEvent(base));
    sink.add(ToolStartedEvent(
      toolCallId: call.id,
      toolName: call.name,
      label: label,
    ));

    ToolResult result;
    ActivityStatus status;
    String? detail;

    if (tool == null) {
      result = ToolResult(
        toolCallId: call.id,
        name: call.name,
        content: 'Unknown or disabled tool "${call.name}". Available tools: '
            '${registry.names.join(', ')}.',
        isError: true,
      );
      status = ActivityStatus.error;
      detail = 'unknown tool';
    } else {
      ToolPreview? preview;
      if (tool is PreviewableTool) {
        try {
          preview = await tool.preview(call.arguments, toolContext);
        } on ToolExecutionException catch (e) {
          result = ToolResult(
            toolCallId: call.id,
            name: tool.name,
            content: e.message,
            isError: true,
          );
          sink.add(ActivityUpdatedEvent(
            base.copyWith(status: ActivityStatus.error, detail: e.message),
          ));
          sink.add(ToolFinishedEvent(
            toolCallId: call.id,
            toolName: call.name,
            result: result,
          ));
          return result;
        }
      }
      // Approval gate for anything above read-only risk (design doc §3.3).
      if (tool.risk != ToolRisk.auto) {
        setPhase(AgentPhase.waitingApproval);
        final decision = await _approvalManager.request(
          toolName: tool.name,
          risk: tool.risk,
          summary: label,
          arguments: call.arguments,
          previewData: preview?.data,
          runtimeLabel: runtimeLabel,
        );
        if (decision == ApprovalDecision.deny) {
          result = ToolResult(
            toolCallId: call.id,
            name: tool.name,
            content: 'Denied by user. The user rejected this ${tool.name} call. '
                'Do not retry the same call; ask what they would prefer or take '
                'a different, less risky approach.',
            isError: true,
            data: <String, dynamic>{'denied': true},
          );
          sink.add(ActivityUpdatedEvent(
            base.copyWith(status: ActivityStatus.skipped, detail: 'denied'),
          ));
          sink.add(ToolFinishedEvent(
            toolCallId: call.id,
            toolName: call.name,
            result: result,
          ));
          return result;
        }
      }

      if (isCancelled()) {
        result = ToolResult(
          toolCallId: call.id,
          name: call.name,
          content: 'Cancelled before execution.',
          isError: true,
        );
        status = ActivityStatus.skipped;
        detail = 'cancelled';
      } else {
        setPhase(AgentPhase.executing);
        try {
          final executed = tool is PreviewableTool && preview != null
              ? await tool.executePrepared(call.arguments, toolContext, preview)
              : await tool.execute(call.arguments, toolContext);
          result = executed.copyWith(toolCallId: call.id, name: tool.name);
          status = result.isError ? ActivityStatus.error : ActivityStatus.done;
          detail = _firstLine(result.content);
        } on ToolExecutionException catch (e) {
          result = ToolResult(
            toolCallId: call.id,
            name: tool.name,
            content: e.message,
            isError: true,
          );
          status = ActivityStatus.error;
          detail = e.message;
        } catch (e, st) {
          result = ToolResult(
            toolCallId: call.id,
            name: tool.name,
            content: 'Tool threw an unexpected error: $e',
            isError: true,
          );
          status = ActivityStatus.error;
          detail = e.toString();
          sink.add(ErrorEvent('Tool ${call.name} failed: $e',
              stackTrace: st.toString()));
        }
      }
    }

    sink.add(ActivityUpdatedEvent(base.copyWith(status: status, detail: detail)));
    sink.add(ToolFinishedEvent(
      toolCallId: call.id,
      toolName: call.name,
      result: result,
    ));
    return result;
  }

  String _firstLine(String text) {
    final line = text.split('\n').firstWhere(
          (l) => l.trim().isNotEmpty,
          orElse: () => '',
        );
    return line.length > 120 ? '${line.substring(0, 120)}…' : line;
  }
}
