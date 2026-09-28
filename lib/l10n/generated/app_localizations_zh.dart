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
  String get redo => '重做';

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
  String get exampleAnalyze => '分析这个项目并总结其架构。';

  @override
  String get exampleConfiguration => '找出应用读取配置的位置并解释其工作方式。';

  @override
  String get examplePerformance => '为什么启动速度很慢？请调查并提出修复方案。';

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
  String get workspacePathHelper => '智能体将读取和编辑的绝对路径。';

  @override
  String get workspaceRequiredFields => '名称和路径不能为空。';

  @override
  String get selectWorkspace => '选择工作区';

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
  String get fileSaved => '文件已保存';

  @override
  String failedToSave(Object error) {
    return '保存失败：$error';
  }

  @override
  String get fileChangedTitle => '磁盘文件已发生变化';

  @override
  String get fileChangedDescription =>
      '智能体或其他程序在文件打开后修改了它。请选择重新加载磁盘版本，或使用当前编辑内容覆盖。';

  @override
  String get reload => '重新加载';

  @override
  String get overwrite => '覆盖';

  @override
  String get unsavedChangesTitle => '放弃未保存的修改？';

  @override
  String get unsavedChangesDescription => '当前编辑内容尚未保存。';

  @override
  String get discard => '丢弃';

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
  String get requiredField => '必填';

  @override
  String get maxTokens => '最大输出 Token';

  @override
  String get loading => '加载中…';

  @override
  String get unavailable => '不可用';

  @override
  String get workspace => '工作区';

  @override
  String get directory => '目录';

  @override
  String get none => '无';

  @override
  String get resolving => '正在解析…';

  @override
  String get shell => 'Shell';

  @override
  String get termux => 'Termux';

  @override
  String get termuxDescription =>
      '在 Android 上，配置完成后智能体会通过 Termux 执行命令，否则使用系统 Shell。';

  @override
  String get waitingForAnswer => '等待授权结果…';

  @override
  String get grantTermuxAccess => '授予 Termux 权限';

  @override
  String get mvpBuild => 'MVP 版本';

  @override
  String get demo => '演示';

  @override
  String get activeOfflineDemo => '当前：离线演示';

  @override
  String activeProvider(String name) {
    return '当前：$name';
  }

  @override
  String get termuxExternalAppsHint =>
      'Termux 还需要在 termux.properties 中设置 allow-external-apps=true 才能接收命令。';

  @override
  String get termuxPermissionHint => '请授予“在 Termux 环境中运行命令”权限，以便智能体使用其中的工具链。';

  @override
  String get aboutDescription =>
      '运行在设备上的 AI 智能体工作台，可读取和编辑代码、执行命令并操作 Git；进行风险操作前会请求确认。';

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
  String get phaseIdle => '空闲';

  @override
  String get phaseThinking => '思考中';

  @override
  String get phasePlanning => '规划中';

  @override
  String get phaseWaitingApproval => '等待批准';

  @override
  String get phaseExecuting => '执行中';

  @override
  String get phaseObserving => '分析结果中';

  @override
  String get phaseRecovering => '恢复中';

  @override
  String get phaseCompleted => '已完成';

  @override
  String get phaseError => '错误';

  @override
  String get phaseCancelled => '已取消';

  @override
  String callingTools(String tools) {
    return '正在调用 $tools';
  }

  @override
  String get deniedByUser => '用户已拒绝';

  @override
  String get done => '完成';

  @override
  String get search => '查找';

  @override
  String get replace => '替换';

  @override
  String get replaceAll => '全部替换';

  @override
  String get previousMatch => '上一个匹配';

  @override
  String get nextMatch => '下一个匹配';

  @override
  String get close => '关闭';

  @override
  String get noMatches => '0 个结果';

  @override
  String matchPosition(int current, int total) {
    return '$current/$total';
  }

  @override
  String replacedOccurrences(int count) {
    return '已替换 $count 处';
  }

  @override
  String get goToLine => '跳转到行';

  @override
  String get lineNumber => '行号';

  @override
  String lineRange(int count) {
    return '1–$count';
  }

  @override
  String get go => '跳转';

  @override
  String get invalidLineNumber => '行号超出当前文件范围';

  @override
  String get newFile => '新建文件';

  @override
  String get newFolder => '新建文件夹';

  @override
  String get name => '名称';

  @override
  String get edit => '编辑';

  @override
  String get rename => '重命名';

  @override
  String get invalidFileName => '请输入不包含 / 或 \\ 的有效名称';

  @override
  String get entryAlreadyExists => '已存在同名文件或文件夹。';

  @override
  String fileOperationFailed(Object error) {
    return '文件操作失败：$error';
  }

  @override
  String deleteEntryTitle(String name) {
    return '删除“$name”？';
  }

  @override
  String get deleteFileDescription => '此文件将被永久删除。';

  @override
  String get deleteFolderDescription => '此文件夹及其中的所有内容将被永久删除。';

  @override
  String get draftRestored => '已恢复上次未保存的草稿。';

  @override
  String fileTooLarge(String size, String limit) {
    return '文件太大无法编辑（$size）。最大大小为 $limit。';
  }

  @override
  String get binaryFileNotSupported => '此文件似乎是二进制文件，无法编辑。';

  @override
  String get import => '导入';

  @override
  String get importing => '导入中…';

  @override
  String importFailed(Object error) {
    return '导入失败：$error';
  }

  @override
  String get selectWorkspaceFirst => '请先选择一个工作区。';

  @override
  String get noImportedDocuments => '尚未导入任何文档。';

  @override
  String get importDocumentHint => '导入 PDF 或 EPUB 以开始使用。';

  @override
  String get deleteDocumentTitle => '删除文档？';

  @override
  String deleteDocumentDescription(String name) {
    return '删除 \"$name\" 及所有已提取的文本？';
  }

  @override
  String get reader => '阅读器';

  @override
  String get documentNotFound => '文档未找到。';

  @override
  String get unknownError => '未知错误';

  @override
  String get tableOfContents => '目录';

  @override
  String get noExtractedText => '无可提取的文本。';

  @override
  String get askAgentAboutSection => '向智能体询问此章节';

  @override
  String get askAboutThisSection => '询问此章节';

  @override
  String get sendSectionToAgent => '将章节文本发送给智能体';

  @override
  String get explainThisSection => '请解释此章节。';

  @override
  String get summarizeThisSection => '总结此章节';

  @override
  String get summarizeSectionConcisely => '请简明扼要地总结此章节。';

  @override
  String get extractKeyConcepts => '提取关键概念';

  @override
  String get extractKeyConceptsDescription => '提取此章节中的关键概念和术语。';

  @override
  String pageIndicator(int current, int total) {
    return '$current / $total';
  }

  @override
  String sectionsCount(int count) {
    return '$count 个章节';
  }

  @override
  String get terminalHint => '在下方输入命令。\n试试：ls, pwd, git status, cat README.md';

  @override
  String get running => '（运行中…）';

  @override
  String get timedOut => '（超时）';

  @override
  String exitCode(int code) {
    return '（退出码 $code）';
  }

  @override
  String finishedIn(String elapsed) {
    return '（耗时 $elapsed）';
  }

  @override
  String runtimeLabel(String id) {
    return '运行环境：$id';
  }

  @override
  String get selectRuntime => '选择运行环境';

  @override
  String get runOnThisDevice => '在本设备运行';

  @override
  String get workspaceNameHint => '我的项目';

  @override
  String deleteSessionTitle(String title) {
    return '删除“$title”？';
  }

  @override
  String get deleteSessionDescription => '此会话及其消息将被永久删除。';

  @override
  String get noExtractableText => '（此章节无可提取的文本。）';

  @override
  String cannotListFolder(Object error) {
    return '无法列出文件夹：$error';
  }

  @override
  String fileTooLargeToPreview(String name, String size) {
    return '$name 太大无法预览（$size）。';
  }
}
