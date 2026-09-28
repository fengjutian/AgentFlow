import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'privacy_policy_page.dart';

class PrivacyConsentPage extends StatelessWidget {
  const PrivacyConsentPage({super.key, required this.onAgree});

  final Future<void> Function() onAgree;

  @override
  Widget build(BuildContext context) {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Icon(Icons.privacy_tip_outlined, size: 52),
                  const SizedBox(height: 20),
                  Text(
                    zh ? '隐私保护说明' : 'Privacy notice',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        zh
                            ? 'AgentFlow 采用本地优先设计。工作区、会话、文档索引和配置默认保存在本机。\n\n'
                                  '只有当你主动配置并使用模型提供商、SSH 主机或 MCP 服务时，完成请求所需的提示词、相关文件片段、工具参数及结果才会发送到你选择的第三方服务。API 密钥、密码和私钥使用设备安全存储。\n\n'
                                  '网络权限用于连接你选择的服务；通知和前台服务用于展示你主动发起的长任务；Termux 权限仅在你选择 Termux 运行命令时使用。相关权限会在具体功能需要时另行申请。\n\n'
                                  '点击“同意并继续”表示你已阅读并同意隐私政策。你可以在设置中再次查看政策。'
                            : 'AgentFlow is local-first. Workspaces, conversations, document indexes, and settings are stored on this device by default.\n\n'
                                  'Only when you configure and use a model provider, SSH host, or MCP service does the app send prompts, relevant file excerpts, tool arguments, and results needed for your request to that selected third party. API keys, passwords, and private keys use device secure storage.\n\n'
                                  'Network access connects to services you select. Notifications and a foreground service show user-initiated long-running tasks. The Termux permission is used only when you choose Termux. Permissions are requested in context.\n\n'
                                  'By selecting “Agree and continue”, you confirm that you have read and accepted the Privacy Policy.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PrivacyPolicyPage(),
                      ),
                    ),
                    child: Text(zh ? '查看完整隐私政策' : 'Read full Privacy Policy'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: onAgree,
                    child: Text(zh ? '同意并继续' : 'Agree and continue'),
                  ),
                  TextButton(
                    onPressed: SystemNavigator.pop,
                    child: Text(zh ? '不同意并退出' : 'Decline and exit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
