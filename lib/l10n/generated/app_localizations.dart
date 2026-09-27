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
  /// **'command'**
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
