/// MCP Server implementation for Avodah.
///
/// Implements the Model Context Protocol (MCP) over JSON-RPC 2.0 for stdio.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avodah_core/avodah_core.dart' show avodahVersion;
import 'package:avodah_mcp/config/paths.dart';
import 'package:avodah_mcp/services/jira_service.dart';
import 'package:avodah_mcp/services/plan_service.dart';
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
  final PlanService planService;
  final AvodahPaths paths;

  static const String serverName = 'avodah';
  static String get serverVersion => avodahVersion;

  McpServer({
    required this.timerService,
    required this.taskService,
    required this.worklogService,
    required this.projectService,
    required this.jiraService,
    required this.planService,
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
      case 'worklog':
        return _handleWorklog(params);
      case 'project':
        return _handleProject(params);
      case 'plan':
        return _handlePlan(params);
      case 'today':
        return _handleToday(params);
      case 'daily':
        return _handleDaily(params);
      case 'week':
        return _handleWeek(params);
      case 'status':
        return _handleStatus(params);
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
          'description':
              'Manage tasks - list, add, show, done, undone, delete, undelete, set due date, set category, notes',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'action': {
                'type': 'string',
                'enum': [
                  'list', 'add', 'show', 'done', 'undone', 'delete',
                  'undelete', 'due', 'cat', 'note'
                ],
                'description': 'Task action to perform',
              },
              'title': {
                'type': 'string',
                'description': 'Task title (required for add)',
              },
              'id': {
                'type': 'string',
                'description':
                    'Task ID or prefix (required for show/done/delete/due/cat)',
              },
              'projectId': {
                'type': 'string',
                'description': 'Optional project ID for add',
              },
              'includeCompleted': {
                'type': 'boolean',
                'description': 'Include completed tasks in list',
              },
              'includeDeleted': {
                'type': 'boolean',
                'description':
                    'List only soft-deleted tasks (overrides other list filters)',
              },
              'force': {
                'type': 'boolean',
                'description':
                    'Force delete even if the task has worklogs',
              },
              'dueDay': {
                'type': 'string',
                'description':
                    'Due date in YYYY-MM-DD format, or null to clear (for due action)',
              },
              'category': {
                'type': 'string',
                'description':
                    'Category string, or null to clear (for cat action)',
              },
              'content': {
                'type': 'string',
                'description':
                    'Note/description content (for note action)',
              },
              'append': {
                'type': 'boolean',
                'description':
                    'Append as timestamped note instead of replacing (for note action)',
              },
            },
            'required': ['action'],
          },
        },
        {
          'name': 'worklog',
          'description':
              'Manage worklogs - add, edit, list recent, or delete entries',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'action': {
                'type': 'string',
                'enum': ['add', 'edit', 'list', 'delete'],
                'description': 'Worklog action to perform',
              },
              'taskId': {
                'type': 'string',
                'description': 'Task ID (required for add)',
              },
              'id': {
                'type': 'string',
                'description': 'Worklog ID or prefix (required for edit/delete)',
              },
              'start': {
                'type': 'string',
                'description': 'Start time in ISO 8601 format (required for add)',
              },
              'durationMinutes': {
                'type': 'integer',
                'description': 'Duration in minutes (required for add)',
              },
              'comment': {
                'type': 'string',
                'description': 'Optional comment',
              },
              'limit': {
                'type': 'integer',
                'description': 'Max entries to return for list (default 10)',
              },
            },
            'required': ['action'],
          },
        },
        {
          'name': 'project',
          'description': 'Manage projects - add, list, show details, or delete',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'action': {
                'type': 'string',
                'enum': ['add', 'list', 'show', 'delete'],
                'description': 'Project action to perform',
              },
              'title': {
                'type': 'string',
                'description': 'Project title (required for add)',
              },
              'id': {
                'type': 'string',
                'description':
                    'Project ID or prefix (required for show/delete)',
              },
              'icon': {
                'type': 'string',
                'description': 'Optional icon for add',
              },
              'includeArchived': {
                'type': 'boolean',
                'description': 'Include archived projects in list',
              },
            },
            'required': ['action'],
          },
        },
        {
          'name': 'plan',
          'description':
              'Manage daily plan - add/remove category time blocks, add/remove/cancel tasks',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'action': {
                'type': 'string',
                'enum': [
                  'add', 'list', 'remove', 'task', 'untask', 'cancel', 'uncancel'
                ],
                'description': 'Plan action to perform',
              },
              'category': {
                'type': 'string',
                'description':
                    'Category name (required for add/remove)',
              },
              'durationMinutes': {
                'type': 'integer',
                'description':
                    'Planned duration in minutes (required for add)',
              },
              'taskId': {
                'type': 'string',
                'description':
                    'Task ID (required for task/untask/cancel/uncancel)',
              },
              'estimateMinutes': {
                'type': 'integer',
                'description': 'Estimated minutes for task (optional for task)',
              },
              'day': {
                'type': 'string',
                'description':
                    'Date in YYYY-MM-DD format (default: today)',
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
          'name': 'daily',
          'description':
              'Date report with worklog summary and plan-vs-actual breakdown',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'date': {
                'type': 'string',
                'description':
                    'Date in YYYY-MM-DD format (default: today)',
              },
            },
          },
        },
        {
          'name': 'week',
          'description':
              'Weekly report with daily breakdown and category plan-vs-actual',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'from': {
                'type': 'string',
                'description':
                    'Start date YYYY-MM-DD. No params = current week. Only from = week containing date.',
              },
              'to': {
                'type': 'string',
                'description':
                    'End date YYYY-MM-DD. Both from+to = custom range.',
              },
            },
          },
        },
        {
          'name': 'status',
          'description':
              'Dashboard overview - timer state, today summary, plan summary, active tasks',
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
      case 'worklog':
        return _handleWorklog(arguments);
      case 'project':
        return _handleProject(arguments);
      case 'plan':
        return _handlePlan(arguments);
      case 'today':
        return _handleToday(arguments);
      case 'daily':
        return _handleDaily(arguments);
      case 'week':
        return _handleWeek(arguments);
      case 'status':
        return _handleStatus(arguments);
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
        final includeDeleted = params['includeDeleted'] as bool? ?? false;
        if (includeDeleted) {
          final tasks = await taskService.listDeleted();
          return {
            'ok': true,
            'tasks': tasks
                .map((t) => {
                      'id': t.id,
                      'title': t.title,
                      'isDone': t.isDone,
                      'isDeleted': true,
                    })
                .toList(),
          };
        }
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
                    'dueDay': t.dueDay,
                    'category': t.category,
                  })
              .toList(),
        };

      case 'add':
        final title = params['title'] as String?;
        if (title == null || title.isEmpty) {
          return {'ok': false, 'error': 'Title is required'};
        }
        final projectId = params['projectId'] as String?;
        final dueDay = params['dueDay'] as String?;
        final category = params['category'] as String?;
        final task = await taskService.add(
          title: title,
          projectId: projectId,
          dueDay: dueDay,
          category: category,
        );
        return {
          'ok': true,
          'created': {
            'id': task.id,
            'title': task.title,
            'projectId': task.projectId,
            'dueDay': task.dueDay,
            'category': task.category,
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
              'dueDay': task.dueDay,
              'category': task.category,
              'description': task.description,
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

      case 'delete':
        final id = params['id'] as String?;
        if (id == null || id.isEmpty) {
          return {'ok': false, 'error': 'Task ID is required'};
        }
        try {
          final force = params['force'] as bool? ?? false;
          final task = await taskService.show(id);

          if (!force) {
            final info = await worklogService.worklogInfoForTask(task.id);
            if (info.count > 0) {
              return {
                'ok': false,
                'error': 'Task has worklogs',
                'worklogCount': info.count,
                'totalTime': _formatDuration(info.total),
                'hint': 'Set force: true to delete anyway',
              };
            }
          }

          await taskService.delete(id);
          return {
            'ok': true,
            'deleted': {
              'id': task.id,
              'title': task.title,
            },
          };
        } on TaskNotFoundException catch (e) {
          return {'ok': false, 'error': e.toString()};
        } on AmbiguousTaskIdException catch (e) {
          return {'ok': false, 'error': e.toString()};
        }

      case 'undone':
        final id = params['id'] as String?;
        if (id == null || id.isEmpty) {
          return {'ok': false, 'error': 'Task ID is required'};
        }
        try {
          final task = await taskService.undone(id);
          return {
            'ok': true,
            'undone': {
              'id': task.id,
              'title': task.title,
            },
          };
        } on TaskNotFoundException catch (e) {
          return {'ok': false, 'error': e.toString()};
        } on AmbiguousTaskIdException catch (e) {
          return {'ok': false, 'error': e.toString()};
        } on TaskNotDoneException catch (e) {
          return {'ok': false, 'error': e.toString()};
        }

      case 'undelete':
        final id = params['id'] as String?;
        if (id == null || id.isEmpty) {
          return {'ok': false, 'error': 'Task ID is required'};
        }
        try {
          final task = await taskService.undelete(id);
          return {
            'ok': true,
            'restored': {
              'id': task.id,
              'title': task.title,
            },
          };
        } on TaskNotFoundException catch (e) {
          return {'ok': false, 'error': e.toString()};
        } on AmbiguousTaskIdException catch (e) {
          return {'ok': false, 'error': e.toString()};
        } on TaskNotDeletedException catch (e) {
          return {'ok': false, 'error': e.toString()};
        }

      case 'due':
        final id = params['id'] as String?;
        if (id == null || id.isEmpty) {
          return {'ok': false, 'error': 'Task ID is required'};
        }
        try {
          final dueDay = params['dueDay'] as String?;
          final task = await taskService.setDue(id, dueDay);
          return {
            'ok': true,
            'task': {
              'id': task.id,
              'title': task.title,
              'dueDay': task.dueDay,
            },
          };
        } on TaskNotFoundException catch (e) {
          return {'ok': false, 'error': e.toString()};
        } on AmbiguousTaskIdException catch (e) {
          return {'ok': false, 'error': e.toString()};
        }

      case 'cat':
        final id = params['id'] as String?;
        if (id == null || id.isEmpty) {
          return {'ok': false, 'error': 'Task ID is required'};
        }
        try {
          final category = params['category'] as String?;
          final task = await taskService.setCategory(id, category);
          return {
            'ok': true,
            'task': {
              'id': task.id,
              'title': task.title,
              'category': task.category,
            },
          };
        } on TaskNotFoundException catch (e) {
          return {'ok': false, 'error': e.toString()};
        } on AmbiguousTaskIdException catch (e) {
          return {'ok': false, 'error': e.toString()};
        }

      case 'note':
        final id = params['id'] as String?;
        if (id == null || id.isEmpty) {
          return {'ok': false, 'error': 'Task ID is required'};
        }
        try {
          final content = params['content'] as String?;
          final append = params['append'] as bool? ?? false;

          if (content == null) {
            // View mode
            final task = await taskService.show(id);
            return {
              'ok': true,
              'note': task.description,
            };
          }

          if (append) {
            final task = await taskService.appendNote(id, content);
            return {
              'ok': true,
              'note': task.description,
            };
          }

          // Set or clear
          final task = await taskService.setDescription(
              id, content.isEmpty ? null : content);
          return {
            'ok': true,
            'note': task.description,
          };
        } on TaskNotFoundException catch (e) {
          return {'ok': false, 'error': e.toString()};
        } on AmbiguousTaskIdException catch (e) {
          return {'ok': false, 'error': e.toString()};
        }

      default:
        throw Exception('Unknown tasks action: $action');
    }
  }

  Future<Map<String, dynamic>> _handleWorklog(
      Map<String, dynamic> params) async {
    final action = params['action'] as String?;

    switch (action) {
      case 'add':
        final taskId = params['taskId'] as String?;
        if (taskId == null || taskId.isEmpty) {
          return {'ok': false, 'error': 'taskId is required'};
        }
        final startStr = params['start'] as String?;
        if (startStr == null) {
          return {'ok': false, 'error': 'start (ISO 8601) is required'};
        }
        final durationMinutes = params['durationMinutes'] as int?;
        if (durationMinutes == null || durationMinutes <= 0) {
          return {
            'ok': false,
            'error': 'durationMinutes (positive integer) is required'
          };
        }
        final comment = params['comment'] as String?;

        try {
          final start = DateTime.parse(startStr);
          final worklog = await worklogService.createWorklog(
            taskId: taskId,
            start: start,
            duration: Duration(minutes: durationMinutes),
            comment: comment,
          );
          return {
            'ok': true,
            'created': {
              'id': worklog.id,
              'taskId': worklog.taskId,
              'start': worklog.startTime.toIso8601String(),
              'durationMinutes': worklog.durationMs ~/ 60000,
              'comment': worklog.comment,
            },
          };
        } on FormatException {
          return {'ok': false, 'error': 'Invalid start date format'};
        }

      case 'edit':
        final id = params['id'] as String?;
        if (id == null || id.isEmpty) {
          return {'ok': false, 'error': 'Worklog ID is required'};
        }
        try {
          final startStr = params['start'] as String?;
          final durationMinutes = params['durationMinutes'] as int?;
          final comment = params['comment'] as String?;

          final worklog = await worklogService.editWorklog(
            id,
            start: startStr != null ? DateTime.parse(startStr) : null,
            duration: durationMinutes != null
                ? Duration(minutes: durationMinutes)
                : null,
            comment: comment,
          );

          // Auto-update worklog on Jira if already synced
          bool jiraUpdated = false;
          if (worklog.isSyncedToJira) {
            jiraUpdated = await jiraService.updateWorklog(worklog.id);
          }

          return {
            'ok': true,
            'updated': {
              'id': worklog.id,
              'taskId': worklog.taskId,
              'start': worklog.startTime.toIso8601String(),
              'durationMinutes': worklog.durationMs ~/ 60000,
              'comment': worklog.comment,
              'jiraUpdated': jiraUpdated,
            },
          };
        } on WorklogNotFoundException catch (e) {
          return {'ok': false, 'error': e.toString()};
        } on AmbiguousWorklogIdException catch (e) {
          return {'ok': false, 'error': e.toString()};
        } on FormatException {
          return {'ok': false, 'error': 'Invalid start date format'};
        }

      case 'list':
        final limit = params['limit'] as int? ?? 10;
        final worklogs = await worklogService.listRecent(limit: limit);
        return {
          'ok': true,
          'worklogs': worklogs
              .map((w) => {
                    'id': w.id,
                    'taskId': w.taskId,
                    'date': w.date,
                    'start': w.startTime.toIso8601String(),
                    'durationMinutes': w.durationMs ~/ 60000,
                    'comment': w.comment,
                  })
              .toList(),
        };

      case 'delete':
        final id = params['id'] as String?;
        if (id == null || id.isEmpty) {
          return {'ok': false, 'error': 'Worklog ID is required'};
        }
        try {
          final worklog = await worklogService.deleteWorklog(id);
          return {
            'ok': true,
            'deleted': {
              'id': worklog.id,
              'taskId': worklog.taskId,
            },
          };
        } on WorklogNotFoundException catch (e) {
          return {'ok': false, 'error': e.toString()};
        } on AmbiguousWorklogIdException catch (e) {
          return {'ok': false, 'error': e.toString()};
        }

      default:
        throw Exception('Unknown worklog action: $action');
    }
  }

  Future<Map<String, dynamic>> _handleProject(
      Map<String, dynamic> params) async {
    final action = params['action'] as String?;

    switch (action) {
      case 'add':
        final title = params['title'] as String?;
        if (title == null || title.isEmpty) {
          return {'ok': false, 'error': 'Title is required'};
        }
        final icon = params['icon'] as String?;
        final project = await projectService.add(title: title, icon: icon);
        return {
          'ok': true,
          'created': {
            'id': project.id,
            'title': project.title,
            'icon': project.icon,
          },
        };

      case 'list':
        final includeArchived = params['includeArchived'] as bool? ?? false;
        final projects =
            await projectService.list(includeArchived: includeArchived);
        final result = <Map<String, dynamic>>[];
        for (final p in projects) {
          final count = await projectService.taskCount(p.id);
          result.add({
            'id': p.id,
            'title': p.title,
            'icon': p.icon,
            'taskCount': count,
          });
        }
        return {'ok': true, 'projects': result};

      case 'show':
        final id = params['id'] as String?;
        if (id == null || id.isEmpty) {
          return {'ok': false, 'error': 'Project ID is required'};
        }
        try {
          final project = await projectService.show(id);
          final count = await projectService.taskCount(project.id);
          return {
            'ok': true,
            'project': {
              'id': project.id,
              'title': project.title,
              'icon': project.icon,
              'taskCount': count,
            },
          };
        } on ProjectNotFoundException catch (e) {
          return {'ok': false, 'error': e.toString()};
        } on AmbiguousProjectIdException catch (e) {
          return {'ok': false, 'error': e.toString()};
        }

      case 'delete':
        final id = params['id'] as String?;
        if (id == null || id.isEmpty) {
          return {'ok': false, 'error': 'Project ID is required'};
        }
        try {
          final project = await projectService.delete(id);
          return {
            'ok': true,
            'deleted': {
              'id': project.id,
              'title': project.title,
            },
          };
        } on ProjectNotFoundException catch (e) {
          return {'ok': false, 'error': e.toString()};
        } on AmbiguousProjectIdException catch (e) {
          return {'ok': false, 'error': e.toString()};
        }

      default:
        throw Exception('Unknown project action: $action');
    }
  }

  Future<Map<String, dynamic>> _handlePlan(
      Map<String, dynamic> params) async {
    final action = params['action'] as String?;
    final day = params['day'] as String?;

    switch (action) {
      case 'add':
        final category = params['category'] as String?;
        if (category == null || category.isEmpty) {
          return {'ok': false, 'error': 'category is required'};
        }
        final durationMinutes = params['durationMinutes'] as int?;
        if (durationMinutes == null || durationMinutes <= 0) {
          return {
            'ok': false,
            'error': 'durationMinutes (positive integer) is required'
          };
        }
        try {
          final entry = await planService.add(
            category: category,
            durationMs: durationMinutes * 60000,
            day: day,
          );
          return {
            'ok': true,
            'created': {
              'category': entry.category,
              'day': entry.day,
              'durationMinutes': entry.durationMs ~/ 60000,
            },
          };
        } on DuplicatePlanEntryException catch (e) {
          return {'ok': false, 'error': e.toString()};
        }

      case 'list':
        final summary = await planService.summary(day: day);
        final tasks = await planService.listTasksForDay(day: day);

        // Resolve task titles
        final taskList = <Map<String, dynamic>>[];
        for (final t in tasks) {
          String? title;
          try {
            final taskDoc = await taskService.show(t.taskId);
            title = taskDoc.title;
          } catch (_) {
            title = null;
          }
          taskList.add({
            'taskId': t.taskId,
            'title': title,
            'estimateMinutes': t.estimateMs > 0 ? t.estimateMs ~/ 60000 : null,
            'isCancelled': t.isCancelled,
          });
        }

        return {
          'ok': true,
          'day': summary.day,
          'totalPlanned': _formatDuration(summary.totalPlanned),
          'totalActual': _formatDuration(summary.totalActual),
          'categories': summary.categories
              .map((c) => {
                    'category': c.category,
                    'planned': _formatDuration(c.planned),
                    'actual': _formatDuration(c.actual),
                    'delta': _formatDuration(c.delta),
                  })
              .toList(),
          if (summary.nonCategorized != null)
            'nonCategorized': {
              'actual': _formatDuration(summary.nonCategorized!.actual),
            },
          'tasks': taskList,
        };

      case 'remove':
        final category = params['category'] as String?;
        if (category == null || category.isEmpty) {
          return {'ok': false, 'error': 'category is required'};
        }
        try {
          await planService.remove(category: category, day: day);
          return {'ok': true, 'removed': category};
        } on PlanEntryNotFoundException catch (e) {
          return {'ok': false, 'error': e.toString()};
        }

      case 'task':
        final taskId = params['taskId'] as String?;
        if (taskId == null || taskId.isEmpty) {
          return {'ok': false, 'error': 'taskId is required'};
        }
        final estimateMinutes = params['estimateMinutes'] as int?;
        try {
          final entry = await planService.addTask(
            taskId: taskId,
            estimateMs: estimateMinutes != null ? estimateMinutes * 60000 : 0,
            day: day,
          );
          return {
            'ok': true,
            'added': {
              'taskId': entry.taskId,
              'day': entry.day,
              'estimateMinutes':
                  entry.estimateMs > 0 ? entry.estimateMs ~/ 60000 : null,
            },
          };
        } on DuplicatePlanTaskException catch (e) {
          return {'ok': false, 'error': e.toString()};
        }

      case 'untask':
        final taskId = params['taskId'] as String?;
        if (taskId == null || taskId.isEmpty) {
          return {'ok': false, 'error': 'taskId is required'};
        }
        try {
          await planService.removeTask(taskId: taskId, day: day);
          return {'ok': true, 'removed': taskId};
        } on PlanTaskNotFoundException catch (e) {
          return {'ok': false, 'error': e.toString()};
        }

      case 'cancel':
        final taskId = params['taskId'] as String?;
        if (taskId == null || taskId.isEmpty) {
          return {'ok': false, 'error': 'taskId is required'};
        }
        try {
          await planService.cancelTask(taskId: taskId, day: day);
          return {'ok': true, 'cancelled': taskId};
        } on PlanTaskNotFoundException catch (e) {
          return {'ok': false, 'error': e.toString()};
        }

      case 'uncancel':
        final taskId = params['taskId'] as String?;
        if (taskId == null || taskId.isEmpty) {
          return {'ok': false, 'error': 'taskId is required'};
        }
        try {
          await planService.uncancelTask(taskId: taskId, day: day);
          return {'ok': true, 'uncancelled': taskId};
        } on PlanTaskNotFoundException catch (e) {
          return {'ok': false, 'error': e.toString()};
        }

      default:
        throw Exception('Unknown plan action: $action');
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

  Future<Map<String, dynamic>> _handleDaily(
      Map<String, dynamic> params) async {
    final date = params['date'] as String? ?? _todayString();

    // Worklog summary for the date
    final daySummary = await worklogService.daySummary(date);

    // Plan-vs-actual
    final planSummary = await planService.summary(day: date);

    // Planned tasks
    final planTasks = await planService.listTasksForDay(day: date);

    // Resolve task titles for worklog entries
    final worklogTasks = <Map<String, dynamic>>[];
    for (final t in daySummary.tasks) {
      String? title;
      try {
        final taskDoc = await taskService.show(t.taskId);
        title = taskDoc.title;
      } catch (_) {
        title = null;
      }
      worklogTasks.add({
        'taskId': t.taskId,
        'title': title ?? t.taskTitle,
        'total': t.formattedDuration,
      });
    }

    // Resolve planned task titles
    final plannedTaskList = <Map<String, dynamic>>[];
    for (final t in planTasks) {
      String? title;
      try {
        final taskDoc = await taskService.show(t.taskId);
        title = taskDoc.title;
      } catch (_) {
        title = null;
      }
      plannedTaskList.add({
        'taskId': t.taskId,
        'title': title,
        'estimateMinutes': t.estimateMs > 0 ? t.estimateMs ~/ 60000 : null,
        'isCancelled': t.isCancelled,
      });
    }

    return {
      'ok': true,
      'date': date,
      'worklog': {
        'total': daySummary.formattedDuration,
        'tasks': worklogTasks,
      },
      'plan': {
        'totalPlanned': _formatDuration(planSummary.totalPlanned),
        'totalActual': _formatDuration(planSummary.totalActual),
        'categories': planSummary.categories
            .map((c) => {
                  'category': c.category,
                  'planned': _formatDuration(c.planned),
                  'actual': _formatDuration(c.actual),
                  'delta': _formatDuration(c.delta),
                })
            .toList(),
        if (planSummary.nonCategorized != null)
          'nonCategorized': {
            'actual': _formatDuration(planSummary.nonCategorized!.actual),
          },
        'tasks': plannedTaskList,
      },
    };
  }

  Future<Map<String, dynamic>> _handleWeek(
      Map<String, dynamic> params) async {
    final fromStr = params['from'] as String?;
    final toStr = params['to'] as String?;

    List<DaySummary> dailySummaries;
    DayPlanSummary planSummary;

    if (fromStr == null && toStr == null) {
      // Current week
      dailySummaries = await worklogService.weekSummary();
      planSummary = await planService.weekSummary();
    } else if (fromStr != null && toStr == null) {
      // Week containing the given date
      final anchor = _parseDate(fromStr);
      dailySummaries = await worklogService.weekSummary(anchor: anchor);
      planSummary = await planService.weekSummary(anchor: anchor);
    } else if (fromStr != null && toStr != null) {
      // Custom range
      final from = _parseDate(fromStr);
      final to = _parseDate(toStr);
      dailySummaries =
          await worklogService.rangeSummary(from: from, to: to);
      planSummary = await planService.rangeSummary(from: from, to: to);
    } else {
      return {'ok': false, 'error': 'If "to" is provided, "from" is required'};
    }

    // Build daily breakdown
    final days = <Map<String, dynamic>>[];
    for (final d in dailySummaries) {
      days.add({
        'date': d.date,
        'total': d.formattedDuration,
        'tasks': d.tasks
            .map((t) => {
                  'taskId': t.taskId,
                  'total': t.formattedDuration,
                })
            .toList(),
      });
    }

    // Category plan-vs-actual
    final categories = planSummary.categories
        .map((c) => {
              'category': c.category,
              'planned': _formatDuration(c.planned),
              'actual': _formatDuration(c.actual),
              'delta': _formatDuration(c.delta),
            })
        .toList();

    // Task summary sorted by time across the week
    final taskTime = <String, int>{};
    for (final d in dailySummaries) {
      for (final t in d.tasks) {
        taskTime[t.taskId] = (taskTime[t.taskId] ?? 0) + t.total.inMinutes;
      }
    }
    final sortedTasks = taskTime.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Resolve titles
    final taskSummaries = <Map<String, dynamic>>[];
    for (final entry in sortedTasks) {
      String? title;
      try {
        final taskDoc = await taskService.show(entry.key);
        title = taskDoc.title;
      } catch (_) {
        title = null;
      }
      taskSummaries.add({
        'taskId': entry.key,
        'title': title,
        'totalMinutes': entry.value,
        'total': _formatDuration(Duration(minutes: entry.value)),
      });
    }

    // Weekly total
    final weekTotal = dailySummaries.fold<Duration>(
        Duration.zero, (sum, d) => sum + d.total);

    return {
      'ok': true,
      'weekTotal': _formatDuration(weekTotal),
      'plan': {
        'totalPlanned': _formatDuration(planSummary.totalPlanned),
        'totalActual': _formatDuration(planSummary.totalActual),
        'categories': categories,
        if (planSummary.nonCategorized != null)
          'nonCategorized': {
            'actual': _formatDuration(planSummary.nonCategorized!.actual),
          },
      },
      'days': days,
      'taskSummary': taskSummaries,
    };
  }

  Future<Map<String, dynamic>> _handleStatus(
      Map<String, dynamic> params) async {
    // Timer state
    final timer = await timerService.status();
    Map<String, dynamic>? timerInfo;
    if (timer != null) {
      timerInfo = {
        'running': timer.isRunning,
        'paused': timer.isPaused,
        'task': timer.taskTitle,
        'taskId': timer.taskId,
        'elapsed': _formatDuration(timer.elapsed),
      };
    }

    // Today worklog summary with titles
    final today = await worklogService.todaySummary();
    final todayTasks = <Map<String, dynamic>>[];
    for (final t in today.tasks) {
      String? title;
      try {
        final taskDoc = await taskService.show(t.taskId);
        title = taskDoc.title;
      } catch (_) {
        title = null;
      }
      todayTasks.add({
        'taskId': t.taskId,
        'title': title ?? t.taskTitle,
        'total': t.formattedDuration,
      });
    }

    // Plan summary
    final planSummary = await planService.summary();

    // First 10 active tasks
    final activeTasks = await taskService.list();
    final taskList = activeTasks.take(10).map((t) {
      return {
        'id': t.id,
        'title': t.title,
        'dueDay': t.dueDay,
        'category': t.category,
        'projectId': t.projectId,
      };
    }).toList();

    return {
      'ok': true,
      'timer': timerInfo,
      'today': {
        'date': today.date,
        'total': today.formattedDuration,
        'tasks': todayTasks,
      },
      'plan': {
        'totalPlanned': _formatDuration(planSummary.totalPlanned),
        'totalActual': _formatDuration(planSummary.totalActual),
        'categories': planSummary.categories
            .map((c) => {
                  'category': c.category,
                  'planned': _formatDuration(c.planned),
                  'actual': _formatDuration(c.actual),
                })
            .toList(),
      },
      'activeTasks': taskList,
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

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  DateTime _parseDate(String dateStr) {
    return DateTime.parse(dateStr);
  }
}
