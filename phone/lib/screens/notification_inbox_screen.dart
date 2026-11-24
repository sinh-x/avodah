import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/inbox_notification.dart';
import '../services/agent_api_client.dart';
import '../services/browser_pairing_service.dart';
import '../services/notification_push_client.dart';

class NotificationInboxScreen extends StatefulWidget {
  final AgentApiClient apiClient;
  final NotificationPushClient? pushClient;
  const NotificationInboxScreen({
    super.key,
    required this.apiClient,
    this.pushClient,
  });

  @override
  State<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends State<NotificationInboxScreen>
    with WidgetsBindingObserver {
  List<InboxNotification> _items = [];
  int? _nextOffset;
  String? _error;
  bool _loading = false, _editing = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool more = false}) async {
    if (_loading || _editing) return;
    setState(() => _loading = true);
    try {
      final items = more
          ? List<InboxNotification>.of(_items)
          : <InboxNotification>[];
      var offset = more ? _nextOffset : 0;
      int? next;
      do {
        final page = await widget.apiClient.listNotifications(
          offset: offset ?? 0,
        );
        items.addAll(page.items);
        next = page.nextOffset;
        offset = next;
      } while (!more && next != null && items.length < _items.length);
      if (mounted) {
        setState(() {
          _items = items;
          _nextOffset = next;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () =>
              _error = 'Inbox unavailable. Displayed records may be stale. $e',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _change(Future<void> Function() action) async {
    setState(() => _editing = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AgentApiException && e.statusCode == 409
                  ? 'Changed on another device. Refreshed; review before trying again.'
                  : 'Edit not confirmed. Refresh before retrying. $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _editing = false);
        await _refresh();
      }
    }
  }

  Future<void> _details(InboxNotification item) async {
    final remarks = TextEditingController(text: item.remarks);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.createdAt),
                const SizedBox(height: 12),
                SelectableText(item.body),
                const SizedBox(height: 20),
                TextField(
                  controller: remarks,
                  maxLength: 16000,
                  minLines: 3,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Remarks',
                    border: OutlineInputBorder(),
                  ),
                ),
                const Text('Remarks are notes only, not replies or approvals.'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: _error == null && !_editing
                ? () => Navigator.pop(context, remarks.text)
                : null,
            child: const Text('Save remarks'),
          ),
        ],
      ),
    );
    // Dispose after the route transition has released its TextField.
    Future<void>.delayed(const Duration(seconds: 1), remarks.dispose);
    if (value != null && value != item.remarks && mounted) {
      // Preserve draft text on conflict/failure so it can be copied and reapplied.
      try {
        setState(() => _editing = true);
        await widget.apiClient.updateNotification(item, remarks: value);
      } catch (e) {
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Remarks were not confirmed saved'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Refresh and review the latest record before reapplying. $e',
                    ),
                    const SizedBox(height: 12),
                    SelectableText(value),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _editing = false);
          await _refresh();
        }
      }
    }
  }

  Future<void> _pairBrowser() async {
    final service = BrowserPairingService(widget.apiClient);
    try {
      final key = await service.start();
      if (!mounted) return;
      final code = TextEditingController();
      final entered = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pair this browser'),
          content: TextField(
            controller: code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Code shown on server console',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, code.text),
              child: const Text('Pair'),
            ),
          ],
        ),
      );
      Future<void>.delayed(const Duration(seconds: 1), code.dispose);
      if (entered != null) {
        await service.confirm(entered, key);
        await _refresh();
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Pairing failed: $e');
    }
  }

  Future<void> _delete(InboxNotification item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete notification?'),
        content: const Text(
          'This removes the record from the shared inbox on all devices. Dismissing an Android alert does not delete it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _change(() => widget.apiClient.deleteNotification(item));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notifications'),
      actions: [
        if (kIsWeb)
          IconButton(
            onPressed: _pairBrowser,
            icon: const Icon(Icons.link),
            tooltip: 'Pair this browser',
          ),
        IconButton(
          onPressed: _loading ? null : _refresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh inbox',
        ),
      ],
    ),
    body: Column(
      children: [
        if (widget.pushClient != null)
          ListenableBuilder(
            listenable: widget.pushClient!,
            builder: (context, _) {
              final push = widget.pushClient!;
              return Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Text(
                      push.enabled
                          ? 'Android alerts opted in'
                          : 'Android alerts not enabled',
                    ),
                    if (push.error != null) Text(push.error!),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: push.busy ? null : push.enable,
                          child: const Text('Enable / reconnect alerts'),
                        ),
                        TextButton(
                          onPressed: push.busy ? null : push.disable,
                          child: const Text('Disable alerts'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_error!, key: const Key('inbox-error')),
          ),
        Expanded(
          child: _items.isEmpty
              ? Center(
                  child: Text(
                    _loading
                        ? 'Loading inbox…'
                        : _error == null
                        ? 'No notifications yet.'
                        : 'Connect and refresh to view the inbox.',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    itemCount: _items.length + (_nextOffset != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _items.length) {
                        return TextButton(
                          onPressed: () => _refresh(more: true),
                          child: const Text('Load older notifications'),
                        );
                      }
                      final item = _items[index];
                      final enabled = !_loading && !_editing && _error == null;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  item.read
                                      ? Icons.drafts_outlined
                                      : Icons.markunread,
                                ),
                                title: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontWeight: item.read
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${item.createdAt}\n${item.handled ? 'Handled' : 'Not handled'}',
                                ),
                                onTap: () => _details(item),
                              ),
                              Text(
                                item.body,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.remarks.isNotEmpty)
                                Text(
                                  'Remarks: ${item.remarks}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Wrap(
                                spacing: 8,
                                children: [
                                  TextButton(
                                    onPressed: enabled
                                        ? () => _change(() async {
                                            await widget.apiClient
                                                .updateNotification(
                                                  item,
                                                  read: !item.read,
                                                );
                                          })
                                        : null,
                                    child: Text(
                                      item.read ? 'Mark unread' : 'Mark read',
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: enabled
                                        ? () => _change(() async {
                                            await widget.apiClient
                                                .updateNotification(
                                                  item,
                                                  handled: !item.handled,
                                                );
                                          })
                                        : null,
                                    child: Text(
                                      item.handled
                                          ? 'Mark unhandled'
                                          : 'Mark handled',
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _details(item),
                                    child: const Text('Details / remarks'),
                                  ),
                                  IconButton(
                                    onPressed: enabled
                                        ? () => _delete(item)
                                        : null,
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: 'Delete notification',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    ),
  );
}
