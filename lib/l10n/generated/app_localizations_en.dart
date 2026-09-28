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
  String get redo => 'Redo';

  @override
  String get send => 'Send';

  @override
  String get stop => 'Stop';

  @override
  String get run => 'Run';

  @override
  String get lastCommand => 'Last command';

  @override
  String get commandHint => 'npx';

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
  String get fileSaved => 'File saved';

  @override
  String failedToSave(Object error) {
    return 'Failed to save: $error';
  }

  @override
  String get fileChangedTitle => 'File changed on disk';

  @override
  String get fileChangedDescription =>
      'The agent or another program changed this file after it was opened. Reload the disk version or overwrite it with your edits.';

  @override
  String get reload => 'Reload';

  @override
  String get overwrite => 'Overwrite';

  @override
  String get unsavedChangesTitle => 'Discard unsaved changes?';

  @override
  String get unsavedChangesDescription => 'Your edits have not been saved.';

  @override
  String get discard => 'Discard';

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
  String get loading => 'Loading…';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get workspace => 'Workspace';

  @override
  String get directory => 'Directory';

  @override
  String get none => 'none';

  @override
  String get resolving => 'resolving…';

  @override
  String get shell => 'Shell';

  @override
  String get termux => 'Termux';

  @override
  String get termuxDescription =>
      'On Android the agent runs commands in Termux when it is set up and falls back to the system shell otherwise.';

  @override
  String get waitingForAnswer => 'Waiting for answer…';

  @override
  String get grantTermuxAccess => 'Grant Termux access';

  @override
  String get mvpBuild => 'MVP build';

  @override
  String get demo => 'Demo';

  @override
  String get activeOfflineDemo => 'Active: offline demo';

  @override
  String activeProvider(String name) {
    return 'Active: $name';
  }

  @override
  String get termuxExternalAppsHint =>
      'Termux also needs allow-external-apps=true in its termux.properties before it accepts commands.';

  @override
  String get termuxPermissionHint =>
      'Grant the “Run commands in Termux environment” permission to let the agent use its toolchain.';

  @override
  String get aboutDescription =>
      'An on-device AI agent workstation. The agent reads and edits code, runs commands and operates Git — asking before anything risky.';

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
  String get phaseRecovering => 'Recovering';

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

  @override
  String get search => 'Find';

  @override
  String get replace => 'Replace';

  @override
  String get replaceAll => 'Replace all';

  @override
  String get previousMatch => 'Previous match';

  @override
  String get nextMatch => 'Next match';

  @override
  String get close => 'Close';

  @override
  String get noMatches => '0 results';

  @override
  String matchPosition(int current, int total) {
    return '$current/$total';
  }

  @override
  String replacedOccurrences(int count) {
    return 'Replaced $count occurrences';
  }

  @override
  String get goToLine => 'Go to line';

  @override
  String get lineNumber => 'Line number';

  @override
  String lineRange(int count) {
    return '1–$count';
  }

  @override
  String get go => 'Go';

  @override
  String get invalidLineNumber => 'Line number is outside this file';

  @override
  String get newFile => 'New file';

  @override
  String get newFolder => 'New folder';

  @override
  String get name => 'Name';

  @override
  String get edit => 'Edit';

  @override
  String get rename => 'Rename';

  @override
  String get invalidFileName => 'Enter a valid name without / or \\';

  @override
  String get entryAlreadyExists => 'An entry with this name already exists.';

  @override
  String fileOperationFailed(Object error) {
    return 'File operation failed: $error';
  }

  @override
  String deleteEntryTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get deleteFileDescription => 'This file will be permanently deleted.';

  @override
  String get deleteFolderDescription =>
      'This folder and all of its contents will be permanently deleted.';

  @override
  String get draftRestored => 'Restored unsaved draft from previous session.';

  @override
  String fileTooLarge(String size, String limit) {
    return 'File is too large to edit ($size). Maximum size is $limit.';
  }

  @override
  String get binaryFileNotSupported =>
      'This file appears to be binary and cannot be edited.';

  @override
  String get import => 'Import';

  @override
  String get importing => 'Importing…';

  @override
  String importFailed(Object error) {
    return 'Import failed: $error';
  }

  @override
  String get selectWorkspaceFirst => 'Select a workspace first.';

  @override
  String get noImportedDocuments => 'No imported documents.';

  @override
  String get importDocumentHint => 'Import a PDF or EPUB to get started.';

  @override
  String get deleteDocumentTitle => 'Delete document?';

  @override
  String deleteDocumentDescription(String name) {
    return 'Remove \"$name\" and all extracted text?';
  }

  @override
  String get reader => 'Reader';

  @override
  String get documentNotFound => 'Document not found.';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get tableOfContents => 'Table of contents';

  @override
  String get noExtractedText => 'No extracted text available.';

  @override
  String get askAgentAboutSection => 'Ask Agent about this section';

  @override
  String get askAboutThisSection => 'Ask about this section';

  @override
  String get sendSectionToAgent => 'Send section text to the Agent';

  @override
  String get explainThisSection => 'Please explain this section.';

  @override
  String get summarizeThisSection => 'Summarize this section';

  @override
  String get summarizeSectionConcisely =>
      'Please summarize this section concisely.';

  @override
  String get extractKeyConcepts => 'Extract key concepts';

  @override
  String get extractKeyConceptsDescription =>
      'Extract the key concepts and terms from this section.';

  @override
  String pageIndicator(int current, int total) {
    return '$current / $total';
  }

  @override
  String sectionsCount(int count) {
    return '$count sections';
  }

  @override
  String get terminalHint =>
      'Type a command below.\nTry: ls, pwd, git status, cat README.md';

  @override
  String get running => '(running…)';

  @override
  String get timedOut => '(timed out)';

  @override
  String exitCode(int code) {
    return '(exit $code)';
  }

  @override
  String finishedIn(String elapsed) {
    return '(finished in $elapsed)';
  }

  @override
  String runtimeLabel(String id) {
    return 'Runtime: $id';
  }

  @override
  String get selectRuntime => 'Select runtime';

  @override
  String get runOnThisDevice => 'Run on this device';

  @override
  String get workspaceNameHint => 'My Project';

  @override
  String deleteSessionTitle(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get deleteSessionDescription =>
      'This session and its messages will be permanently deleted.';

  @override
  String get noExtractableText => '(No extractable text for this section.)';

  @override
  String get openFiles => 'Open files';

  @override
  String get recentFiles => 'Recent files';

  @override
  String get diagnostics => 'Diagnostics';

  @override
  String get noDiagnostics => 'No diagnostics';

  @override
  String cannotListFolder(Object error) {
    return 'Cannot list folder: $error';
  }

  @override
  String fileTooLargeToPreview(String name, String size) {
    return '$name is too large to preview ($size).';
  }

  @override
  String errorGeneric(Object error) {
    return 'Error: $error';
  }

  @override
  String get noSshConnections => 'No SSH connections configured.';

  @override
  String get addSshHint =>
      'Add an SSH connection to run commands on remote servers.';

  @override
  String get testConnection => 'Test connection';

  @override
  String get hostKeyMismatch => 'Host key mismatch!';

  @override
  String hostKeyChanged(
    String host,
    int port,
    String stored,
    String presented,
  ) {
    return 'WARNING: The host key for $host:$port has changed!\n\nStored: $stored\nPresented: $presented\n\nThis could indicate a man-in-the-middle attack.';
  }

  @override
  String get newHostKey => 'New host key';

  @override
  String get hostKeyVerified => 'Host key verified';

  @override
  String algorithmLabel(String algorithm) {
    return 'Algorithm: $algorithm';
  }

  @override
  String fingerprintLabel(String fingerprint) {
    return 'Fingerprint: $fingerprint';
  }

  @override
  String get trustHostKeyQuestion =>
      'Trust this host key for future connections?';

  @override
  String get trust => 'Trust';

  @override
  String connectionFailed(Object error) {
    return 'Connection failed: $error';
  }

  @override
  String deleteSshConfigTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get deleteSshConfigDescription =>
      'This SSH connection will be removed.';

  @override
  String get addSshConnection => 'Add SSH Connection';

  @override
  String get editSshConnection => 'Edit SSH Connection';

  @override
  String get label => 'Label';

  @override
  String get host => 'Host';

  @override
  String get port => 'Port';

  @override
  String get username => 'Username';

  @override
  String get authMethod => 'Auth method';

  @override
  String get password => 'Password';

  @override
  String get privateKey => 'Private key';

  @override
  String get privateKeyPem => 'Private key (PEM)';

  @override
  String get keyPassphrase => 'Key passphrase (optional)';

  @override
  String get remoteRoot => 'Remote root';

  @override
  String get selectWorkspaceFirstMcp => 'Select a workspace first.';

  @override
  String get noMcpServers => 'No MCP servers configured.';

  @override
  String get addMcpHint =>
      'Add an MCP server to extend the agent with external tools.';

  @override
  String get connect => 'Connect';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get refreshTools => 'Refresh tools';

  @override
  String get mcpConnected => 'Connected';

  @override
  String get mcpConnecting => 'Connecting';

  @override
  String get mcpDisconnected => 'Disconnected';

  @override
  String toolsAvailable(int count) {
    return '$count tool(s) available';
  }

  @override
  String get connectionSuccessful => 'Connection successful';

  @override
  String get connectionFailedTitle => 'Connection failed';

  @override
  String connectionSuccessfulDetail(int count) {
    return 'Connected successfully. Found $count tool(s).';
  }

  @override
  String deleteMcpConfigTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get deleteMcpConfigDescription => 'This MCP server will be removed.';

  @override
  String get addMcpServer => 'Add MCP Server';

  @override
  String get editMcpServer => 'Edit MCP Server';

  @override
  String get transport => 'Transport';

  @override
  String get endpointUrl => 'Endpoint URL';

  @override
  String get endpointUrlHint => 'https://mcp.example.com/mcp';

  @override
  String get command => 'Command';

  @override
  String get argumentsLabel => 'Arguments (space-separated)';

  @override
  String get argumentsHint => '-y @modelcontextprotocol/server-name';

  @override
  String get authorizationHeader => 'Authorization header (optional)';

  @override
  String get mcpEnabled => 'Enabled';

  @override
  String get mcpEnabledDescription => 'Agent can use this server';

  @override
  String get mcpAutoConnect => 'Auto-connect';

  @override
  String get mcpAutoConnectDescription => 'Connect when workspace opens';

  @override
  String get noProviderConfiguredHint =>
      'No provider is configured yet, so the agent uses a built-in mock that demonstrates the loop without any network. Add an OpenAI-compatible provider to use a real model.';

  @override
  String get providerLabelHint => 'DeepSeek (personal)';

  @override
  String get statusReady => 'Ready';

  @override
  String get statusParsing => 'Parsing';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusOcrRequired => 'OCR needed';

  @override
  String get noOutput => '(no output)';

  @override
  String get modelHint => 'gpt-4o-mini / deepseek-chat';

  @override
  String get copyDiagnostics => 'Copy diagnostics';

  @override
  String get diagnosticsCopied => 'Diagnostics copied to clipboard';

  @override
  String get version => 'Version';
}
