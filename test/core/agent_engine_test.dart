import 'dart:io';

import 'package:agentflow/core/agent/agent_engine.dart';
import 'package:agentflow/core/agent/agent_state.dart';
import 'package:agentflow/core/approval/approval_manager.dart';
import 'package:agentflow/core/context/context_manager.dart';
import 'package:agentflow/core/model/mock_provider.dart';
import 'package:agentflow/core/model/model_provider.dart';
import 'package:agentflow/core/model/provider_factory.dart';
import 'package:agentflow/runtime/local_runtime.dart';
import 'package:agentflow/tools/default_tools.dart';
import 'package:flutter_test/flutter_test.dart';

const ModelConfig _mockConfig = ModelConfig(
  id: 'mock',
  label: 'Demo',
  provider: 'mock',
  model: 'mock-agent',
  baseUrl: '',
);

/// Lets a test drive the loop with a scripted [ModelProvider] instead of the
/// canned demo, by overriding the factory's single decision point.
class _ScriptedFactory extends ModelProviderFactory {
  _ScriptedFactory(this._provider);

  final ModelProvider _provider;

  @override
  ModelProvider providerFor(ModelConfig config) => _provider;
}

void main() {
  late Directory tmp;
  late LocalRuntime runtime;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('agentflow_engine_test');
    runtime = LocalRuntime(rootDirectory: tmp.path);
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  AgentEngine buildEngine(ModelProviderFactory factory, ApprovalManager approval) =>
      AgentEngine(
        providerFactory: factory,
        approvalManager: approval,
        defaultRegistry: defaultToolRegistry(),
        contextManager: ContextManager(),
      );

  AgentRunRequest request(String message) => AgentRunRequest(
        userMessage: message,
        workspace: WorkspaceContext(
          workspaceName: 'test-ws',
          rootDirectory: tmp.path,
          runtimeLabel: runtime.label,
        ),
        config: _mockConfig,
        runtime: runtime,
      );

  test('the demo run lists files, then completes with a final answer', () async {
    File('${tmp.path}${Platform.pathSeparator}README.md')
        .writeAsStringSync('# hello\n');
    final approval = ApprovalManager(autoApprove: true);
    addTearDown(approval.dispose);
    final engine = buildEngine(ModelProviderFactory(), approval);

    final run = engine.runTurn(request('explore the workspace'));
    final events = await run.events.toList();
    await run.done;

    expect(
      events.whereType<ToolFinishedEvent>().any((ToolFinishedEvent e) =>
          e.toolName == 'list_files' && !e.result.isError),
      isTrue,
      reason: 'the demo script should have listed the workspace',
    );
    final completed =
        events.whereType<RunCompletedEvent>().single;
    expect(completed.toolCallCount, greaterThanOrEqualTo(1));
    expect(completed.finalText, isNotEmpty);
    expect(
      events.whereType<PhaseChangedEvent>().map((PhaseChangedEvent e) => e.phase),
      contains(AgentPhase.completed),
    );
  });

  test('a denied mutating tool is reported and never writes', () async {
    final approval = ApprovalManager(resolver: (ApprovalRequest r) => ApprovalDecision.deny);
    addTearDown(approval.dispose);
    final mock = MockModelProvider(
      script: <ModelResponse>[
        MockModelProvider.toolCall(
          id: 'call_w1',
          name: 'write_file',
          arguments: <String, dynamic>{'path': 'x.txt', 'content': 'boom'},
          reasoning: 'I will write a file.',
        ),
      ],
      finalText: 'Understood, I will not write the file.',
    );
    final engine = buildEngine(_ScriptedFactory(mock), approval);

    final run = engine.runTurn(request('write x.txt'));
    final events = await run.events.toList();
    await run.done;

    final finished = events.whereType<ToolFinishedEvent>().toList();
    expect(finished, hasLength(1));
    expect(finished.single.toolName, 'write_file');
    expect(finished.single.result.isError, isTrue);
    expect(finished.single.result.data?['denied'], isTrue);
    expect(
      File('${tmp.path}${Platform.pathSeparator}x.txt').existsSync(),
      isFalse,
      reason: 'a denied write must not touch disk',
    );
    // The loop still terminates gracefully with the model's follow-up.
    expect(events.whereType<RunCompletedEvent>().single.finalText,
        'Understood, I will not write the file.');
  });

  test('an approved mutating tool executes and the file lands on disk', () async {
    final approval = ApprovalManager(resolver: (ApprovalRequest r) => ApprovalDecision.allow);
    addTearDown(approval.dispose);
    final mock = MockModelProvider(
      script: <ModelResponse>[
        MockModelProvider.toolCall(
          id: 'call_w1',
          name: 'write_file',
          arguments: <String, dynamic>{'path': 'ok.txt', 'content': 'written\n'},
        ),
      ],
      finalText: 'Wrote ok.txt.',
    );
    final engine = buildEngine(_ScriptedFactory(mock), approval);

    final run = engine.runTurn(request('write ok.txt'));
    final events = await run.events.toList();
    await run.done;

    final finished = events.whereType<ToolFinishedEvent>().single;
    expect(finished.result.isError, isFalse);
    final file = File('${tmp.path}${Platform.pathSeparator}ok.txt');
    expect(file.existsSync(), isTrue);
    expect(file.readAsStringSync(), 'written\n');
    // The write produces a diff payload for the Diff card.
    expect(finished.result.data?['diff'], isNotNull);
  });

  test('write approval includes a diff before the file is touched', () async {
    ApprovalRequest? captured;
    final approval = ApprovalManager(resolver: (ApprovalRequest request) {
      captured = request;
      expect(File('${tmp.path}${Platform.pathSeparator}preview.txt').existsSync(),
          isFalse);
      return ApprovalDecision.deny;
    });
    addTearDown(approval.dispose);
    final mock = MockModelProvider(
      script: <ModelResponse>[
        MockModelProvider.toolCall(
          id: 'call_preview',
          name: 'write_file',
          arguments: <String, dynamic>{
            'path': 'preview.txt',
            'content': 'proposed\n',
          },
        ),
      ],
      finalText: 'The proposed change was rejected.',
    );
    final run = buildEngine(_ScriptedFactory(mock), approval)
        .runTurn(request('write preview.txt'));
    await run.events.toList();
    await run.done;

    expect(captured?.previewData?['diff'], isNotNull);
    expect(File('${tmp.path}${Platform.pathSeparator}preview.txt').existsSync(),
        isFalse);
  });

  test('an unknown tool call yields an error result and keeps looping', () async {
    final approval = ApprovalManager(autoApprove: true);
    addTearDown(approval.dispose);
    final mock = MockModelProvider(
      script: <ModelResponse>[
        MockModelProvider.toolCall(
          id: 'call_x',
          name: 'launch_missiles',
          arguments: <String, dynamic>{},
        ),
      ],
      finalText: 'That tool does not exist.',
    );
    final engine = buildEngine(_ScriptedFactory(mock), approval);

    final run = engine.runTurn(request('do something impossible'));
    final events = await run.events.toList();
    await run.done;

    final finished = events.whereType<ToolFinishedEvent>().single;
    expect(finished.result.isError, isTrue);
    expect(finished.result.content, contains('Unknown or disabled tool'));
    expect(events.whereType<RunCompletedEvent>(), isNotEmpty);
  });

  test('the loop stops at maxIterations without a final answer', () async {
    final approval = ApprovalManager(autoApprove: true);
    addTearDown(approval.dispose);
    // A script that always asks for another tool call → never terminates on its own.
    final mock = MockModelProvider(script: <ModelResponse>[
      for (var i = 0; i < 5; i++)
        MockModelProvider.toolCall(
          id: 'call_$i',
          name: 'list_files',
          arguments: <String, dynamic>{'path': '.'},
        ),
    ]);
    final engine = buildEngine(_ScriptedFactory(mock), approval);

    final run = engine.runTurn(AgentRunRequest(
      userMessage: 'loop forever',
      workspace: WorkspaceContext(
        workspaceName: 'test-ws',
        rootDirectory: tmp.path,
        runtimeLabel: runtime.label,
      ),
      config: _mockConfig,
      runtime: runtime,
      maxIterations: 3,
    ));
    final events = await run.events.toList();
    await run.done;

    expect(events.whereType<ErrorEvent>(), isNotEmpty);
    expect(events.whereType<RunCompletedEvent>(), isEmpty);
    expect(
      events.whereType<PhaseChangedEvent>().map((PhaseChangedEvent e) => e.phase),
      contains(AgentPhase.error),
    );
  });
}
