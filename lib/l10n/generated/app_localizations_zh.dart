// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'AgentFlow';

  @override
  String get agent => '智能体';

  @override
  String get files => '文件';

  @override
  String get terminal => '终端';

  @override
  String get settings => '设置';

  @override
  String get sessions => '会话';

  @override
  String get newSession => '新建会话';

  @override
  String get newLabel => '新建';

  @override
  String get clear => '清空';

  @override
  String get refresh => '刷新';

  @override
  String get retry => '重试';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get create => '创建';

  @override
  String get save => '保存';

  @override
  String get undo => '撤销';

  @override
  String get send => '发送';

  @override
  String get stop => '停止';

  @override
  String get run => '运行';

  @override
  String get lastCommand => '上一条命令';

  @override
  String get commandHint => '输入命令';

  @override
  String failedToLoad(Object error) {
    return '加载失败：$error';
  }

  @override
  String get notFound => '页面不存在';

  @override
  String noRouteFor(String uri) {
    return '没有与 $uri 匹配的页面';
  }

  @override
  String get noWorkspaceSelected => '尚未选择工作区';

  @override
  String get workspaceRequiredDescription =>
      '工作区是智能体读取和编辑的项目目录。请选择已有工作区或新建一个工作区。';

  @override
  String get selectOrCreateWorkspace => '选择或创建工作区';

  @override
  String get giveAgentTask => '给智能体一个任务';

  @override
  String get agentTaskDescription => '它可以读取文件、搜索代码、提出修改并执行命令；进行风险操作前会请求确认。';

  @override
  String get describeTask => '描述一个任务…';

  @override
  String get noSessions => '暂无会话，请发送任务开始使用。';

  @override
  String get justNow => '刚刚';

  @override
  String minutesAgo(int count) {
    return '$count 分钟前';
  }

  @override
  String hoursAgo(int count) {
    return '$count 小时前';
  }

  @override
  String daysAgo(int count) {
    return '$count 天前';
  }

  @override
  String get workspaces => '工作区';

  @override
  String get noWorkspaces => '暂无工作区，请新建一个工作区。';

  @override
  String get newWorkspace => '新建工作区';

  @override
  String deleteWorkspaceTitle(String name) {
    return '删除“$name”？';
  }

  @override
  String get deleteWorkspaceDescription => '这会删除工作区及其本地会话记录，但不会删除项目文件。';

  @override
  String get workspaceName => '名称';

  @override
  String get workspacePath => '项目路径';

  @override
  String get selectWorkspaceForFiles => '请选择工作区以浏览文件。';

  @override
  String get runtimeUnavailable => '当前工作区的运行环境不可用。';

  @override
  String get emptyFolder => '此文件夹为空。';

  @override
  String get parentFolder => '上级文件夹';

  @override
  String cannotOpen(Object error) {
    return '无法打开：$error';
  }

  @override
  String get emptyFile => '（空文件）';

  @override
  String get selectWorkspaceForTerminal => '请选择工作区以在其目录中打开终端。';

  @override
  String get modelProviders => '模型服务';

  @override
  String get provider => '服务商';

  @override
  String get runtime => '运行环境';

  @override
  String get about => '关于';

  @override
  String get offlineDemoMode => '正在使用离线演示模式';

  @override
  String get setAsDefault => '设为默认';

  @override
  String deleteProviderTitle(String name) {
    return '删除“$name”？';
  }

  @override
  String get deleteProviderDescription => '这会删除模型服务配置及其安全存储的凭据。';

  @override
  String get addProvider => '添加模型服务';

  @override
  String get editProvider => '编辑模型服务';

  @override
  String get providerType => '服务商类型';

  @override
  String get providerLabel => '名称';

  @override
  String get model => '模型';

  @override
  String get baseUrl => '接口地址';

  @override
  String get apiKey => 'API Key';

  @override
  String temperatureValue(String value) {
    return '温度：$value';
  }

  @override
  String get approveAction => '批准此操作';

  @override
  String get confirmHighRisk => '确认高风险操作';

  @override
  String get deny => '拒绝';

  @override
  String get reject => '拒绝修改';

  @override
  String get allow => '允许';

  @override
  String get accept => '接受修改';

  @override
  String get alwaysAllow => '始终允许';

  @override
  String get acceptAll => '全部接受';

  @override
  String get riskAuto => '自动';

  @override
  String get riskConfirm => '需确认';

  @override
  String get riskHigh => '高风险';

  @override
  String get agentActivity => '智能体活动';

  @override
  String callingTools(String tools) {
    return '正在调用 $tools';
  }

  @override
  String get deniedByUser => '用户已拒绝';

  @override
  String get done => '完成';
}
