/// Agent state machine + event stream.
///
/// The loop is not a single "loading" spinner. It moves through explicit phases
/// (design doc §9) and emits a stream of [AgentEvent]s that the Activity panel
/// renders as a live checklist. Keeping these as data (not callbacks into UI)
/// means the same events feed the UI, the terminal panel, persistence and tests.
library;

import '../message.dart';
import '../approval/approval_manager.dart';

/// Coarse lifecycle phase of a single agent run.
enum AgentPhase {
  idle,
  thinking,
  planning,
  waitingApproval,
  executing,
  observing,
  recovering,
  completed,
  error,
  cancelled,
}

extension AgentPhaseX on AgentPhase {
  bool get isTerminal =>
      this == AgentPhase.completed ||
      this == AgentPhase.error ||
      this == AgentPhase.cancelled;

  String get label => switch (this) {
        AgentPhase.idle => 'Idle',
        AgentPhase.thinking => 'Thinking',
        AgentPhase.planning => 'Planning',
        AgentPhase.waitingApproval => 'Waiting for approval',
        AgentPhase.executing => 'Executing',
        AgentPhase.observing => 'Observing',
        AgentPhase.recovering => 'Recovering',
        AgentPhase.completed => 'Completed',
        AgentPhase.error => 'Error',
        AgentPhase.cancelled => 'Cancelled',
      };
}

/// Status of one line in the Activity checklist.
enum ActivityStatus { pending, running, done, error, skipped }

/// A single row in the Agent Activity feed, e.g. "✓ read_file pubspec.yaml".
class ActivityItem {
  ActivityItem({
    required this.id,
    required this.label,
    this.status = ActivityStatus.pending,
    this.detail,
    this.toolCallId,
  });

  final String id;
  final String label;
  ActivityStatus status;
  String? detail;

  /// Links the row to the tool invocation that produced it, when applicable.
  final String? toolCallId;

  ActivityItem copyWith({ActivityStatus? status, String? detail}) => ActivityItem(
        id: id,
        label: label,
        status: status ?? this.status,
        detail: detail ?? this.detail,
        toolCallId: toolCallId,
      );
}

/// Base type for everything the loop publishes.
sealed class AgentEvent {
  const AgentEvent();
}

class PhaseChangedEvent extends AgentEvent {
  const PhaseChangedEvent(this.phase);
  final AgentPhase phase;
}

/// The assistant produced (partial or full) natural-language text.
class AssistantTextEvent extends AgentEvent {
  const AssistantTextEvent(this.text, {this.isFinal = false});
  final String text;
  final bool isFinal;
}

/// A complete assistant turn (content and/or tool calls) ready to be appended to
/// the transcript and persisted.
class AssistantMessageEvent extends AgentEvent {
  const AssistantMessageEvent(this.message);
  final ChatMessage message;

  bool get hasToolCalls => message.hasToolCalls;
}

/// A new Activity row was added or updated.
class ActivityUpdatedEvent extends AgentEvent {
  const ActivityUpdatedEvent(this.item);
  final ActivityItem item;
}

class ToolStartedEvent extends AgentEvent {
  const ToolStartedEvent({
    required this.toolCallId,
    required this.toolName,
    required this.label,
  });
  final String toolCallId;
  final String toolName;
  final String label;
}

class ToolFinishedEvent extends AgentEvent {
  const ToolFinishedEvent({
    required this.toolCallId,
    required this.toolName,
    required this.result,
  });
  final String toolCallId;
  final String toolName;
  final ToolResult result;
}

class ApprovalRequiredEvent extends AgentEvent {
  const ApprovalRequiredEvent(this.request);
  final ApprovalRequest request;
}

class ErrorEvent extends AgentEvent {
  const ErrorEvent(this.message, {this.stackTrace});
  final String message;
  final String? stackTrace;
}

class RunCompletedEvent extends AgentEvent {
  const RunCompletedEvent({required this.finalText, required this.toolCallCount});
  final String finalText;
  final int toolCallCount;
}

/// Emitted when the context manager generates a structural summary of
/// messages trimmed to fit the budget. The controller threads this across
/// turns so the model retains awareness of earlier work.
class SummaryUpdatedEvent extends AgentEvent {
  const SummaryUpdatedEvent(this.summary);
  final String summary;
}
