/// Deterministic mock provider with streaming support.
///
/// Lets AgentFlow run end-to-end with no network or API key: it replays a
/// scripted sequence of [ModelResponse]s (tool calls, then a final answer),
/// streaming each response as a series of [ModelChunk]s. Text is emitted
/// word-by-word with a configurable [streamDelay] so the UI renders a
/// realistic typing effect during demos while tests can pass
/// `Duration.zero` for instant execution.
library;

import '../message.dart';
import 'model_provider.dart';

class MockModelProvider implements ModelProvider {
  MockModelProvider({
    List<ModelResponse>? script,
    this.finalText,
    this.streamDelay = const Duration(milliseconds: 10),
  }) : _script = List<ModelResponse>.of(script ?? <ModelResponse>[]);

  final List<ModelResponse> _script;
  final String? finalText;

  /// Delay between emitted [ContentDelta] chunks. Tests pass [Duration.zero]
  /// to avoid artificial waits; the demo factory uses a small delay for a
  /// realistic typing effect.
  final Duration streamDelay;

  int _calls = 0;

  /// How many times [generate] has been invoked (useful in tests).
  int get callCount => _calls;

  @override
  String get id => 'mock';

  @override
  String get displayName => 'Demo (offline)';

  /// A canned exploration: list the workspace, then report back.
  ///
  /// [streamDelay] controls the pause between emitted text deltas. The default
  /// 10 ms gives a realistic typing effect in the UI; tests pass
  /// [Duration.zero] for instant execution.
  factory MockModelProvider.demo({
    Duration streamDelay = const Duration(milliseconds: 10),
  }) =>
      MockModelProvider(
        streamDelay: streamDelay,
        script: <ModelResponse>[
          ModelResponse(
            content: 'I will start by inspecting the workspace layout.',
            toolCalls: <ToolCall>[
              ToolCall(
                id: 'call_list_1',
                name: 'list_files',
                arguments: <String, dynamic>{'path': '.'},
              ),
            ],
            finishReason: FinishReason.toolCalls,
          ),
        ],
        finalText: 'I inspected the workspace root. This is an offline demo run '
            '— connect a real model provider in Settings to let the agent read, '
            'search, edit code and run tests.',
      );

  @override
  Stream<ModelChunk> generate(ModelRequest request) async* {
    _calls++;
    final ModelResponse response;
    if (_script.isNotEmpty) {
      response = _script.removeAt(0);
    } else {
      response = ModelResponse.text(
        finalText ??
            'Mock agent finished after $_calls step(s). No script remains, so this '
                'is the final answer.',
      );
    }

    // Stream content word-by-word to simulate token-by-token output.
    if (response.content.isNotEmpty) {
      final words = response.content.split(' ');
      for (var i = 0; i < words.length; i++) {
        if (streamDelay > Duration.zero) {
          await Future<void>.delayed(streamDelay);
        }
        yield ContentDelta(i == 0 ? words[i] : ' ${words[i]}');
      }
    }

    // Emit tool calls as individual deltas.
    for (final call in response.toolCalls) {
      yield ToolCallDelta(call);
    }

    yield FinishChunk(reason: response.finishReason, usage: response.rawUsage);
  }

  /// Builds a scripted tool-call response.
  static ModelResponse toolCall({
    required String id,
    required String name,
    required Map<String, dynamic> arguments,
    String reasoning = '',
  }) =>
      ModelResponse(
        content: reasoning,
        toolCalls: <ToolCall>[
          ToolCall(id: id, name: name, arguments: arguments),
        ],
        finishReason: FinishReason.toolCalls,
      );
}
