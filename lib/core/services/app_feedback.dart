import 'package:flutter/services.dart';

class AppFeedback {
  static bool enabled = true;
  static const _channel = MethodChannel('com.pendodol.ownerwaroeng/feedback');
  static Future<void> play({bool success = false}) async {
    if (!enabled) return;
    try {
      await _channel.invokeMethod<void>('play', success ? 'success' : 'click');
    } on PlatformException {
      /* Sound must never change a saved transaction result. */
    } on MissingPluginException {
      /* Desktop/widget tests have no Android sound engine. */
    }
  }
}
