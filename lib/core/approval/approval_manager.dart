/// Approval gate for risky tool calls.
///
/// Read-only tools run automatically; mutating tools require a tap-to-confirm;
/// destructive tools require an explicit confirmation. The engine calls
/// [ApprovalManager.request] before executing anything above [ToolRisk.auto] and
/// blocks on the returned future until the UI (or an injected policy in tests)
/// resolves it.
library;

import 'dart:async';

import '../../tools/agent_tool.dart';

enum ApprovalDecision { allow, allowAlways, deny }

/// A pending confirmation surfaced to the UI.
class ApprovalRequest {
  const ApprovalRequest({
    required this.id,
    required this.toolName,
    required this.summary,
    required this.risk,
    required this.arguments,
    this.previewData,
    this.runtimeLabel,
  });

  final String id;
  final String toolName;
  final String summary;
  final ToolRisk risk;
  final Map<String, dynamic> arguments;
  final Map<String, dynamic>? previewData;

  /// Human label for the runtime context (e.g. `user@host` for SSH).
  /// When present, shown in the UI to clarify where the action runs.
  final String? runtimeLabel;

  bool get isStrong => risk == ToolRisk.strong;
}

/// Decides approvals without UI — used by tests and by a future "auto-approve
/// trusted tools" policy.
typedef ApprovalResolver = FutureOr<ApprovalDecision> Function(
  ApprovalRequest request,
);

class ApprovalManager {
  ApprovalManager({ApprovalResolver? resolver, bool autoApprove = false})
      : _resolver = resolver,
        _autoApprove = autoApprove;

  final StreamController<ApprovalRequest?> _controller =
      StreamController<ApprovalRequest?>.broadcast();

  ApprovalResolver? _resolver;
  bool _autoApprove;
  final Set<String> _alwaysAllowed = <String>{};

  ApprovalRequest? _pending;
  Completer<ApprovalDecision>? _completer;
  int _counter = 0;

  /// Emits the current pending request (or null). The UI watches this.
  Stream<ApprovalRequest?> get pendingChanges => _controller.stream;

  ApprovalRequest? get pending => _pending;

  bool get hasPending => _pending != null;

  set autoApprove(bool value) => _autoApprove = value;

  set resolver(ApprovalResolver? value) => _resolver = value;

  /// Requests approval for a tool call. Returns immediately for auto-risk tools
  /// or tools the user marked "always allow" this session.
  Future<ApprovalDecision> request({
    required String toolName,
    required ToolRisk risk,
    required String summary,
    Map<String, dynamic> arguments = const <String, dynamic>{},
    Map<String, dynamic>? previewData,
    String? runtimeLabel,
  }) async {
    if (risk == ToolRisk.auto || _autoApprove) {
      return ApprovalDecision.allow;
    }
    if (_alwaysAllowed.contains(toolName)) {
      return ApprovalDecision.allow;
    }

    final request = ApprovalRequest(
      id: '$toolName-${_counter++}',
      toolName: toolName,
      summary: summary,
      risk: risk,
      arguments: arguments,
      previewData: previewData,
      runtimeLabel: runtimeLabel,
    );

    final resolver = _resolver;
    if (resolver != null) {
      final decision = await resolver(request);
      _applyDecision(request, decision);
      return decision;
    }

    _pending = request;
    _completer = Completer<ApprovalDecision>();
    _emit(request);

    final decision = await _completer!.future;
    _applyDecision(request, decision);
    _pending = null;
    _completer = null;
    _emit(null);
    return decision;
  }

  /// Publishes to [pendingChanges] unless the controller was already closed
  /// (e.g. [dispose] unblocked a waiting request as it tore down).
  void _emit(ApprovalRequest? request) {
    if (!_controller.isClosed) _controller.add(request);
  }

  void _applyDecision(ApprovalRequest request, ApprovalDecision decision) {
    if (decision == ApprovalDecision.allowAlways) {
      _alwaysAllowed.add(request.toolName);
    }
  }

  /// Called by the UI when the user taps Allow / Deny.
  void resolve(ApprovalDecision decision) {
    final completer = _completer;
    if (completer != null && !completer.isCompleted) {
      completer.complete(decision);
    }
  }

  /// Revokes "always allow" for a tool (Settings → reset approvals).
  void revokeAlways(String toolName) => _alwaysAllowed.remove(toolName);

  void clearAlwaysAllowed() => _alwaysAllowed.clear();

  Set<String> get alwaysAllowed => Set<String>.unmodifiable(_alwaysAllowed);

  Future<void> dispose() async {
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(ApprovalDecision.deny);
    }
    await _controller.close();
  }
}
