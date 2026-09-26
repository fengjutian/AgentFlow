/// Deterministic mock provider.
///
/// Lets AgentFlow run end-to-end with no network or API key: it replays a
/// scripted sequence of [ModelResponse]s (tool calls, then a final answer). This
/// powers the "Demo" provider in Settings and makes the agent loop testable.
library;

import '../message.dart';
import 'model_provider.dart';

class MockModelProvider implements ModelProvider {
  MockModelProvider({List<ModelResponse>? script, this.finalText})
      : _script = List<ModelResponse>.of(script ?? <ModelResponse>[]);

  final List<ModelResponse> _script;
  final String? finalText;

  int _calls = 0;

  /// How many times [generate] has been invoked (useful in tests).
  int get callCount => _calls;

  @override
  String get id => 'mock';

  @override
  String get displayName => 'Demo (offline)';

  /// A canned exploration: list the workspace, then report back.
  factory MockModelProvider.demo() => MockModelProvider(
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
  Future<ModelResponse> generate(ModelRequest request) async {
    _calls++;
    if (_script.isNotEmpty) {
      return _script.removeAt(0);
    }
    return ModelResponse.text(
      finalText ??
          'Mock agent finished after $_calls step(s). No script remains, so this '
              'is the final answer.',
    );
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
