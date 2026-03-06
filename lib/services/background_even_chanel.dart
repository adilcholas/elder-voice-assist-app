import 'dart:async';
import 'package:flutter/services.dart';

class BackgroundEventChannel {
  static const EventChannel _channel =
      EventChannel('elder_voice/background_events');

  static Stream<String> get events {
    return _channel.receiveBroadcastStream().map((event) => event.toString());
  }
}