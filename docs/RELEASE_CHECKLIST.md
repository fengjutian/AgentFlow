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

## Xiaomi / mainland China build

Provide the legal identity at build time and generate a signed APK:

```text
flutter build apk --release \
  --dart-define=AGENTFLOW_SUPPORT_EMAIL=support@example.com \
  --dart-define=AGENTFLOW_PRIVACY_POLICY_URL=https://example.com/privacy \
  --dart-define=AGENTFLOW_APP_FILING_NUMBER=京ICP备XXXXXXXX号-XA
```

- [ ] The app name, package name, software copyright certificate, ICP filing,
      APP filing, and Xiaomi developer entity match.
- [ ] The About page shows the real APP filing number and opens the MIIT query.
- [ ] First launch displays the privacy notice before workspace/network setup.
- [ ] Upload the signed APK (not AAB) to Xiaomi.
