# AgentFlow Privacy Policy

Effective date: September 28, 2026

> Release blocker: replace `SUPPORT_EMAIL` below and publish this document at
> a stable public HTTPS URL before submitting the app to a store.

AgentFlow is a local-first AI workspace. Workspaces, conversations, document
indexes, and settings are stored on the user's device by default. The developer
does not operate an AgentFlow cloud service that collects this content.

## Data processed

AgentFlow may process project files, documents, prompts, model settings, SSH
settings, and MCP settings selected by the user. API keys, passwords, and
private keys use device secure storage. Other app data is stored in the local
database or app directory.

## Third-party services

When a user configures and uses a model provider, SSH host, or MCP server,
AgentFlow sends data needed to complete the request to that user-selected
service. This may include prompts, relevant file excerpts, tool arguments, and
tool results. Those services process data under their own terms and privacy
policies. Users should not send sensitive content to services they do not trust.

## Permissions

- Network access connects to services configured by the user.
- Notifications and a foreground service display user-initiated, long-running
  agent commands.
- The Termux command permission is used only when the user chooses Termux as a
  runtime.

## Retention and deletion

Users can delete workspaces, conversations, connections, and model settings in
the app. Uninstalling removes local app data, but does not delete external
project files, remote-host data, or data already received by third-party
services. Requests concerning third-party data must be sent to that provider.

## Children's privacy

AgentFlow is intended for developers, not children, and does not knowingly
collect children's personal information.

## Contact and changes

Contact: `SUPPORT_EMAIL`

Material changes will be announced through an app update or the public version
of this policy.
