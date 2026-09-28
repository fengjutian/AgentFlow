/// Release-time legal identity shown in the app and privacy policy.
///
/// Supply values with `--dart-define` for production builds. Keeping them out
/// of source avoids publishing guessed or stale regulatory information.
abstract final class LegalConfig {
  static const String supportEmail = String.fromEnvironment(
    'AGENTFLOW_SUPPORT_EMAIL',
  );
  static const String privacyPolicyUrl = String.fromEnvironment(
    'AGENTFLOW_PRIVACY_POLICY_URL',
  );
  static const String appFilingNumber = String.fromEnvironment(
    'AGENTFLOW_APP_FILING_NUMBER',
  );

  static const String appFilingQueryUrl = 'https://beian.miit.gov.cn/';
}
