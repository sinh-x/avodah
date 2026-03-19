import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/team_folder.dart';
import '../services/team_browser_provider.dart';
import '../widgets/deploy_sheet.dart';

/// Entry point for the Team Browser — shows list of agent teams.
///
/// Read-only navigation: Teams → Folders → Files → Markdown content.
class TeamBrowserScreen extends StatefulWidget {
  final TeamBrowserProvider teamProvider;

  const TeamBrowserScreen({super.key, required this.teamProvider});

  @override
  State<TeamBrowserScreen> createState() => _TeamBrowserScreenState();
}

class _TeamBrowserScreenState extends State<TeamBrowserScreen> {
  @override
  void initState() {
    super.initState();
    widget.teamProvider.addListener(_onUpdate);
    if (widget.teamProvider.teams.isEmpty) {
      widget.teamProvider.refreshTeams();
    }
    if (widget.teamProvider.paTeams.isEmpty) {
      widget.teamProvider.loadPaTeams();
    }
  }

  @override
  void dispose() {
    widget.teamProvider.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.teamProvider;
    final theme = Theme.of(context);

    if (provider.error != null && provider.teams.isEmpty) {
      return _buildError(theme, provider);
    }

    if (provider.loading && provider.teams.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.teams.isEmpty) {
      return _buildEmpty(theme, provider);
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: provider.refreshTeams,
        child: ListView.builder(
          itemCount: provider.teams.length,
          itemBuilder: (context, index) {
            final team = provider.teams[index];
            return _TeamTile(
              team: team,
              onTap: () => _openTeam(context, team),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openFabSheet(context),
        tooltip: 'Deploy',
        child: const Icon(Icons.rocket_launch_outlined),
      ),
    );
  }

  void _openTeam(BuildContext context, TeamFolder team) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _TeamFoldersScreen(
          team: team,
          teamProvider: widget.teamProvider,
        ),
      ),
    );
  }

  void _openFabSheet(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DeploySheet(
        paTeams: widget.teamProvider.paTeams,
        repos: widget.teamProvider.paRepos,
        onDeploy: (team, mode, objective, repo) async {
          Navigator.pop(context);
          try {
            final result = await widget.teamProvider.deploy(
              team,
              mode,
              objective: objective.isNotEmpty ? objective : null,
              repo: repo,
            );
            if (mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    result.deploymentId.isNotEmpty
                        ? '${result.deploymentId} started'
                        : 'Deployment started',
                  ),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Deploy failed: $e'),
                  backgroundColor: errorColor,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme, TeamBrowserProvider provider) {
    return RefreshIndicator(
      onRefresh: provider.refreshTeams,
      child: ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.group_work_outlined,
              size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'No teams found',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Pull to refresh',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme, TeamBrowserProvider provider) {
    return RefreshIndicator(
      onRefresh: provider.refreshTeams,
      child: ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.cloud_off, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Unable to connect',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Check server address in settings',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => provider.refreshTeams(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamTile extends StatelessWidget {
  final TeamFolder team;
  final VoidCallback onTap;

  const _TeamTile({required this.team, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            theme.colorScheme.primaryContainer,
        child: Icon(
          Icons.group_work_outlined,
          color: theme.colorScheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(team.name),
      subtitle: Text(
        '${team.inboxCount} / ${team.ongoingCount} / ${team.wfrCount}',
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.outline),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// --- Team Folders Screen ---

class _TeamFoldersScreen extends StatelessWidget {
  final TeamFolder team;
  final TeamBrowserProvider teamProvider;

  const _TeamFoldersScreen({
    required this.team,
    required this.teamProvider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(team.name)),
      body: team.folders.isEmpty
          ? Center(
              child: Text(
                'No folders',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            )
          : ListView.builder(
              itemCount: team.folders.length,
              itemBuilder: (context, index) {
                final folder = team.folders[index];
                return _FolderTile(
                  folder: folder,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _TeamFilesScreen(
                        team: team.name,
                        folder: folder,
                        teamProvider: teamProvider,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _FolderTile extends StatelessWidget {
  final String folder;
  final VoidCallback onTap;

  const _FolderTile({required this.folder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        _folderIcon(folder),
        color: theme.colorScheme.primary,
      ),
      title: Text(folder),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  IconData _folderIcon(String folder) {
    switch (folder.toLowerCase()) {
      case 'inbox':
        return Icons.inbox_outlined;
      case 'ongoing':
        return Icons.pending_actions_outlined;
      case 'done':
        return Icons.task_alt;
      case 'artifacts':
        return Icons.article_outlined;
      case 'waiting-for-response':
      case 'waiting_for_response':
        return Icons.hourglass_empty;
      case 'archives':
        return Icons.archive_outlined;
      default:
        return Icons.folder_outlined;
    }
  }
}

// --- Team Files Screen ---

class _TeamFilesScreen extends StatefulWidget {
  final String team;
  final String folder;
  final TeamBrowserProvider teamProvider;

  const _TeamFilesScreen({
    required this.team,
    required this.folder,
    required this.teamProvider,
  });

  @override
  State<_TeamFilesScreen> createState() => _TeamFilesScreenState();
}

class _TeamFilesScreenState extends State<_TeamFilesScreen> {
  List<TeamFile> _files = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final files =
          await widget.teamProvider.fetchFolder(widget.team, widget.folder);
      if (mounted) {
        setState(() {
          _files = files;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.team} / ${widget.folder}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(theme)
              : _files.isEmpty
                  ? _buildEmpty(theme)
                  : RefreshIndicator(
                      onRefresh: _loadFiles,
                      child: ListView.builder(
                        itemCount: _files.length,
                        itemBuilder: (context, index) {
                          final file = _files[index];
                          return _FileTile(
                            file: file,
                            onTap: () => _openFile(context, file),
                          );
                        },
                      ),
                    ),
    );
  }

  void _openFile(BuildContext context, TeamFile file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _TeamFileViewScreen(
          team: widget.team,
          folder: widget.folder,
          file: file,
          teamProvider: widget.teamProvider,
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.folder_open, size: 64, color: theme.colorScheme.outline),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'No files in this folder',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ),
      ],
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('Failed to load files', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(_error!, style: theme.textTheme.bodySmall),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadFiles,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  final TeamFile file;
  final VoidCallback onTap;

  const _FileTile({required this.file, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modifiedStr = _formatDate(file.modified);
    final sizeStr = _formatSize(file.size);

    return ListTile(
      leading: Icon(Icons.description_outlined,
          color: theme.colorScheme.primary),
      title: Text(
        file.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '$modifiedStr · $sizeStr',
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.outline),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      '',
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${months[local.month]} ${local.day} $h:$m';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

// --- Team File View Screen ---

class _TeamFileViewScreen extends StatefulWidget {
  final String team;
  final String folder;
  final TeamFile file;
  final TeamBrowserProvider teamProvider;

  const _TeamFileViewScreen({
    required this.team,
    required this.folder,
    required this.file,
    required this.teamProvider,
  });

  @override
  State<_TeamFileViewScreen> createState() => _TeamFileViewScreenState();
}

class _TeamFileViewScreenState extends State<_TeamFileViewScreen> {
  String? _content;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final item = await widget.teamProvider.readFile(
        widget.team,
        widget.folder,
        widget.file.name,
      );
      if (mounted) {
        setState(() {
          _content = item.content ?? '';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isInbox = widget.folder == 'inbox';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.file.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (!_loading && _error == null && isInbox)
            IconButton(
              icon: const Icon(Icons.rocket_launch_outlined),
              tooltip: 'Deploy',
              onPressed: _onDeploy,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(theme)
              : Markdown(
                  data: _content ?? '',
                  selectable: true,
                  padding: const EdgeInsets.all(16),
                ),
    );
  }

  void _onDeploy() {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DeploySheet(
        paTeams: widget.teamProvider.paTeams,
        repos: widget.teamProvider.paRepos,
        initialTeam: widget.team,
        initialObjective: widget.file.name,
        onDeploy: (team, mode, objective, repo) async {
          Navigator.pop(context);
          try {
            final result = await widget.teamProvider.deploy(
              team,
              mode,
              objective: objective.isNotEmpty ? objective : null,
              repo: repo,
            );
            if (mounted) {
              messenger.showSnackBar(SnackBar(
                content: Text(
                  result.deploymentId.isNotEmpty
                      ? '${result.deploymentId} started'
                      : 'Deployment started',
                ),
                duration: const Duration(seconds: 4),
              ));
            }
          } catch (e) {
            if (mounted) {
              messenger.showSnackBar(SnackBar(
                content: Text('Deploy failed: $e'),
                backgroundColor: errorColor,
              ));
            }
          }
        },
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('Failed to load content', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(_error!, style: theme.textTheme.bodySmall),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadContent,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
