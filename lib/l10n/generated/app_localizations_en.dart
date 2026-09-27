// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AgentFlow';

  @override
  String get agent => 'Agent';

  @override
  String get files => 'Files';

  @override
  String get terminal => 'Terminal';

  @override
  String get settings => 'Settings';

  @override
  String get sessions => 'Sessions';

  @override
  String get newSession => 'New session';

  @override
  String get newLabel => 'New';

  @override
  String get clear => 'Clear';

  @override
  String get refresh => 'Refresh';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get create => 'Create';

  @override
  String get save => 'Save';

  @override
  String get undo => 'Undo';

  @override
  String get send => 'Send';

  @override
  String get stop => 'Stop';

  @override
  String get run => 'Run';

  @override
  String get lastCommand => 'Last command';

  @override
  String get commandHint => 'command';

  @override
  String failedToLoad(Object error) {
    return 'Failed to load: $error';
  }

  @override
  String get notFound => 'Not found';

  @override
  String noRouteFor(String uri) {
    return 'No route for $uri';
  }

  @override
  String get noWorkspaceSelected => 'No workspace selected';

  @override
  String get workspaceRequiredDescription =>
      'A workspace is the project folder the agent reads and edits. Pick an existing one or create a new one to begin.';

  @override
  String get selectOrCreateWorkspace => 'Select or create a workspace';

  @override
  String get giveAgentTask => 'Give the agent a task';

  @override
  String get agentTaskDescription =>
      'It will read files, search code, propose changes and run commands — asking before anything risky.';

  @override
  String get exampleAnalyze =>
      'Analyze this project and summarize its architecture.';

  @override
  String get exampleConfiguration =>
      'Find where the app reads its configuration and explain it.';

  @override
  String get examplePerformance =>
      'Why is startup slow? Investigate and propose a fix.';

  @override
  String get describeTask => 'Describe a task…';

  @override
  String get noSessions => 'No sessions yet. Start by sending a task.';

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get workspaces => 'Workspaces';

  @override
  String get noWorkspaces => 'No workspaces yet. Create one to get started.';

  @override
  String get newWorkspace => 'New workspace';

  @override
  String deleteWorkspaceTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get deleteWorkspaceDescription =>
      'This removes the workspace and its local session history. Project files are not deleted.';

  @override
  String get workspaceName => 'Name';

  @override
  String get workspacePath => 'Project path';

  @override
  String get workspacePathHelper =>
      'Absolute path the agent will read and edit.';

  @override
  String get workspaceRequiredFields => 'Name and path are required.';

  @override
  String get selectWorkspace => 'Select workspace';

  @override
  String get selectWorkspaceForFiles =>
      'Select a workspace to browse its files.';

  @override
  String get runtimeUnavailable => 'Runtime unavailable for this workspace.';

  @override
  String get emptyFolder => 'This folder is empty.';

  @override
  String get parentFolder => 'Parent folder';

  @override
  String cannotOpen(Object error) {
    return 'Cannot open: $error';
  }

  @override
  String get emptyFile => '(empty file)';

  @override
  String get selectWorkspaceForTerminal =>
      'Select a workspace to open a shell in its directory.';

  @override
  String get modelProviders => 'Model providers';

  @override
  String get provider => 'Provider';

  @override
  String get runtime => 'Runtime';

  @override
  String get about => 'About';

  @override
  String get offlineDemoMode => 'Running in offline demo mode';

  @override
  String get setAsDefault => 'Set as default';

  @override
  String deleteProviderTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get deleteProviderDescription =>
      'This removes the provider configuration and its stored credential.';

  @override
  String get addProvider => 'Add provider';

  @override
  String get editProvider => 'Edit provider';

  @override
  String get providerType => 'Provider type';

  @override
  String get providerLabel => 'Label';

  @override
  String get model => 'Model';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get apiKey => 'API Key';

  @override
  String get requiredField => 'Required';

  @override
  String get maxTokens => 'Max tokens';

  @override
  String temperatureValue(String value) {
    return 'Temperature: $value';
  }

  @override
  String get approveAction => 'Approve this action';

  @override
  String get confirmHighRisk => 'Confirm a high-risk action';

  @override
  String get deny => 'Deny';

  @override
  String get reject => 'Reject';

  @override
  String get allow => 'Allow';

  @override
  String get accept => 'Accept';

  @override
  String get alwaysAllow => 'Always allow';

  @override
  String get acceptAll => 'Accept all';

  @override
  String get riskAuto => 'auto';

  @override
  String get riskConfirm => 'confirm';

  @override
  String get riskHigh => 'high risk';

  @override
  String get agentActivity => 'Agent Activity';

  @override
  String get phaseIdle => 'Idle';

  @override
  String get phaseThinking => 'Thinking';

  @override
  String get phasePlanning => 'Planning';

  @override
  String get phaseWaitingApproval => 'Waiting for approval';

  @override
  String get phaseExecuting => 'Executing';

  @override
  String get phaseObserving => 'Observing';

  @override
  String get phaseCompleted => 'Completed';

  @override
  String get phaseError => 'Error';

  @override
  String get phaseCancelled => 'Cancelled';

  @override
  String callingTools(String tools) {
    return 'Calling $tools';
  }

  @override
  String get deniedByUser => 'Denied by user';

  @override
  String get done => 'done';
}
