import 'package:flutter/material.dart';

/// Offline copy of the privacy policy shown before a network-hosted policy is
/// available. Keep this text aligned with the public URL used in store listings.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    return Scaffold(
      appBar: AppBar(title: Text(zh ? '隐私政策' : 'Privacy Policy')),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Text(
              zh ? 'AgentFlow 隐私政策' : 'AgentFlow Privacy Policy',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(zh ? '生效日期：2026年9月28日' : 'Effective: September 28, 2026'),
            const SizedBox(height: 20),
            _Section(
              title: zh ? '概述' : 'Overview',
              body: zh
                  ? 'AgentFlow 是本地优先的 AI 工作区。工作区、会话、文档索引和配置默认保存在你的设备上。开发者不运营用于收集这些内容的 AgentFlow 云端服务器。'
                  : 'AgentFlow is a local-first AI workspace. Workspaces, conversations, document indexes, and settings are stored on your device by default. The developer does not operate an AgentFlow cloud service that collects this content.',
            ),
            _Section(
              title: zh ? '你提供的数据' : 'Data you provide',
              body: zh
                  ? '应用可能处理你选择的项目文件、文档、提示词、模型配置、SSH 配置和 MCP 配置。API 密钥、密码和私钥使用设备安全存储；其他应用数据保存在本地数据库或应用目录。'
                  : 'The app may process project files, documents, prompts, model settings, SSH settings, and MCP settings that you choose. API keys, passwords, and private keys use device secure storage; other app data is stored in the local database or app directory.',
            ),
            _Section(
              title: zh ? '第三方服务' : 'Third-party services',
              body: zh
                  ? '当你配置并使用模型提供商、SSH 主机或 MCP 服务器时，应用会把完成请求所需的数据发送给你选择的服务。接收内容可能包括提示词、相关文件片段、工具参数和工具结果。相关服务依据其各自隐私政策处理数据；请勿向不受信任的服务发送敏感内容。'
                  : 'When you configure and use a model provider, SSH host, or MCP server, the app sends data needed to complete your request to that service. This may include prompts, relevant file excerpts, tool arguments, and tool results. Those services process data under their own privacy policies. Do not send sensitive content to services you do not trust.',
            ),
            _Section(
              title: zh ? '权限' : 'Permissions',
              body: zh
                  ? '网络权限用于连接你配置的服务；通知和前台服务用于显示正在执行的长任务；Termux 权限仅在你选择使用 Termux 运行命令时使用。'
                  : 'Network access connects to services you configure. Notifications and a foreground service show long-running tasks. The Termux permission is used only when you choose Termux to run commands.',
            ),
            _Section(
              title: zh ? '保留与删除' : 'Retention and deletion',
              body: zh
                  ? '你可以在应用内删除工作区、会话、连接和模型配置。卸载应用会删除其本地应用数据，但不会删除你选择的外部项目文件、远程主机数据，或第三方服务已经收到的数据。第三方数据删除请求应提交给对应服务提供商。'
                  : 'You can delete workspaces, conversations, connections, and model settings in the app. Uninstalling removes local app data, but does not delete external project files, remote-host data, or data already received by third-party services. Send third-party deletion requests to the relevant provider.',
            ),
            _Section(
              title: zh ? '儿童隐私' : "Children's privacy",
              body: zh
                  ? 'AgentFlow 面向开发者，不面向儿童，也不会在明知的情况下收集儿童个人信息。'
                  : 'AgentFlow is intended for developers, not children, and does not knowingly collect children’s personal information.',
            ),
            _Section(
              title: zh ? '联系与变更' : 'Contact and changes',
              body: zh
                  ? '发布前请在此处及公开网页中填入开发者支持邮箱。政策发生重大变化时，将通过应用更新或公开政策页面说明。'
                  : 'Before release, add the developer support email here and on the public policy page. Material changes will be announced through an app update or the public policy page.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(body),
          ],
        ),
      );
}
