import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AgentFlow'**
  String get appTitle;

  /// No description provided for @agent.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get agent;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @terminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get terminal;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @newSession.
  ///
  /// In en, this message translates to:
  /// **'New session'**
  String get newSession;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLabel;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @run.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get run;

  /// No description provided for @lastCommand.
  ///
  /// In en, this message translates to:
  /// **'Last command'**
  String get lastCommand;

  /// No description provided for @commandHint.
  ///
  /// In en, this message translates to:
  /// **'npx'**
  String get commandHint;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load: {error}'**
  String failedToLoad(Object error);

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFound;

  /// No description provided for @noRouteFor.
  ///
  /// In en, this message translates to:
  /// **'No route for {uri}'**
  String noRouteFor(String uri);

  /// No description provided for @noWorkspaceSelected.
  ///
  /// In en, this message translates to:
  /// **'No workspace selected'**
  String get noWorkspaceSelected;

  /// No description provided for @workspaceRequiredDescription.
  ///
  /// In en, this message translates to:
  /// **'A workspace is the project folder the agent reads and edits. Pick an existing one or create a new one to begin.'**
  String get workspaceRequiredDescription;

  /// No description provided for @selectOrCreateWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Select or create a workspace'**
  String get selectOrCreateWorkspace;

  /// No description provided for @giveAgentTask.
  ///
  /// In en, this message translates to:
  /// **'Give the agent a task'**
  String get giveAgentTask;

  /// No description provided for @agentTaskDescription.
  ///
  /// In en, this message translates to:
  /// **'It will read files, search code, propose changes and run commands — asking before anything risky.'**
  String get agentTaskDescription;

  /// No description provided for @exampleAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze this project and summarize its architecture.'**
  String get exampleAnalyze;

  /// No description provided for @exampleConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Find where the app reads its configuration and explain it.'**
  String get exampleConfiguration;

  /// No description provided for @examplePerformance.
  ///
  /// In en, this message translates to:
  /// **'Why is startup slow? Investigate and propose a fix.'**
  String get examplePerformance;

  /// No description provided for @describeTask.
  ///
  /// In en, this message translates to:
  /// **'Describe a task…'**
  String get describeTask;

  /// No description provided for @noSessions.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet. Start by sending a task.'**
  String get noSessions;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgo(int count);

  /// No description provided for @workspaces.
  ///
  /// In en, this message translates to:
  /// **'Workspaces'**
  String get workspaces;

  /// No description provided for @noWorkspaces.
  ///
  /// In en, this message translates to:
  /// **'No workspaces yet. Create one to get started.'**
  String get noWorkspaces;

  /// No description provided for @newWorkspace.
  ///
  /// In en, this message translates to:
  /// **'New workspace'**
  String get newWorkspace;

  /// No description provided for @deleteWorkspaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteWorkspaceTitle(String name);

  /// No description provided for @deleteWorkspaceDescription.
  ///
  /// In en, this message translates to:
  /// **'This removes the workspace and its local session history. Project files are not deleted.'**
  String get deleteWorkspaceDescription;

  /// No description provided for @workspaceName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get workspaceName;

  /// No description provided for @workspacePath.
  ///
  /// In en, this message translates to:
  /// **'Project path'**
  String get workspacePath;

  /// No description provided for @workspacePathHelper.
  ///
  /// In en, this message translates to:
  /// **'Absolute path the agent will read and edit.'**
  String get workspacePathHelper;

  /// No description provided for @workspaceRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Name and path are required.'**
  String get workspaceRequiredFields;

  /// No description provided for @selectWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Select workspace'**
  String get selectWorkspace;

  /// No description provided for @selectWorkspaceForFiles.
  ///
  /// In en, this message translates to:
  /// **'Select a workspace to browse its files.'**
  String get selectWorkspaceForFiles;

  /// No description provided for @runtimeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Runtime unavailable for this workspace.'**
  String get runtimeUnavailable;

  /// No description provided for @emptyFolder.
  ///
  /// In en, this message translates to:
  /// **'This folder is empty.'**
  String get emptyFolder;

  /// No description provided for @parentFolder.
  ///
  /// In en, this message translates to:
  /// **'Parent folder'**
  String get parentFolder;

  /// No description provided for @cannotOpen.
  ///
  /// In en, this message translates to:
  /// **'Cannot open: {error}'**
  String cannotOpen(Object error);

  /// No description provided for @emptyFile.
  ///
  /// In en, this message translates to:
  /// **'(empty file)'**
  String get emptyFile;

  /// No description provided for @fileSaved.
  ///
  /// In en, this message translates to:
  /// **'File saved'**
  String get fileSaved;

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String failedToSave(Object error);

  /// No description provided for @fileChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'File changed on disk'**
  String get fileChangedTitle;

  /// No description provided for @fileChangedDescription.
  ///
  /// In en, this message translates to:
  /// **'The agent or another program changed this file after it was opened. Reload the disk version or overwrite it with your edits.'**
  String get fileChangedDescription;

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @overwrite.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get overwrite;

  /// No description provided for @unsavedChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard unsaved changes?'**
  String get unsavedChangesTitle;

  /// No description provided for @unsavedChangesDescription.
  ///
  /// In en, this message translates to:
  /// **'Your edits have not been saved.'**
  String get unsavedChangesDescription;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @selectWorkspaceForTerminal.
  ///
  /// In en, this message translates to:
  /// **'Select a workspace to open a shell in its directory.'**
  String get selectWorkspaceForTerminal;

  /// No description provided for @modelProviders.
  ///
  /// In en, this message translates to:
  /// **'Model providers'**
  String get modelProviders;

  /// No description provided for @provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// No description provided for @runtime.
  ///
  /// In en, this message translates to:
  /// **'Runtime'**
  String get runtime;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @offlineDemoMode.
  ///
  /// In en, this message translates to:
  /// **'Running in offline demo mode'**
  String get offlineDemoMode;

  /// No description provided for @setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get setAsDefault;

  /// No description provided for @deleteProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteProviderTitle(String name);

  /// No description provided for @deleteProviderDescription.
  ///
  /// In en, this message translates to:
  /// **'This removes the provider configuration and its stored credential.'**
  String get deleteProviderDescription;

  /// No description provided for @addProvider.
  ///
  /// In en, this message translates to:
  /// **'Add provider'**
  String get addProvider;

  /// No description provided for @editProvider.
  ///
  /// In en, this message translates to:
  /// **'Edit provider'**
  String get editProvider;

  /// No description provided for @providerType.
  ///
  /// In en, this message translates to:
  /// **'Provider type'**
  String get providerType;

  /// No description provided for @providerLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get providerLabel;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @baseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get baseUrl;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKey;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @maxTokens.
  ///
  /// In en, this message translates to:
  /// **'Max tokens'**
  String get maxTokens;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @workspace.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get workspace;

  /// No description provided for @directory.
  ///
  /// In en, this message translates to:
  /// **'Directory'**
  String get directory;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get none;

  /// No description provided for @resolving.
  ///
  /// In en, this message translates to:
  /// **'resolving…'**
  String get resolving;

  /// No description provided for @shell.
  ///
  /// In en, this message translates to:
  /// **'Shell'**
  String get shell;

  /// No description provided for @termux.
  ///
  /// In en, this message translates to:
  /// **'Termux'**
  String get termux;

  /// No description provided for @termuxDescription.
  ///
  /// In en, this message translates to:
  /// **'On Android the agent runs commands in Termux when it is set up and falls back to the system shell otherwise.'**
  String get termuxDescription;

  /// No description provided for @waitingForAnswer.
  ///
  /// In en, this message translates to:
  /// **'Waiting for answer…'**
  String get waitingForAnswer;

  /// No description provided for @grantTermuxAccess.
  ///
  /// In en, this message translates to:
  /// **'Grant Termux access'**
  String get grantTermuxAccess;

  /// No description provided for @mvpBuild.
  ///
  /// In en, this message translates to:
  /// **'MVP build'**
  String get mvpBuild;

  /// No description provided for @demo.
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get demo;

  /// No description provided for @activeOfflineDemo.
  ///
  /// In en, this message translates to:
  /// **'Active: offline demo'**
  String get activeOfflineDemo;

  /// No description provided for @activeProvider.
  ///
  /// In en, this message translates to:
  /// **'Active: {name}'**
  String activeProvider(String name);

  /// No description provided for @termuxExternalAppsHint.
  ///
  /// In en, this message translates to:
  /// **'Termux also needs allow-external-apps=true in its termux.properties before it accepts commands.'**
  String get termuxExternalAppsHint;

  /// No description provided for @termuxPermissionHint.
  ///
  /// In en, this message translates to:
  /// **'Grant the “Run commands in Termux environment” permission to let the agent use its toolchain.'**
  String get termuxPermissionHint;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'An on-device AI agent workstation. The agent reads and edits code, runs commands and operates Git — asking before anything risky.'**
  String get aboutDescription;

  /// No description provided for @temperatureValue.
  ///
  /// In en, this message translates to:
  /// **'Temperature: {value}'**
  String temperatureValue(String value);

  /// No description provided for @approveAction.
  ///
  /// In en, this message translates to:
  /// **'Approve this action'**
  String get approveAction;

  /// No description provided for @confirmHighRisk.
  ///
  /// In en, this message translates to:
  /// **'Confirm a high-risk action'**
  String get confirmHighRisk;

  /// No description provided for @deny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get deny;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @alwaysAllow.
  ///
  /// In en, this message translates to:
  /// **'Always allow'**
  String get alwaysAllow;

  /// No description provided for @acceptAll.
  ///
  /// In en, this message translates to:
  /// **'Accept all'**
  String get acceptAll;

  /// No description provided for @riskAuto.
  ///
  /// In en, this message translates to:
  /// **'auto'**
  String get riskAuto;

  /// No description provided for @riskConfirm.
  ///
  /// In en, this message translates to:
  /// **'confirm'**
  String get riskConfirm;

  /// No description provided for @riskHigh.
  ///
  /// In en, this message translates to:
  /// **'high risk'**
  String get riskHigh;

  /// No description provided for @agentActivity.
  ///
  /// In en, this message translates to:
  /// **'Agent Activity'**
  String get agentActivity;

  /// No description provided for @phaseIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get phaseIdle;

  /// No description provided for @phaseThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking'**
  String get phaseThinking;

  /// No description provided for @phasePlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get phasePlanning;

  /// No description provided for @phaseWaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get phaseWaitingApproval;

  /// No description provided for @phaseExecuting.
  ///
  /// In en, this message translates to:
  /// **'Executing'**
  String get phaseExecuting;

  /// No description provided for @phaseObserving.
  ///
  /// In en, this message translates to:
  /// **'Observing'**
  String get phaseObserving;

  /// No description provided for @phaseRecovering.
  ///
  /// In en, this message translates to:
  /// **'Recovering'**
  String get phaseRecovering;

  /// No description provided for @phaseCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get phaseCompleted;

  /// No description provided for @phaseError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get phaseError;

  /// No description provided for @phaseCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get phaseCancelled;

  /// No description provided for @callingTools.
  ///
  /// In en, this message translates to:
  /// **'Calling {tools}'**
  String callingTools(String tools);

  /// No description provided for @deniedByUser.
  ///
  /// In en, this message translates to:
  /// **'Denied by user'**
  String get deniedByUser;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get done;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get search;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @replaceAll.
  ///
  /// In en, this message translates to:
  /// **'Replace all'**
  String get replaceAll;

  /// No description provided for @previousMatch.
  ///
  /// In en, this message translates to:
  /// **'Previous match'**
  String get previousMatch;

  /// No description provided for @nextMatch.
  ///
  /// In en, this message translates to:
  /// **'Next match'**
  String get nextMatch;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'0 results'**
  String get noMatches;

  /// No description provided for @matchPosition.
  ///
  /// In en, this message translates to:
  /// **'{current}/{total}'**
  String matchPosition(int current, int total);

  /// No description provided for @replacedOccurrences.
  ///
  /// In en, this message translates to:
  /// **'Replaced {count} occurrences'**
  String replacedOccurrences(int count);

  /// No description provided for @goToLine.
  ///
  /// In en, this message translates to:
  /// **'Go to line'**
  String get goToLine;

  /// No description provided for @lineNumber.
  ///
  /// In en, this message translates to:
  /// **'Line number'**
  String get lineNumber;

  /// No description provided for @lineRange.
  ///
  /// In en, this message translates to:
  /// **'1–{count}'**
  String lineRange(int count);

  /// No description provided for @go.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get go;

  /// No description provided for @invalidLineNumber.
  ///
  /// In en, this message translates to:
  /// **'Line number is outside this file'**
  String get invalidLineNumber;

  /// No description provided for @newFile.
  ///
  /// In en, this message translates to:
  /// **'New file'**
  String get newFile;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get newFolder;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @invalidFileName.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid name without / or \\'**
  String get invalidFileName;

  /// No description provided for @entryAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'An entry with this name already exists.'**
  String get entryAlreadyExists;

  /// No description provided for @fileOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'File operation failed: {error}'**
  String fileOperationFailed(Object error);

  /// No description provided for @deleteEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteEntryTitle(String name);

  /// No description provided for @deleteFileDescription.
  ///
  /// In en, this message translates to:
  /// **'This file will be permanently deleted.'**
  String get deleteFileDescription;

  /// No description provided for @deleteFolderDescription.
  ///
  /// In en, this message translates to:
  /// **'This folder and all of its contents will be permanently deleted.'**
  String get deleteFolderDescription;

  /// No description provided for @draftRestored.
  ///
  /// In en, this message translates to:
  /// **'Restored unsaved draft from previous session.'**
  String get draftRestored;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File is too large to edit ({size}). Maximum size is {limit}.'**
  String fileTooLarge(String size, String limit);

  /// No description provided for @binaryFileNotSupported.
  ///
  /// In en, this message translates to:
  /// **'This file appears to be binary and cannot be edited.'**
  String get binaryFileNotSupported;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @importing.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get importing;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(Object error);

  /// No description provided for @selectWorkspaceFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a workspace first.'**
  String get selectWorkspaceFirst;

  /// No description provided for @noImportedDocuments.
  ///
  /// In en, this message translates to:
  /// **'No imported documents.'**
  String get noImportedDocuments;

  /// No description provided for @importDocumentHint.
  ///
  /// In en, this message translates to:
  /// **'Import a PDF or EPUB to get started.'**
  String get importDocumentHint;

  /// No description provided for @deleteDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete document?'**
  String get deleteDocumentTitle;

  /// No description provided for @deleteDocumentDescription.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" and all extracted text?'**
  String deleteDocumentDescription(String name);

  /// No description provided for @reader.
  ///
  /// In en, this message translates to:
  /// **'Reader'**
  String get reader;

  /// No description provided for @documentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Document not found.'**
  String get documentNotFound;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @tableOfContents.
  ///
  /// In en, this message translates to:
  /// **'Table of contents'**
  String get tableOfContents;

  /// No description provided for @noExtractedText.
  ///
  /// In en, this message translates to:
  /// **'No extracted text available.'**
  String get noExtractedText;

  /// No description provided for @askAgentAboutSection.
  ///
  /// In en, this message translates to:
  /// **'Ask Agent about this section'**
  String get askAgentAboutSection;

  /// No description provided for @askAboutThisSection.
  ///
  /// In en, this message translates to:
  /// **'Ask about this section'**
  String get askAboutThisSection;

  /// No description provided for @sendSectionToAgent.
  ///
  /// In en, this message translates to:
  /// **'Send section text to the Agent'**
  String get sendSectionToAgent;

  /// No description provided for @explainThisSection.
  ///
  /// In en, this message translates to:
  /// **'Please explain this section.'**
  String get explainThisSection;

  /// No description provided for @summarizeThisSection.
  ///
  /// In en, this message translates to:
  /// **'Summarize this section'**
  String get summarizeThisSection;

  /// No description provided for @summarizeSectionConcisely.
  ///
  /// In en, this message translates to:
  /// **'Please summarize this section concisely.'**
  String get summarizeSectionConcisely;

  /// No description provided for @extractKeyConcepts.
  ///
  /// In en, this message translates to:
  /// **'Extract key concepts'**
  String get extractKeyConcepts;

  /// No description provided for @extractKeyConceptsDescription.
  ///
  /// In en, this message translates to:
  /// **'Extract the key concepts and terms from this section.'**
  String get extractKeyConceptsDescription;

  /// No description provided for @pageIndicator.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String pageIndicator(int current, int total);

  /// No description provided for @sectionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sections'**
  String sectionsCount(int count);

  /// No description provided for @terminalHint.
  ///
  /// In en, this message translates to:
  /// **'Type a command below.\nTry: ls, pwd, git status, cat README.md'**
  String get terminalHint;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'(running…)'**
  String get running;

  /// No description provided for @timedOut.
  ///
  /// In en, this message translates to:
  /// **'(timed out)'**
  String get timedOut;

  /// No description provided for @exitCode.
  ///
  /// In en, this message translates to:
  /// **'(exit {code})'**
  String exitCode(int code);

  /// No description provided for @finishedIn.
  ///
  /// In en, this message translates to:
  /// **'(finished in {elapsed})'**
  String finishedIn(String elapsed);

  /// No description provided for @runtimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Runtime: {id}'**
  String runtimeLabel(String id);

  /// No description provided for @selectRuntime.
  ///
  /// In en, this message translates to:
  /// **'Select runtime'**
  String get selectRuntime;

  /// No description provided for @runOnThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Run on this device'**
  String get runOnThisDevice;

  /// No description provided for @workspaceNameHint.
  ///
  /// In en, this message translates to:
  /// **'My Project'**
  String get workspaceNameHint;

  /// No description provided for @deleteSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"?'**
  String deleteSessionTitle(String title);

  /// No description provided for @deleteSessionDescription.
  ///
  /// In en, this message translates to:
  /// **'This session and its messages will be permanently deleted.'**
  String get deleteSessionDescription;

  /// No description provided for @noExtractableText.
  ///
  /// In en, this message translates to:
  /// **'(No extractable text for this section.)'**
  String get noExtractableText;

  /// No description provided for @openFiles.
  ///
  /// In en, this message translates to:
  /// **'Open files'**
  String get openFiles;

  /// No description provided for @recentFiles.
  ///
  /// In en, this message translates to:
  /// **'Recent files'**
  String get recentFiles;

  /// No description provided for @diagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnostics;

  /// No description provided for @noDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'No diagnostics'**
  String get noDiagnostics;

  /// No description provided for @cannotListFolder.
  ///
  /// In en, this message translates to:
  /// **'Cannot list folder: {error}'**
  String cannotListFolder(Object error);

  /// No description provided for @fileTooLargeToPreview.
  ///
  /// In en, this message translates to:
  /// **'{name} is too large to preview ({size}).'**
  String fileTooLargeToPreview(String name, String size);

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorGeneric(Object error);

  /// No description provided for @noSshConnections.
  ///
  /// In en, this message translates to:
  /// **'No SSH connections configured.'**
  String get noSshConnections;

  /// No description provided for @addSshHint.
  ///
  /// In en, this message translates to:
  /// **'Add an SSH connection to run commands on remote servers.'**
  String get addSshHint;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get testConnection;

  /// No description provided for @hostKeyMismatch.
  ///
  /// In en, this message translates to:
  /// **'Host key mismatch!'**
  String get hostKeyMismatch;

  /// No description provided for @hostKeyChanged.
  ///
  /// In en, this message translates to:
  /// **'WARNING: The host key for {host}:{port} has changed!\n\nStored: {stored}\nPresented: {presented}\n\nThis could indicate a man-in-the-middle attack.'**
  String hostKeyChanged(String host, int port, String stored, String presented);

  /// No description provided for @newHostKey.
  ///
  /// In en, this message translates to:
  /// **'New host key'**
  String get newHostKey;

  /// No description provided for @hostKeyVerified.
  ///
  /// In en, this message translates to:
  /// **'Host key verified'**
  String get hostKeyVerified;

  /// No description provided for @algorithmLabel.
  ///
  /// In en, this message translates to:
  /// **'Algorithm: {algorithm}'**
  String algorithmLabel(String algorithm);

  /// No description provided for @fingerprintLabel.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint: {fingerprint}'**
  String fingerprintLabel(String fingerprint);

  /// No description provided for @trustHostKeyQuestion.
  ///
  /// In en, this message translates to:
  /// **'Trust this host key for future connections?'**
  String get trustHostKeyQuestion;

  /// No description provided for @trust.
  ///
  /// In en, this message translates to:
  /// **'Trust'**
  String get trust;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String connectionFailed(Object error);

  /// No description provided for @deleteSshConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteSshConfigTitle(String name);

  /// No description provided for @deleteSshConfigDescription.
  ///
  /// In en, this message translates to:
  /// **'This SSH connection will be removed.'**
  String get deleteSshConfigDescription;

  /// No description provided for @addSshConnection.
  ///
  /// In en, this message translates to:
  /// **'Add SSH Connection'**
  String get addSshConnection;

  /// No description provided for @editSshConnection.
  ///
  /// In en, this message translates to:
  /// **'Edit SSH Connection'**
  String get editSshConnection;

  /// No description provided for @label.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get label;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get host;

  /// No description provided for @port.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @authMethod.
  ///
  /// In en, this message translates to:
  /// **'Auth method'**
  String get authMethod;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @privateKey.
  ///
  /// In en, this message translates to:
  /// **'Private key'**
  String get privateKey;

  /// No description provided for @privateKeyPem.
  ///
  /// In en, this message translates to:
  /// **'Private key (PEM)'**
  String get privateKeyPem;

  /// No description provided for @keyPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Key passphrase (optional)'**
  String get keyPassphrase;

  /// No description provided for @remoteRoot.
  ///
  /// In en, this message translates to:
  /// **'Remote root'**
  String get remoteRoot;

  /// No description provided for @selectWorkspaceFirstMcp.
  ///
  /// In en, this message translates to:
  /// **'Select a workspace first.'**
  String get selectWorkspaceFirstMcp;

  /// No description provided for @noMcpServers.
  ///
  /// In en, this message translates to:
  /// **'No MCP servers configured.'**
  String get noMcpServers;

  /// No description provided for @addMcpHint.
  ///
  /// In en, this message translates to:
  /// **'Add an MCP server to extend the agent with external tools.'**
  String get addMcpHint;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @refreshTools.
  ///
  /// In en, this message translates to:
  /// **'Refresh tools'**
  String get refreshTools;

  /// No description provided for @mcpConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get mcpConnected;

  /// No description provided for @mcpConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get mcpConnecting;

  /// No description provided for @mcpDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get mcpDisconnected;

  /// No description provided for @toolsAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} tool(s) available'**
  String toolsAvailable(int count);

  /// No description provided for @connectionSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Connection successful'**
  String get connectionSuccessful;

  /// No description provided for @connectionFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailedTitle;

  /// No description provided for @connectionSuccessfulDetail.
  ///
  /// In en, this message translates to:
  /// **'Connected successfully. Found {count} tool(s).'**
  String connectionSuccessfulDetail(int count);

  /// No description provided for @deleteMcpConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteMcpConfigTitle(String name);

  /// No description provided for @deleteMcpConfigDescription.
  ///
  /// In en, this message translates to:
  /// **'This MCP server will be removed.'**
  String get deleteMcpConfigDescription;

  /// No description provided for @addMcpServer.
  ///
  /// In en, this message translates to:
  /// **'Add MCP Server'**
  String get addMcpServer;

  /// No description provided for @editMcpServer.
  ///
  /// In en, this message translates to:
  /// **'Edit MCP Server'**
  String get editMcpServer;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @endpointUrl.
  ///
  /// In en, this message translates to:
  /// **'Endpoint URL'**
  String get endpointUrl;

  /// No description provided for @endpointUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://mcp.example.com/mcp'**
  String get endpointUrlHint;

  /// No description provided for @command.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get command;

  /// No description provided for @argumentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Arguments (space-separated)'**
  String get argumentsLabel;

  /// No description provided for @argumentsHint.
  ///
  /// In en, this message translates to:
  /// **'-y @modelcontextprotocol/server-name'**
  String get argumentsHint;

  /// No description provided for @authorizationHeader.
  ///
  /// In en, this message translates to:
  /// **'Authorization header (optional)'**
  String get authorizationHeader;

  /// No description provided for @mcpEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get mcpEnabled;

  /// No description provided for @mcpEnabledDescription.
  ///
  /// In en, this message translates to:
  /// **'Agent can use this server'**
  String get mcpEnabledDescription;

  /// No description provided for @mcpAutoConnect.
  ///
  /// In en, this message translates to:
  /// **'Auto-connect'**
  String get mcpAutoConnect;

  /// No description provided for @mcpAutoConnectDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect when workspace opens'**
  String get mcpAutoConnectDescription;

  /// No description provided for @noProviderConfiguredHint.
  ///
  /// In en, this message translates to:
  /// **'No provider is configured yet, so the agent uses a built-in mock that demonstrates the loop without any network. Add an OpenAI-compatible provider to use a real model.'**
  String get noProviderConfiguredHint;

  /// No description provided for @providerLabelHint.
  ///
  /// In en, this message translates to:
  /// **'DeepSeek (personal)'**
  String get providerLabelHint;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get statusReady;

  /// No description provided for @statusParsing.
  ///
  /// In en, this message translates to:
  /// **'Parsing'**
  String get statusParsing;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @statusOcrRequired.
  ///
  /// In en, this message translates to:
  /// **'OCR needed'**
  String get statusOcrRequired;

  /// No description provided for @noOutput.
  ///
  /// In en, this message translates to:
  /// **'(no output)'**
  String get noOutput;

  /// No description provided for @modelHint.
  ///
  /// In en, this message translates to:
  /// **'gpt-4o-mini / deepseek-chat'**
  String get modelHint;

  /// No description provided for @copyDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Copy diagnostics'**
  String get copyDiagnostics;

  /// No description provided for @diagnosticsCopied.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics copied to clipboard'**
  String get diagnosticsCopied;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @quickOpen.
  ///
  /// In en, this message translates to:
  /// **'Quick open'**
  String get quickOpen;

  /// No description provided for @searchFiles.
  ///
  /// In en, this message translates to:
  /// **'Search files'**
  String get searchFiles;

  /// No description provided for @noFiles.
  ///
  /// In en, this message translates to:
  /// **'No files found'**
  String get noFiles;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
