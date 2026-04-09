import 'package:flutter/material.dart';

import '../models/repo_diff.dart';
import '../services/agent_api_client.dart';
import '../widgets/diff_widgets.dart';

/// Screen showing the full file-level diff for a single commit.
///
/// Calls [AgentApiClient.getRepoDiff] on init with repoKey and commitSha.
/// Shows loading spinner while fetching, error state with retry on failure,
/// and a color-coded diff view on success.
class CommitDiffScreen extends StatefulWidget {
  final AgentApiClient apiClient;
  final String repoKey;
  final String commitSha;
  final String? commitMessage;

  const CommitDiffScreen({
    super.key,
    required this.apiClient,
    required this.repoKey,
    required this.commitSha,
    this.commitMessage,
  });

  @override
  State<CommitDiffScreen> createState() => _CommitDiffScreenState();
}

class _CommitDiffScreenState extends State<CommitDiffScreen> {
  RepoDiff? _diff;
  bool _loading = true;
  String? _error;

  String get _shortSha => widget.commitSha.length > 7
      ? widget.commitSha.substring(0, 7)
      : widget.commitSha;

  @override
  void initState() {
    super.initState();
    _loadDiff();
  }

  Future<void> _loadDiff() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final diff = await widget.apiClient.getRepoDiff(widget.repoKey, widget.commitSha);

      if (mounted) {
        setState(() {
          _diff = diff;
          _loading = false;
        });
      }
    } on AgentApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.commitMessage ?? _shortSha),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ErrorView(
        error: _error!,
        onRetry: _loadDiff,
      );
    }

    return DiffView(diff: _diff!);
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load diff',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
