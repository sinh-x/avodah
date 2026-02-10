/// MCP Server implementation for Avodah.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avodah_core/avodah_core.dart';
import 'package:avodah_mcp/config/paths.dart';

/// MCP Server that exposes worklog tracking tools.
class McpServer {
  final AppDatabase db;
  final AvodahPaths paths;

  McpServer({
    required this.db,
    required this.paths,
  });

  /// Starts serving MCP over stdio.
  Future<void> serve(Stream<List<int>> input, IOSink output) async {
    // TODO: Implement MCP protocol
    // For now, just a placeholder that reads JSON-RPC requests

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

  Future<Map<String, dynamic>> _handleRequest(Map<String, dynamic> request) async {
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

  Future<Map<String, dynamic>> _handleTimer(Map<String, dynamic> params) async {
    final action = params['action'] as String?;

    switch (action) {
      case 'start':
        // TODO: Implement start timer
        return {
          'ok': true,
          'running': true,
          'task': params['task'] ?? 'Untitled',
          'elapsed': '0m',
        };
      case 'stop':
        // TODO: Implement stop timer
        return {
          'ok': true,
          'running': false,
          'logged': '0m → Task',
        };
      case 'status':
        // TODO: Implement status
        return {
          'ok': true,
          'running': false,
        };
      default:
        throw Exception('Unknown timer action: $action');
    }
  }

  Future<Map<String, dynamic>> _handleTasks(Map<String, dynamic> params) async {
    final action = params['action'] as String?;

    switch (action) {
      case 'list':
        // TODO: Implement list tasks
        return {
          'ok': true,
          'tasks': <Map<String, dynamic>>[],
        };
      case 'add':
        // TODO: Implement add task
        return {
          'ok': true,
          'created': {
            'id': 'placeholder',
            'title': params['title'],
          },
        };
      default:
        throw Exception('Unknown tasks action: $action');
    }
  }

  Future<Map<String, dynamic>> _handleToday(Map<String, dynamic> params) async {
    // TODO: Implement today summary
    final now = DateTime.now();
    return {
      'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'total': '0m',
      'tasks': <Map<String, dynamic>>[],
    };
  }

  Future<Map<String, dynamic>> _handleJira(Map<String, dynamic> params) async {
    final action = params['action'] as String?;

    switch (action) {
      case 'sync':
        // TODO: Implement Jira sync
        return {
          'ok': true,
          'pulled': 0,
          'pushed': 0,
        };
      case 'status':
        // TODO: Implement Jira status
        return {
          'ok': true,
          'configured': false,
        };
      default:
        throw Exception('Unknown jira action: $action');
    }
  }
}
