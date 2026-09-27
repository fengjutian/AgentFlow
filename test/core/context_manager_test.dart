import 'package:agentflow/core/context/context_manager.dart';
import 'package:agentflow/core/message.dart';
import 'package:agentflow/core/model/model_provider.dart';
import 'package:agentflow/tools/tool_registry.dart';
import 'package:flutter_test/flutter_test.dart';

const _config = ModelConfig(
  id: 'test',
  label: 'Test',
  provider: 'test',
  model: 'test-model',
  baseUrl: '',
  contextWindow: 100,
);

void main() {
  late ContextManager cm;
  late ToolRegistry registry;

  setUp(() {
    cm = ContextManager();
    registry = ToolRegistry();
  });

  group('estimateTokens', () {
    test('returns 0 for empty list', () {
      expect(cm.estimateTokens(<ChatMessage>[]), 0);
    });

    test('estimates based on character count', () {
      final messages = <ChatMessage>[ChatMessage.user('hello world')];
      // "hello world" is 11 chars → 11 * 0.25 = 2.75 → ceil → 3
      expect(cm.estimateTokens(messages), 3);
    });
  });

  group('buildSystemPrompt', () {
    test('includes workspace facts', () {
      const ctx = WorkspaceContext(
        workspaceName: 'my-project',
        rootDirectory: '/home/user/my-project',
        runtimeLabel: 'local',
      );
      final prompt = cm.buildSystemPrompt(ctx);
      expect(prompt, contains('my-project'));
      expect(prompt, contains('/home/user/my-project'));
      expect(prompt, contains('local'));
    });

    test('includes memory block when present', () {
      const ctx = WorkspaceContext(
        workspaceName: 'ws',
        rootDirectory: '/ws',
        runtimeLabel: 'local',
        memoryBlock: 'User prefers concise answers.',
      );
      final prompt = cm.buildSystemPrompt(ctx);
      expect(prompt, contains('User prefers concise answers.'));
    });
  });

  group('build', () {
    test('returns ContextBuildResult with request', () {
      const workspace = WorkspaceContext(
        workspaceName: 'ws',
        rootDirectory: '/ws',
        runtimeLabel: 'local',
      );
      final result = cm.build(
        workspace: workspace,
        history: <ChatMessage>[ChatMessage.user('hi')],
        registry: registry,
        config: _config,
      );
      expect(result.request, isA<ModelRequest>());
      expect(result.request.messages, isNotEmpty);
      // Small history fits the budget → no summary
      expect(result.droppedSummary, isNull);
    });

    test('generates summary when history exceeds budget', () {
      const workspace = WorkspaceContext(
        workspaceName: 'ws',
        rootDirectory: '/ws',
        runtimeLabel: 'local',
      );
      // Create a large history that exceeds the 100-token context window
      final history = <ChatMessage>[];
      for (var i = 0; i < 50; i++) {
        history.add(ChatMessage.user('Question number $i with some padding text'));
        history.add(ChatMessage(
          role: MessageRole.assistant,
          content: 'Answer number $i with explanation and details.',
        ));
      }

      final result = cm.build(
        workspace: workspace,
        history: history,
        registry: registry,
        config: _config,
      );

      // Should have trimmed messages and generated a summary
      expect(result.droppedSummary, isNotNull);
      expect(result.droppedSummary, contains('Earlier conversation'));
      // The request messages should include the system prompt + summary + trimmed history
      expect(result.request.messages.first.role, MessageRole.system);
    });

    test('merges pre-existing summary with new drops', () {
      const workspace = WorkspaceContext(
        workspaceName: 'ws',
        rootDirectory: '/ws',
        runtimeLabel: 'local',
      );
      final history = <ChatMessage>[];
      for (var i = 0; i < 50; i++) {
        history.add(ChatMessage.user('Long question $i with extra padding'));
        history.add(ChatMessage(
          role: MessageRole.assistant,
          content: 'Long answer $i with detailed explanation',
        ));
      }

      final result = cm.build(
        workspace: workspace,
        history: history,
        registry: registry,
        config: _config,
        conversationSummary: 'Previously: user asked about X.',
      );

      expect(result.droppedSummary, contains('Previously: user asked about X.'));
      expect(result.droppedSummary, contains('Earlier conversation'));
    });

    test('passes through existing summary when no trimming needed', () {
      const workspace = WorkspaceContext(
        workspaceName: 'ws',
        rootDirectory: '/ws',
        runtimeLabel: 'local',
      );
      final result = cm.build(
        workspace: workspace,
        history: <ChatMessage>[ChatMessage.user('short')],
        registry: registry,
        config: _config,
        conversationSummary: 'Previously discussed topic A.',
      );

      // No trimming → droppedSummary stays as the original
      expect(result.droppedSummary, 'Previously discussed topic A.');
      // The request should include the summary system message
      final summaryMsg = result.request.messages[1];
      expect(summaryMsg.content, contains('Previously discussed topic A.'));
    });
  });

  group('dropped message summary structure', () {
    test('summarizes user, assistant, and tool messages', () {
      const workspace = WorkspaceContext(
        workspaceName: 'ws',
        rootDirectory: '/ws',
        runtimeLabel: 'local',
      );

      // Build a history with user, assistant (with tool calls), and tool results
      final history = <ChatMessage>[];
      for (var i = 0; i < 30; i++) {
        history.add(ChatMessage.user('Question $i'));
        history.add(ChatMessage(
          role: MessageRole.assistant,
          content: '',
          toolCalls: <ToolCall>[
            ToolCall(id: 'c$i', name: 'read_file', arguments: <String, dynamic>{'path': 'file$i.dart'}),
          ],
        ));
        history.add(ChatMessage(
          role: MessageRole.tool,
          content: 'File content $i...',
          toolCallId: 'c$i',
          name: 'read_file',
        ));
      }

      final result = cm.build(
        workspace: workspace,
        history: history,
        registry: registry,
        config: _config,
      );

      if (result.droppedSummary != null) {
        expect(result.droppedSummary, contains('User asked:'));
        expect(result.droppedSummary, contains('Called read_file'));
        expect(result.droppedSummary, contains('read_file result:'));
      }
    });
  });
}
