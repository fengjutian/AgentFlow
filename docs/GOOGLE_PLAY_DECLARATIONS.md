# Google Play declaration worksheet

This is a submission aid, not a substitute for answering Play Console based on
the final production build and published privacy policy.

## Data safety

Current architecture does not send data to an AgentFlow-operated backend.
However, user-selected model and MCP providers receive data directly from the
app. In Play Console, disclose transfers according to Google's current Data
Safety definitions and the behavior of every provider included or configured in
the production release.

Review at minimum:

- App interactions: prompts and conversations sent to model providers.
- Files and documents: excerpts sent when the user asks the model to analyze
  them.
- Authentication information: provider/MCP credentials are stored locally and
  sent only to authenticate with the selected service.
- Diagnostics: declare only if a crash or analytics SDK is added later.

Security statements supported by the current code:

- Data is encrypted in transit when an HTTPS endpoint is used.
- Secrets use platform secure storage.
- Users can delete local workspace/session/configuration data in the app.

Do not claim that all network data is encrypted in transit if arbitrary HTTP MCP
or model endpoints are enabled in the release.

## Foreground service: `specialUse`

Suggested description:

> AgentFlow starts a foreground service only while a user-initiated agent shell
> command is running. The persistent notification makes the execution visible
> and returns the user to the task. Immediate execution is required for
> interactive builds and tests; deferral or interruption can invalidate the
> command result and leave the task incomplete. The service stops when the
> command finishes.

The required review video should show:

1. The user starting an agent task or terminal command.
2. The approval step for the command.
3. The visible foreground notification while the app is backgrounded.
4. Returning to AgentFlow and seeing the result.
5. The notification disappearing after completion.

## App access

The app has no AgentFlow account. Provide a reviewer with a mock/offline path or
test model credentials if core review flows otherwise require a paid third-party
API. Never put production secrets in review instructions.

## Ads and content

- Ads: none in the current source.
- Account creation: none in the current source; Google's account-deletion URL
  requirement does not apply unless accounts are added.
- Target audience: developers/adults; complete the questionnaire consistently.
- Content rating: disclose unrestricted AI-generated content and code/terminal
  execution accurately.
