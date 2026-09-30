/// Git status panel for the editor workspace.
///
/// Shows branch info, file status, recent commits, and quick actions.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../l10n/l10n.dart';

/// Parsed git status from `git status --porcelain -b`.
class GitStatus {
  const GitStatus({
    required this.branch,
    required this.upstream,
    required this.ahead,
    required this.behind,
    required this.staged,
    required this.modified,
    required this.untracked,
    required this.conflicts,
  });

  final String branch;
  final String upstream;
  final int ahead;
  final int behind;
  final List<String> staged;
  final List<String> modified;
  final List<String> untracked;
  final List<String> conflicts;

  bool get hasConflicts => conflicts.isNotEmpty;
  int get totalChanges => staged.length + modified.length + untracked.length;

  static GitStatus parse(String output) {
    var branch = '';
    var upstream = '';
    var ahead = 0;
    var behind = 0;
    final staged = <String>[];
    final modified = <String>[];
    final untracked = <String>[];
    final conflicts = <String>[];

    final lines = output.split('\n');
    for (final line in lines) {
      if (line.startsWith('## ')) {
        final branchLine = line.substring(3);
        final match = RegExp(r'^(\S+?)(?:\.\.\.(\S+))?(?:\s*\[(.+)\])?$').firstMatch(branchLine);
        if (match != null) {
          branch = match.group(1) ?? '';
          upstream = match.group(2) ?? '';
          final info = match.group(3) ?? '';
          final aheadMatch = RegExp(r'ahead (\d+)').firstMatch(info);
          final behindMatch = RegExp(r'behind (\d+)').firstMatch(info);
          ahead = aheadMatch != null ? int.parse(aheadMatch.group(1)!) : 0;
          behind = behindMatch != null ? int.parse(behindMatch.group(1)!) : 0;
        }
      } else if (line.length >= 2) {
        final xy = line.substring(0, 2);
        final path = line.substring(3);
        if (xy == 'UU' || xy == 'AA' || xy == 'DD') {
          conflicts.add(path);
        } else if (xy == '??') {
          untracked.add(path);
        } else if (xy[0] != ' ') {
          staged.add(path);
        } else if (xy[1] != ' ') {
          modified.add(path);
        }
      }
    }

    return GitStatus(
      branch: branch,
      upstream: upstream,
      ahead: ahead,
      behind: behind,
      staged: staged,
      modified: modified,
      untracked: untracked,
      conflicts: conflicts,
    );
  }
}

/// A commit entry from git log.
class GitCommit {
  const GitCommit({required this.hash, required this.subject});
  final String hash;
  final String subject;
}

/// Provider for git status - polls periodically.
final gitStatusProvider =
    NotifierProvider<GitStatusNotifier, AsyncValue<GitStatus?>>(GitStatusNotifier.new);

class GitStatusNotifier extends Notifier<AsyncValue<GitStatus?>> {
  Timer? _timer;

  @override
  AsyncValue<GitStatus?> build() {
    _startPolling();
    ref.onDispose(() => _timer?.cancel());
    return const AsyncValue.data(null);
  }

  void _startPolling() {
    _fetchStatus();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchStatus());
  }

  Future<void> refresh() => _fetchStatus();

  Future<void> _fetchStatus() async {
    try {
      final runtime = await ref.read(runtimeProvider.future);
      final workspace = ref.read(currentWorkspaceProvider);
      if (runtime == null || workspace == null) {
        state = const AsyncValue.data(null);
        return;
      }
      state = const AsyncValue.loading();
      final result = await runtime.execute(
        'git status --porcelain -b',
        workingDirectory: workspace.rootDirectory,
      );
      if (result.success) {
        state = AsyncValue.data(GitStatus.parse(result.stdout));
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for recent commits.
final gitLogProvider =
    NotifierProvider<GitLogNotifier, AsyncValue<List<GitCommit>>>(GitLogNotifier.new);

class GitLogNotifier extends Notifier<AsyncValue<List<GitCommit>>> {
  @override
  AsyncValue<List<GitCommit>> build() {
    _fetchLog();
    return const AsyncValue.loading();
  }

  Future<void> refresh() => _fetchLog();

  Future<void> _fetchLog() async {
    try {
      final runtime = await ref.read(runtimeProvider.future);
      final workspace = ref.read(currentWorkspaceProvider);
      if (runtime == null || workspace == null) {
        state = const AsyncValue.data([]);
        return;
      }
      state = const AsyncValue.loading();
      final result = await runtime.execute(
        'git log -20 --oneline --no-decorate',
        workingDirectory: workspace.rootDirectory,
      );
      if (result.success) {
        final commits = result.stdout
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .map((line) {
              final sep = line.indexOf(' ');
              return GitCommit(
                hash: sep < 0 ? line : line.substring(0, sep),
                subject: sep < 0 ? '' : line.substring(sep + 1),
              );
            })
            .toList();
        state = AsyncValue.data(commits);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for branch list.
final gitBranchListProvider =
    NotifierProvider<GitBranchListNotifier, AsyncValue<List<String>>>(GitBranchListNotifier.new);

class GitBranchListNotifier extends Notifier<AsyncValue<List<String>>> {
  @override
  AsyncValue<List<String>> build() {
    _fetchBranches();
    return const AsyncValue.loading();
  }

  Future<void> refresh() => _fetchBranches();

  Future<void> _fetchBranches() async {
    try {
      final runtime = await ref.read(runtimeProvider.future);
      final workspace = ref.read(currentWorkspaceProvider);
      if (runtime == null || workspace == null) {
        state = const AsyncValue.data([]);
        return;
      }
      state = const AsyncValue.loading();
      final result = await runtime.execute(
        'git branch --list --no-color',
        workingDirectory: workspace.rootDirectory,
      );
      if (result.success) {
        final branches = result.stdout
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .map((l) => l.replaceFirst(RegExp(r'^[\s*]+'), '').trim())
            .toList();
        state = AsyncValue.data(branches);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Git panel widget showing workspace git status.
class GitPanel extends ConsumerStatefulWidget {
  const GitPanel({super.key});

  @override
  ConsumerState<GitPanel> createState() => _GitPanelState();
}

class _GitPanelState extends ConsumerState<GitPanel> {
  bool _busy = false;

  Future<void> _runGitCommand(String command, {bool refresh = true}) async {
    setState(() => _busy = true);
    try {
      final runtime = await ref.read(runtimeProvider.future);
      final workspace = ref.read(currentWorkspaceProvider);
      if (runtime == null || workspace == null) return;

      final result = await runtime.execute(
        command,
        workingDirectory: workspace.rootDirectory,
      );

      if (!mounted) return;

      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Git error: ${result.stderr}')),
        );
      } else if (result.stdout.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.stdout.split('\n').first)),
        );
      }

      if (refresh) {
        ref.read(gitStatusProvider.notifier).refresh();
        ref.read(gitLogProvider.notifier).refresh();
        ref.read(gitBranchListProvider.notifier).refresh();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(gitStatusProvider);
    final logAsync = ref.watch(gitLogProvider);
    final branchesAsync = ref.watch(gitBranchListProvider);
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(Icons.source_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  context.l10n.gitStatus,
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _busy
                      ? null
                      : () {
                          ref.read(gitStatusProvider.notifier).refresh();
                          ref.read(gitLogProvider.notifier).refresh();
                        },
                  tooltip: context.l10n.refresh,
                ),
              ],
            ),
          ),

          Flexible(
            child: statusAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $e'),
              ),
              data: (status) {
                if (status == null) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Not a git repository')),
                  );
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BranchHeader(
                        status: status,
                        branches: branchesAsync.value ?? [],
                        onCheckout: (branch) => _runGitCommand('git checkout $branch'),
                        onCreateBranch: () => _showCreateBranchDialog(),
                      ),
                      const SizedBox(height: 16),

                      if (status.hasConflicts) ...[
                        _ConflictBanner(
                          count: status.conflicts.length,
                          onAbort: () => _runGitCommand('git merge --abort'),
                        ),
                        const SizedBox(height: 16),
                      ],

                      _QuickActions(
                        busy: _busy,
                        onFetch: () => _runGitCommand('git fetch'),
                        onPull: () => _runGitCommand('git pull'),
                        onPush: () => _showPushConfirm(),
                        onStash: () => _runGitCommand('git stash push -m "Auto stash"'),
                        onStashPop: () => _runGitCommand('git stash pop'),
                      ),
                      const SizedBox(height: 16),

                      _FileStatusSection(status: status),
                      const SizedBox(height: 16),

                      _CommitSection(
                        commits: logAsync.value ?? [],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateBranchDialog() {
    final controller = TextEditingController();
    showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.createBranch),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.l10n.branchName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx, controller.text);
            },
            child: Text(context.l10n.create),
          ),
        ],
      ),
    ).then((name) {
      if (name != null && name.isNotEmpty) {
        _runGitCommand('git checkout -b $name');
      }
    });
  }

  void _showPushConfirm() {
    final status = ref.read(gitStatusProvider).value;
    if (status == null) return;

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.pushToRemote),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${context.l10n.branch}: ${status.branch}'),
            if (status.ahead > 0)
              Text('${context.l10n.commitsToPush}: ${status.ahead}'),
            const SizedBox(height: 8),
            Text(
              context.l10n.pushWarning,
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.push),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _runGitCommand('git push');
      }
    });
  }
}

class _BranchHeader extends StatelessWidget {
  const _BranchHeader({
    required this.status,
    required this.branches,
    required this.onCheckout,
    required this.onCreateBranch,
  });

  final GitStatus status;
  final List<String> branches;
  final void Function(String) onCheckout;
  final VoidCallback onCreateBranch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fork_right, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status.branch.isEmpty ? 'detached' : status.branch,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.swap_horiz, size: 20),
                tooltip: context.l10n.switchBranch,
                onSelected: onCheckout,
                itemBuilder: (ctx) => branches
                    .where((b) => b != status.branch)
                    .map((b) => PopupMenuItem(value: b, child: Text(b)))
                    .toList(),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                tooltip: context.l10n.createBranch,
                onPressed: onCreateBranch,
              ),
            ],
          ),
          if (status.upstream.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${status.upstream} '
              '${status.ahead > 0 ? '↑${status.ahead}' : ''}'
              '${status.behind > 0 ? ' ↓${status.behind}' : ''}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _ConflictBanner extends StatelessWidget {
  const _ConflictBanner({required this.count, required this.onAbort});

  final int count;
  final VoidCallback onAbort;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count merge conflict(s) - resolve and commit',
              style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
            ),
          ),
          TextButton(
            onPressed: onAbort,
            child: Text(context.l10n.abort),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.busy,
    required this.onFetch,
    required this.onPull,
    required this.onPush,
    required this.onStash,
    required this.onStashPop,
  });

  final bool busy;
  final VoidCallback onFetch;
  final VoidCallback onPull;
  final VoidCallback onPush;
  final VoidCallback onStash;
  final VoidCallback onStashPop;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ActionButton(
          icon: Icons.download,
          label: 'Fetch',
          onPressed: busy ? null : onFetch,
        ),
        _ActionButton(
          icon: Icons.sync,
          label: 'Pull',
          onPressed: busy ? null : onPull,
        ),
        _ActionButton(
          icon: Icons.upload,
          label: 'Push',
          onPressed: busy ? null : onPush,
          color: Theme.of(context).colorScheme.error,
        ),
        _ActionButton(
          icon: Icons.inventory_2_outlined,
          label: 'Stash',
          onPressed: busy ? null : onStash,
        ),
        _ActionButton(
          icon: Icons.inventory_2,
          label: 'Unstash',
          onPressed: busy ? null : onStashPop,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

class _FileStatusSection extends StatelessWidget {
  const _FileStatusSection({required this.status});

  final GitStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.l10n.changes,
              style: theme.textTheme.titleSmall,
            ),
            const Spacer(),
            Text(
              '${status.totalChanges} file(s)',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (status.staged.isNotEmpty)
          _FileList(
            title: context.l10n.staged,
            files: status.staged,
            icon: Icons.add_circle_outline,
            color: Colors.green,
          ),
        if (status.modified.isNotEmpty)
          _FileList(
            title: context.l10n.modified,
            files: status.modified,
            icon: Icons.edit_outlined,
            color: Colors.orange,
          ),
        if (status.untracked.isNotEmpty)
          _FileList(
            title: context.l10n.untracked,
            files: status.untracked,
            icon: Icons.help_outline,
            color: Colors.grey,
          ),
        if (status.conflicts.isNotEmpty)
          _FileList(
            title: context.l10n.conflicts,
            files: status.conflicts,
            icon: Icons.error_outline,
            color: Colors.red,
          ),
        if (status.totalChanges == 0)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              context.l10n.noChanges,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
      ],
    );
  }
}

class _FileList extends StatelessWidget {
  const _FileList({
    required this.title,
    required this.files,
    required this.icon,
    required this.color,
  });

  final String title;
  final List<String> files;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(left: 24),
      leading: Icon(icon, color: color, size: 18),
      title: Text('$title (${files.length})'),
      children: files
          .map(
            (f) => ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              title: Text(
                f,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CommitSection extends StatelessWidget {
  const _CommitSection({required this.commits});

  final List<GitCommit> commits;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.recentCommits,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (commits.isEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              context.l10n.noCommits,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          )
        else
          ...commits.take(10).map(
                (c) => ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: Icon(Icons.commit, size: 16, color: theme.colorScheme.primary),
                  title: Text(
                    c.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    c.hash,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
      ],
    );
  }
}

/// Shows the git panel as a modal bottom sheet.
Future<void> showGitPanel(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => const GitPanel(),
  );
}
