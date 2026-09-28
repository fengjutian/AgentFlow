import 'package:agentflow/core/editor/editor_workspace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('opens, activates and closes editor tabs', () {
    final controller = EditorWorkspaceController();

    controller.open(const EditorLocation(path: 'lib/a.dart'));
    controller.open(const EditorLocation(path: 'lib/b.dart', line: 4));

    expect(controller.state.tabs.map((tab) => tab.name), <String>['a.dart', 'b.dart']);
    expect(controller.state.activeTab?.path, 'lib/b.dart');
    expect(controller.state.activeTab?.location?.line, 4);

    controller.activate(0);
    expect(controller.state.activeTab?.path, 'lib/a.dart');

    controller.close(0);
    expect(controller.state.tabs, hasLength(1));
    expect(controller.state.activeTab?.path, 'lib/b.dart');
  });

  test('reopening a file updates location without duplicating the tab', () {
    final controller = EditorWorkspaceController();
    controller.open(const EditorLocation(path: 'lib/a.dart'));
    controller.open(const EditorLocation(path: 'lib/a.dart', line: 8, column: 3));

    expect(controller.state.tabs, hasLength(1));
    expect(controller.state.activeTab?.location?.line, 8);
    expect(controller.state.activeTab?.location?.column, 3);
  });

  test('recent files are de-duplicated and bounded', () {
    final controller = EditorWorkspaceController();
    for (var i = 0; i < 20; i++) {
      controller.open(EditorLocation(path: 'file_$i.txt'));
    }
    controller.open(const EditorLocation(path: 'file_15.txt'));

    expect(controller.state.recentFiles, hasLength(EditorWorkspaceController.maxRecentFiles));
    expect(controller.state.recentFiles.first.path, 'file_15.txt');
    expect(
      controller.state.recentFiles.where((tab) => tab.path == 'file_15.txt'),
      hasLength(1),
    );
  });

  test('stores diagnostics for navigation', () {
    final controller = EditorWorkspaceController();
    controller.setDiagnostics(const <EditorDiagnostic>[
      EditorDiagnostic(
        message: 'Undefined name',
        location: EditorLocation(path: 'lib/main.dart', line: 12, column: 5),
      ),
    ]);

    expect(controller.state.diagnostics.single.location.line, 12);
  });
}
