import 'dart:async';

import 'package:flutter/services.dart';

class ReplayKitLauncher {
  static const MethodChannel _channel =
      const MethodChannel('replay_kit_launcher');

  /// 用于事件检测
  final EventChannel eventChannel =
      EventChannel('plugins.flutter.io/replay.event.channel');

  /// This function will directly create a free RPSystemBroadcastPickerView and automatically click the View to launch ReplayKit
  ///
  /// [extensionName] is your `BroadCast Upload Extension` target's `Product Name`,
  /// or to be precise, the file name of the `.appex` product of the extension
  static Future<bool?> launchReplayKitBroadcast(String extensionName) async {
    return await _channel.invokeMethod(
        'launchReplayKitBroadcast', {'extensionName': extensionName});
  }

  /// This function will post a notification by `CFNotificationCenterPostNotification()` with `notificationName`
  ///
  /// Developers need to implement the logic to finish broadcast after receiving the notification
  /// That is, invoke `-[RPBroadcastSampleHandler finishBroadcastWithError:]` when received the notification
  ///
  /// For specific implementation, please refer to `example/ios/BroadcastDemoExtension/SampleHandler.m`
  static Future<bool?> finishReplayKitBroadcast(String notificationName) async {
    if (notificationName.length <= 0) {
      return false;
    }

    return await _channel.invokeMethod(
        'finishReplayKitBroadcast', {'notificationName': notificationName});
  }

  /// 检测是否开启了屏幕共享
  Future<bool?> isScreen() async {
    return await _channel.invokeMethod('isScreen');
  }
}
