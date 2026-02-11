/// MCP Server implementation for Avodah.
///
/// Implements the Model Context Protocol (MCP) over JSON-RPC 2.0 for stdio.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avodah_mcp/config/paths.dart';
import 'package:avodah_mcp/services/jira_service.dart';
import 'package:avodah_mcp/services/project_service.dart';
import 'package:avodah_mcp/services/task_service.dart';
import 'package:avodah_mcp/services/timer_service.dart';
import 'package:avodah_mcp/services/worklog_service.dart';

/// MCP Server that exposes worklog tracking tools.
class McpServer {
  final TimerService timerService;
  final TaskService taskService;
  final WorklogService worklogService;
  final ProjectService projectService;
  final JiraService jiraService;
  final AvodahPaths paths;

  static const String serverName = 'avodah';
  static const String serverVersion = '0.1.0';

  McpServer({
    required this.timerService,
    required this.taskService,
    required this.worklogService,
    required this.projectService,
    required this.jiraService,
    required this.paths,
  });

  /// Starts serving MCP over stdio.
  Future<void> serve(Stream<List<int>> input, IOSink output) async {
    final lines = input.transform(utf8.decoder).transform(const LineSplitter());

    await for (final line in lines) {
      try {
        final request = jsonDecode(line) as Map<String, dynamic>;
        final response = await _handleRequest(request);
        output.writeln(jsonEncode(response));
      } catch (e) {
        final error = {
          'jsonrpc': '2.0',
          'error': {
            'code': -32700,
            'message': 'Parse error',
            'data': e.toString(),
          },
          'id': null,
        };
        output.writeln(jsonEncode(error));
      }
    }
  }

  Future<Map<String, dynamic>> _handleRequest(
      Map<String, dynamic> request) async {
    final method = request['method'] as String?;
    final params = request['params'] as Map<String, dynamic>? ?? {};
    final id = request['id'];

    try {
      final result = await _dispatch(method, params);
      return {
        'jsonrpc': '2.0',
        'result': result,
        'id': id,
      };
    } catch (e) {
      return {
        'jsonrpc': '2.0',
        'error': {
          'code': -32603,
          'message': e.toString(),
        },
        'id': id,
      };
    }
  }

  Future<dynamic> _dispatch(String? method, Map<String, dynamic> params) async {
    switch (method) {
      // MCP Protocol methods
      case 'initialize':
        return _handleInitialize(params);
      case 'tools/list':
        return _handleToolsList();
      case 'tools/call':
        return _handleToolsCall(params);
      case 'resources/list':
        return _handleResourcesList();
      case 'resources/read':
        return _handleResourcesRead(params);

      // Legacy methods (for backwards compatibility)
      case 'timer':
        return _handleTimer(params);
      case 'tasks':
        return _handleTasks(params);
      case 'today':
        return _handleToday(params);
      case 'jira':
        return _handleJira(params);

      default:
        throw Exception('Unknown method: $method');
    }
  }

  // ── MCP Protocol Methods ──────────────────────────────────────────────────

  Map<String, dynamic> _handleInitialize(Map<String, dynamic> params) {
    return {
      'protocolVersion': '2024-11-05',
      'capabilities': {
        'tools': {},
        'resources': {},
      },
      'serverInfo': {
        'name': serverName,
        'version': serverVersion,
      },
    };
  }

  Map<String, dynamic> _handleToolsList() {
    return {
      'tools': [
        {
          'name': 'timer',
          'description':
              'Control the worklog timer - start, stop, pause, resume, or get status',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'action': {
                'type': 'string',
                'enum': ['start', 'stop', 'pause', 'resume', 'status', 'cancel'],
                'description': 'Timer action to perform',
              },
              'task': {
                'type': 'string',
                'description': 'Task title (required for start)',
              },
              'taskId': {
                'type': 'string',
                'description': 'Optional task ID to link the timer to',
              },
              'note': {
                'type': 'string',
                'description': 'Optional note for the timer',
              },
            },
            'required': ['action'],
          },
        },
        {
          'name': 'tasks',
          'description': 'Manage tasks - list, add, show details, or mark done',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'action': {
                'type': 'string',
                'enum': ['list', 'add', 'show', 'done'],
                'description': 'Task action to perform',
              },
              'title': {
                'type': 'string',
                'description': 'Task title (required for add)',
              },
              'id': {
                'type': 'string',
                'description': 'Task ID or prefix (required for show/done)',
              },
              'projectId': {
                'type': 'string',
                'description': 'Optional project ID for add',
              },
              'includeCompleted': {
                'type': 'boolean',
                'description': 'Include completed tasks in list',
              },
            },
            'required': ['action'],
          },
        },
        {
          'name': 'today',
          'description': "Get today's worklog summary",
          'inputSchema': {
            'type': 'object',
            'properties': {},
          },
        },
        {
          'name': 'jira',
          'description': 'Jira integration - sync, status, pull, push',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'action': {
                'type': 'string',
                'enum': ['sync', 'status', 'pull', 'push'],
                'description': 'Jira action to perform',
              },
            },
            'required': ['action'],
          },
        },
      ],
    };
  }

  Future<Map<String, dynamic>> _handleToolsCall(
      Map<String, dynamic> params) async {
    final name = params['name'] as String?;
    final arguments = params['arguments'] as Map<String, dynamic>? ?? {};

    switch (name) {
      case 'timer':
        return _handleTimer(arguments);
      case 'tasks':
        return _handleTasks(arguments);
      case 'today':
        return _handleToday(arguments);
      case 'jira':
        return _handleJira(arguments);
      default:
        throw Exception('Unknown tool: $name');
    }
  }

  Map<String, dynamic> _handleResourcesList() {
    return {
      'resources': [
        {
          'uri': 'avodah://status',
          'name': 'Avodah Status',
          'description': 'Current timer status and today\'s summary',
          'mimeType': 'application/json',
        },
      ],
    };
  }

  Future<Map<String, dynamic>> _handleResourcesRead(
      Map<String, dynamic> params) async {
    final uri = params['uri'] as String?;

    switch (uri) {
      case 'avodah://status':
        final timer = await timerService.status();
        final today = await worklogService.todaySummary();

        return {
          'contents': [
            {
              'uri': 'avodah://status',
              'mimeType': 'application/json',
              'text': jsonEncode({
                'timer': timer != null
                    ? {
                        'running': timer.isRunning,
                        'paused': timer.isPaused,
                        'task': timer.taskTitle,
                        'taskId': timer.taskId,
                        'elapsed': _formatDuration(timer.elapsed),
                      }
                    : null,
                'today': {
                  'date': today.date,
                  'total': today.formattedDuration,
                  'tasks': today.tasks
                      .map((t) => {
                            'taskId': t.taskId,
                            'total': t.formattedDuration,
                          })
                      .toList(),
                },
              }),
            },
          ],
        };
      default:
        throw Exception('Unknown resource: $uri');
    }
  }

  // ── Tool Handlers ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _handleTimer(Map<String, dynamic> params) async {
    final action = params['action'] as String?;

    switch (action) {
      case 'start':
        final task = params['task'] as String? ?? 'Untitled';
        final taskId = params['taskId'] as String?;
        final note = params['note'] as String?;

        try {
          final timer = await timerService.start(
            taskTitle: task,
            taskId: taskId,
            note: note,
          );
          return {
            'ok': true,
            'running': true,
            'task': timer.taskTitle,
            'taskId': timer.taskId,
            'startedAt': timer.startedAt?.toIso8601String(),
          };
        } on TimerAlreadyRunningException catch (e) {
          return {
            'ok': false,
            'error': e.toString(),
            'running': true,
            'task': e.timer.taskTitle,
          };
        }

      case 'stop':
        try {
          final result = await timerService.stop();
          return {
            'ok': true,
            'running': false,
            'logged': '${result.elapsedFormatted} → ${result.taskTitle}',
            'worklogId': result.worklogId,
            'elapsed': result.elapsedFormatted,
            'task': result.taskTitle,
          };
        } on NoTimerRunningException {
          return {
            'ok': false,
            'error': 'No timer is currently running.',
            'running': false,
          };
        }

      case 'pause':
        try {
          final timer = await timerService.pause();
          return {
            'ok': true,
            'paused': true,
            'task': timer.taskTitle,
            'elapsed': _formatDuration(timer.elapsed),
          };
        } on NoTimerRunningException {
          return {'ok': false, 'error': 'No timer is currently running.'};
        } on TimerAlreadyPausedException {
          return {'ok': false, 'error': 'Timer is already paused.'};
        }

      case 'resume':
        try {
          final timer = await timerService.resume();
          return {
            'ok': true,
            'running': true,
            'task': timer.taskTitle,
            'elapsed': _formatDuration(timer.elapsed),
          };
        } on NoTimerRunningException {
          return {'ok': false, 'error': 'No timer is currently running.'};
        } on TimerNotPausedException {
          return {'ok': false, 'error': 'Timer is not paused.'};
        }

      case 'cancel':
        try {
          await timerService.cancel();
          return {'ok': true, 'cancelled': true};
        } on NoTimerRunningException {
          return {'ok': false, 'error': 'No timer is currently running.'};
        }

      case 'status':
        final timer = await timerService.status();
        if (timer == null) {
          return {'ok': true, 'running': false};
        }
        return {
          'ok': true,
          'running': timer.isRunning,
          'paused': timer.isPaused,
          'task': timer.taskTitle,
          'taskId': timer.taskId,
          'elapsed': _formatDuration(timer.elapsed),
          'startedAt': timer.startedAt?.toIso8601String(),
        };

      default:
        throw Exception('Unknown timer action: $action');
    }
  }

  Future<Map<String, dynamic>> _handleTasks(Map<String, dynamic> params) async {
    final action = params['action'] as String?;

    switch (action) {
      case 'list':
        final includeCompleted = params['includeCompleted'] as bool? ?? false;
        final tasks = await taskService.list(includeCompleted: includeCompleted);
        return {
          'ok': true,
          'tasks': tasks
              .map((t) => {
                    'id': t.id,
                    'title': t.title,
                    'isDone': t.isDone,
                    'projectId': t.projectId,
                  })
              .toList(),
        };

      case 'add':
        final title = params['title'] as String?;
        if (title == null || title.isEmpty) {
          return {'ok': false, 'error': 'Title is required'};
        }
        final projectId = params['projectId'] as String?;
        final task = await taskService.add(title: title, projectId: projectId);
        return {
          'ok': true,
          'created': {
            'id': task.id,
            'title': task.title,
            'projectId': task.projectId,
          },
        };

      case 'show':
        final id = params['id'] as String?;
        if (id == null || id.isEmpty) {
          return {'ok': false, 'error': 'Task ID is required'};
        }
        try {
          final task = await taskService.show(id);
          return {
            'ok': true,
            'task': {
              'id': task.id,
              'title': task.title,
              'isDone': task.isDone,
              'projectId': task.projectId,
            },
          };
        } on TaskNotFoundException catch (e) {
          return {'ok': false, 'error': e.toString()};
        } on AmbiguousTaskIdException catch (e) {
          return {'ok': false, 'error': e.toString()};
        }

      case 'done':
        final id = params['id'] as String?;
        if (id == null || id.isEmpty) {
          return {'ok': false, 'error': 'Task ID is required'};
        }
        try {
          final task = await taskService.done(id);
          return {
            'ok': true,
            'completed': {
              'id': task.id,
              'title': task.title,
            },
          };
        } on TaskNotFoundException catch (e) {
          return {'ok': false, 'error': e.toString()};
        } on AmbiguousTaskIdException catch (e) {
          return {'ok': false, 'error': e.toString()};
        } on TaskAlreadyDoneException catch (e) {
          return {'ok': false, 'error': e.toString()};
        }

      default:
        throw Exception('Unknown tasks action: $action');
    }
  }

  Future<Map<String, dynamic>> _handleToday(Map<String, dynamic> params) async {
    final summary = await worklogService.todaySummary();
    return {
      'date': summary.date,
      'total': summary.formattedDuration,
      'tasks': summary.tasks
          .map((t) => {
                'taskId': t.taskId,
                'taskTitle': t.taskTitle,
                'total': t.formattedDuration,
              })
          .toList(),
    };
  }

  Future<Map<String, dynamic>> _handleJira(Map<String, dynamic> params) async {
    final action = params['action'] as String?;

    switch (action) {
      case 'sync':
        try {
          final result = await jiraService.sync();
          return {
            'ok': true,
            'pull': {'created': result.pull.created, 'updated': result.pull.updated},
            'push': {'pushed': result.push.pushed, 'failed': result.push.failed},
          };
        } on JiraNotConfiguredException catch (e) {
          return {'ok': false, 'error': e.toString()};
        } on JiraCredentialsNotFoundException catch (e) {
          return {'ok': false, 'error': e.toString()};
        } on JiraSyncException catch (e) {
          return {'ok': false, 'error': e.toString()};
        }

      case 'status':
        final status = await jiraService.status();
        return {
          'ok': true,
          'configured': status.configured,
          'jiraProjectKey': status.jiraProjectKey,
          'baseUrl': status.baseUrl,
          'lastSyncAt': status.lastSyncAt?.toIso8601String(),
          'lastSyncError': status.lastSyncError,
          'pendingWorklogs': status.pendingWorklogs,
          'linkedTasks': status.linkedTasks,
        };

      case 'pull':
        try {
          final result = await jiraService.pull();
          return {
            'ok': true,
            'created': result.created,
            'updated': result.updated,
          };
        } on JiraNotConfiguredException catch (e) {
          return {'ok': false, 'error': e.toString()};
        } on JiraCredentialsNotFoundException catch (e) {
          return {'ok': false, 'error': e.toString()};
        } on JiraSyncException catch (e) {
          return {'ok': false, 'error': e.toString()};
        }

      case 'push':
        try {
          final result = await jiraService.push();
          return {
            'ok': true,
            'pushed': result.pushed,
            'failed': result.failed,
          };
        } on JiraNotConfiguredException catch (e) {
          return {'ok': false, 'error': e.toString()};
        } on JiraCredentialsNotFoundException catch (e) {
          return {'ok': false, 'error': e.toString()};
        }

      default:
        throw Exception('Unknown jira action: $action');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}
