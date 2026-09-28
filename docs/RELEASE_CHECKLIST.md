# Release checklist

## One-time decisions

- [ ] Confirm ownership of `com.agentflow.agentflow` before creating the store app.
- [ ] Replace `SUPPORT_EMAIL` and publish `PRIVACY_POLICY.md` over HTTPS.
- [ ] Create the Play Console app and enroll in Play App Signing.
- [ ] Generate and back up a dedicated upload keystore.
- [ ] Copy `android/key.properties.example` to `android/key.properties` and fill it.

Example key generation (run outside the repository or use a path ignored by Git):

```text
keytool -genkeypair -v -keystore upload-keystore.jks -keyalg RSA -keysize 4096 \
  -validity 10000 -alias upload
```

## Every release

- [ ] Remove all `TODO`, `CHANGE_ME`, `SUPPORT_EMAIL`, and `TODO_HTTPS_URL` markers.
- [ ] Increment `version` in `pubspec.yaml`.
- [ ] Run `dart format --output=none --set-exit-if-changed lib test`.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Run `flutter build appbundle --release`.
- [ ] Confirm the AAB is release-signed with the expected upload certificate.
- [ ] Test the release build on phone and tablet across supported Android versions.
- [ ] Test notifications, background commands, cancellation, workspace deletion,
      provider errors, SSH host-key rejection, and MCP disconnect behavior.
- [ ] Review the merged manifest and Play pre-launch/security reports.
- [ ] Update Data Safety and foreground-service declarations when behavior changes.
- [ ] Upload to Internal testing, then Closed testing, before Production.
