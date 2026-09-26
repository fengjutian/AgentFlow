import 'package:agentflow/core/approval/approval_manager.dart';
import 'package:agentflow/tools/agent_tool.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('auto-risk tools are allowed without prompting', () async {
    final manager = ApprovalManager();
    addTearDown(manager.dispose);
    final decision = await manager.request(
      toolName: 'read_file',
      risk: ToolRisk.auto,
      summary: 'read_file pubspec.yaml',
    );
    expect(decision, ApprovalDecision.allow);
    expect(manager.hasPending, isFalse);
  });

  test('autoApprove bypasses confirmation for mutating tools', () async {
    final manager = ApprovalManager(autoApprove: true);
    addTearDown(manager.dispose);
    final decision = await manager.request(
      toolName: 'write_file',
      risk: ToolRisk.confirm,
      summary: 'write_file x.txt',
    );
    expect(decision, ApprovalDecision.allow);
  });

  test('a resolver can deny a confirm-risk call', () async {
    final manager = ApprovalManager(resolver: (ApprovalRequest r) => ApprovalDecision.deny);
    addTearDown(manager.dispose);
    final decision = await manager.request(
      toolName: 'run_shell',
      risk: ToolRisk.confirm,
      summary: 'run_shell rm -rf build',
    );
    expect(decision, ApprovalDecision.deny);
  });

  test('allowAlways remembers the tool for the session', () async {
    var prompts = 0;
    final manager = ApprovalManager(resolver: (ApprovalRequest r) {
      prompts++;
      return ApprovalDecision.allowAlways;
    });
    addTearDown(manager.dispose);

    await manager.request(
        toolName: 'run_shell', risk: ToolRisk.confirm, summary: 'first');
    final second = await manager.request(
        toolName: 'run_shell', risk: ToolRisk.confirm, summary: 'second');

    expect(second, ApprovalDecision.allow);
    expect(prompts, 1, reason: 'the second call should skip the resolver');
    expect(manager.alwaysAllowed, contains('run_shell'));
  });

  test('pending stream emits the request then clears on resolve', () async {
    final manager = ApprovalManager();
    addTearDown(manager.dispose);

    final events = <ApprovalRequest?>[];
    final sub = manager.pendingChanges.listen(events.add);
    addTearDown(sub.cancel);

    final future = manager.request(
      toolName: 'write_file',
      risk: ToolRisk.confirm,
      summary: 'write_file x.txt',
    );
    await Future<void>.delayed(Duration.zero);
    expect(manager.hasPending, isTrue);

    manager.resolve(ApprovalDecision.allow);
    expect(await future, ApprovalDecision.allow);

    await Future<void>.delayed(Duration.zero);
    expect(events.first, isNotNull);
    expect(events.last, isNull);
    expect(manager.hasPending, isFalse);
  });

  test('dispose() unblocks a waiting request with a deny', () async {
    final manager = ApprovalManager();
    final future = manager.request(
      toolName: 'write_file',
      risk: ToolRisk.strong,
      summary: 'write_file /etc/passwd',
    );
    await Future<void>.delayed(Duration.zero);
    await manager.dispose();
    expect(await future, ApprovalDecision.deny);
  });
}
