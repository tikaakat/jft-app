import 'package:flutter/foundation.dart';

/// Analytics facade. Events: quiz_start, quiz_complete, paywall_view, purchase.
/// Currently logs to the console; plug Firebase Analytics in here later.
class Analytics {
  const Analytics();

  void log(String event, [Map<String, Object> params = const {}]) {
    debugPrint('[analytics] $event $params');
  }
}
