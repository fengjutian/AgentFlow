# AgentFlow MVP-3 / MVP-4 开发计划

本文档覆盖三个后续模块：PDF/EPUB 文档 Agent、MCP 接入、SSH Remote Runtime。

## 1. 目标架构

```text
                    AgentEngine
                         |
                    ToolRegistry
         +---------------+----------------+
         |               |                |
  Document Tools      MCP Tools       Existing Tools
         |               |
  DocumentService     McpClient
                         |
                  HTTP / stdio transport
                         |
             Local / Termux / SSH Runtime
```

三个模块继续复用现有 `AgentTool`、`ToolRegistry`、`Runtime`、Riverpod、Drift
和 `SecretStore`，不让 UI 直接调用底层运行环境。

## 2. 实施顺序

1. 公共基础：数据库迁移、运行时配置、动态工具注册、连接状态。
2. 文档 Agent：导入、解析、索引、阅读器和 Agent 工具。
3. MCP HTTP：协议、连接管理、工具发现和动态注册。
4. SSH Runtime：认证、Host Key、命令执行和 SFTP。
5. 长进程会话：stdio MCP、终端流式输出和 MCP over SSH。
6. 跨模块联调、安全审计和端到端测试。

## 3. 公共基础

### F-01 数据库与迁移

- 数据库升级到 schema 2，并保留 schema 1 数据。
- 新增 `runtime_configs`、`documents`、`document_sections` 和 `mcp_servers`。
- 密码、令牌、私钥和私钥口令只写入 `SecretStore`。
- 为升级、全新建库和级联删除增加测试。

### F-02 Runtime 配置

- 将运行时类型和运行时实例分开。
- Workspace 的 `runtimeId` 指向一个运行时配置；`local`、`termux` 继续作为内置 ID。
- 配置支持 local、termux、ssh，后续可扩展 docker。
- Settings 提供新增、编辑、测试连接、删除和设为默认。

### F-03 动态工具注册

- Workspace Registry 合并内置工具、文档工具和已连接的 MCP 工具。
- MCP 工具采用 `mcp_<serverId>_<toolName>` 命名，不能覆盖内置工具。
- Workspace 切换或 MCP 工具列表变化时重建 Registry。
- 工具风险默认为 `confirm`，只读工具经可信配置后才使用 `auto`。

## 4. PDF / EPUB 文档 Agent

### 4.1 MVP 范围

- 导入本地 PDF 和 EPUB。
- 提取元数据、PDF 页文本、EPUB 目录和章节文本。
- 保存解析状态、页面/章节定位信息和阅读位置。
- 提供文档库、PDF 页面阅读和 EPUB 章节阅读。
- 提供 `list_documents`、`get_document_info`、`read_document_section`、
  `search_document` 四个只读 Agent 工具。
- 回答必须携带页码或章节来源。

首版不做扫描 PDF OCR、DRM EPUB、复杂表格恢复和向量数据库。没有文本层的
PDF 必须明确标记为 `ocrRequired`，不能静默返回空内容。

### 4.2 模块

```text
lib/core/document/
  document.dart
  document_parser.dart
  document_service.dart
  document_context_builder.dart
lib/storage/document_repository.dart
lib/tools/document/
lib/ui/reader/
```

### 4.3 任务

- DOC-01：文件选择、缓存、hash 去重和导入进度。
- DOC-02：统一 `DocumentParser` 接口。
- DOC-03：PDF 元数据、页面渲染和文本层提取。
- DOC-04：EPUB container、OPF、manifest、spine、TOC 和 XHTML 解析。
- DOC-05：页面/章节持久化以及 SQLite FTS 文本搜索。
- DOC-06：四个文档工具及结果长度限制。
- DOC-07：文档库、阅读器、目录导航和阅读位置。
- DOC-08：“询问当前页”“总结本章”“提取关键概念”。
- DOC-09：解析、搜索、上下文裁剪和端到端测试。

### 4.4 验收

- 重启后仍能打开已导入文档。
- Agent 能先搜索，再读取命中页面/章节，并给出来源。
- 大文档不会一次性进入模型上下文。
- 损坏、加密或无文本层的文档显示明确错误。

## 5. MCP 接入

### 5.1 第一阶段：HTTP MCP

- JSON-RPC 请求、响应、通知、超时和取消。
- initialize、initialized、tools/list、tools/call。
- Streamable HTTP transport。
- Server 配置、连接测试、自动连接和错误诊断。
- MCP Tool 到 `AgentTool` 的动态适配。
- Bearer Token 和敏感 Header 使用 `SecretStore`。

### 5.2 第二阶段：stdio MCP

现有 `Runtime.execute` 是一次性命令，不足以承载双向长连接。需要增加：

```dart
abstract class ProcessSession {
  Stream<String> get stdout;
  Stream<String> get stderr;
  Future<void> writeStdin(String data);
  Future<int> waitForExit();
  Future<void> terminate();
}
```

Local、Android Bridge 和 SSH 分别实现进程会话。Android 使用 MethodChannel
管理进程，EventChannel 传递 stdout、stderr 和 exit 事件。

### 5.3 任务

- MCP-01：JSON-RPC 数据模型和请求关联。
- MCP-02：HTTP transport 与初始化握手。
- MCP-03：Server Repository 和安全凭据。
- MCP-04：tools/list 动态注册与命名冲突处理。
- MCP-05：tools/call 内容映射、截断和错误映射。
- MCP-06：设置页、Server 编辑器、工具列表和风险配置。
- MCP-07：断线、重连、工具列表变化和 Workspace 隔离。
- MCP-08：长进程 Runtime 接口。
- MCP-09：stdio transport 和 MCP over SSH。
- MCP-10：假 MCP Server 集成测试。

### 5.4 安全与验收

- 默认只允许 HTTPS，HTTP 必须显式确认。
- 日志不得包含 Authorization、Cookie、密码或私钥。
- 外部工具默认需要审批，Server 内容不能绕过审批策略。
- 限制响应大小、连接数和调用超时。
- Server 断线后工具立即不可用，重连后自动恢复。

## 6. SSH Remote Runtime

### 6.1 MVP 范围

- 主机、端口、用户名、密码或私钥认证。
- 首次连接显示 Host Key 指纹，后续变化时阻止连接。
- SSH exec 执行命令并返回 stdout、stderr、exit code 和 timeout。
- SFTP 实现读、写、删除、exists 和 list。
- Workspace 绑定 SSH 配置和远程根目录。
- 连接复用、空闲关闭、网络中断和有限重连。

首版不做跳板机、Agent forwarding、端口转发、rsync 和 Docker over SSH。

### 6.2 模块

```text
lib/runtime/ssh/
  ssh_runtime.dart
  ssh_connection.dart
  ssh_connection_pool.dart
  ssh_process_session.dart
  ssh_host_key_store.dart
lib/storage/runtime_config_repository.dart
lib/ui/settings/runtime/
```

### 6.3 任务

- SSH-01：SSH 配置模型、Repository 和 SecretStore key 约定。
- SSH-02：连接测试、认证错误和超时映射。
- SSH-03：Host Key 首次确认、持久化和变化拒绝。
- SSH-04：`SshRuntime.execute`。
- SSH-05：SFTP 文件操作；写文件采用临时文件加原子 rename。
- SSH-06：Runtime Resolver 按 Workspace 配置选择运行时。
- SSH-07：设置 UI 和 Workspace Runtime 选择。
- SSH-08：连接池、生命周期和网络切换。
- SSH-09：远程长进程会话，为 stdio MCP 和流式终端提供基础。
- SSH-10：测试服务器集成测试。

### 6.4 安全与验收

- 私钥、密码和口令不进入 SQLite、日志或模型上下文。
- 文件工具不能逃逸远程 Workspace 根目录。
- 审批卡显示 `user@host` 和远程工作目录。
- Agent 可以读取远程代码、预览修改、批准写入并运行测试。

## 7. 里程碑

| 迭代 | 交付内容 |
| --- | --- |
| Sprint 0 | schema 2、RuntimeConfig、动态 Registry |
| Sprint 1 | PDF/EPUB 导入、解析和持久化 |
| Sprint 2 | 文档工具、搜索、Reader UI |
| Sprint 3 | HTTP MCP 与动态工具 |
| Sprint 4 | SSH 配置、Host Key 和连接测试 |
| Sprint 5 | SSH exec、SFTP 和 Workspace 绑定 |
| Sprint 6 | 长进程 Bridge、stdio MCP、MCP over SSH |
| Sprint 7 | 安全、稳定性、端到端测试和发布文档 |

## 8. 最终验收路径

1. 导入 EPUB，搜索概念，读取命中章节并生成带章节引用的总结。
2. 添加 HTTP MCP Server，发现并启用工具，Agent 完成一次工具调用。
3. 添加 SSH 主机并确认 Host Key，绑定远程项目，修改文件并运行测试。
4. 在 SSH Runtime 上启动 stdio MCP Server，断线重连后工具恢复。

