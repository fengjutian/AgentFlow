import 'package:agentflow/core/agent/agent_state.dart';
import 'package:agentflow/core/approval/approval_manager.dart';
import 'package:agentflow/core/diff/line_diff.dart';
import 'package:agentflow/tools/agent_tool.dart';
import 'package:agentflow/ui/chat/widgets/activity_panel.dart';
import 'package:agentflow/ui/chat/widgets/approval_card.dart';
import 'package:agentflow/ui/chat/widgets/diff_card.dart';
import 'package:agentflow/ui/chat/widgets/terminal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  testWidgets('ActivityPanel renders the checklist labels and phase', (tester) async {
    await tester.pumpWidget(_wrap(ActivityPanel(
      items: <ActivityItem>[
        ActivityItem(
            id: '1',
            label: 'read_file pubspec.yaml',
            status: ActivityStatus.done),
        ActivityItem(
            id: '2', label: 'search_code TODO', status: ActivityStatus.running),
        ActivityItem(id: '3', label: 'run_shell flutter test', status: ActivityStatus.pending),
      ],
      phase: AgentPhase.executing,
    )));

    expect(find.text('Agent Activity'), findsOneWidget);
    expect(find.text('read_file pubspec.yaml'), findsOneWidget);
    expect(find.text('search_code TODO'), findsOneWidget);
    expect(find.text('run_shell flutter test'), findsOneWidget);
    expect(find.text('Executing'), findsOneWidget);
  });

  testWidgets('ActivityPanel with no items shows the phase-only hint', (tester) async {
    await tester.pumpWidget(_wrap(const ActivityPanel(
      items: <ActivityItem>[],
      phase: AgentPhase.thinking,
    )));
    expect(find.text('Agent Activity'), findsOneWidget);
    expect(find.text('Thinking…'), findsOneWidget);
  });

  testWidgets('ApprovalCard shows the summary and reports the decision', (tester) async {
    ApprovalDecision? chosen;
    await tester.pumpWidget(_wrap(ApprovalCard(
      request: const ApprovalRequest(
        id: 'a1',
        toolName: 'write_file',
        summary: 'write_file lib/main.dart',
        risk: ToolRisk.confirm,
        arguments: <String, dynamic>{},
      ),
      onDecision: (ApprovalDecision d) => chosen = d,
    )));

    expect(find.text('write_file lib/main.dart'), findsOneWidget);
    expect(find.text('Allow'), findsOneWidget);
    expect(find.text('Deny'), findsOneWidget);

    await tester.tap(find.text('Allow'));
    expect(chosen, ApprovalDecision.allow);
  });

  testWidgets('DiffCard shows the path and +/- counts', (tester) async {
    final FileDiff diff =
        buildFileDiff(path: 'a.dart', oldText: 'x\ny', newText: 'x\nz');
    await tester.pumpWidget(_wrap(DiffCard(diff: diff)));

    expect(find.text('a.dart'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    expect(find.text('\u22121'), findsOneWidget);
  });

  testWidgets('DiffCard.fromData builds from a write_file payload', (tester) async {
    final FileDiff diff =
        buildFileDiff(path: 'b.txt', oldText: '', newText: 'new');
    final DiffCard? card =
        DiffCard.fromData(<String, dynamic>{'diff': diff.toJson()});
    expect(card, isNotNull);
    expect(DiffCard.fromData(<String, dynamic>{}), isNull);
  });

  testWidgets('TerminalCard shows the command line and exit badge', (tester) async {
    await tester.pumpWidget(_wrap(const TerminalCard(
      command: 'echo hi',
      output: 'hi',
      exitCode: 0,
    )));

    expect(find.text('\$ echo hi'), findsOneWidget);
    expect(find.text('exit 0'), findsOneWidget);
    expect(find.text('hi'), findsOneWidget);
  });

  testWidgets('TerminalCard.fromData reads a run_shell payload', (tester) async {
    final TerminalCard? card = TerminalCard.fromData(<String, dynamic>{
      'command': 'git status',
      'stdout': 'clean',
      'stderr': '',
      'exitCode': 0,
    });
    expect(card, isNotNull);
    expect(card!.command, 'git status');
    expect(TerminalCard.fromData(<String, dynamic>{'foo': 'bar'}), isNull);
  });
}
