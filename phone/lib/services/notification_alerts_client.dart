import 'package:flutter/foundation.dart';

/// Common UI controls; provider/native delivery remains informational only.
abstract class NotificationAlertsClient extends ChangeNotifier {
  bool get enabled;
  bool get busy;
  String? get error;
  String get description;
  Future<void> restore();
  Future<void> enable();
  Future<void> disable();
}
