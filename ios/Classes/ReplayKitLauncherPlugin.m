#import "ReplayKitLauncherPlugin.h"
#import <ReplayKit/ReplayKit.h>


@implementation ReplayKitLauncherPlugin

{
    /// flutter事件流变量
    FlutterEventSink eventSinkAction;
}


static ReplayKitLauncherPlugin* _instance = nil;

+(instancetype) shareInstance
{
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init] ;
    }) ;
    
    return _instance ;
}
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"replay_kit_launcher" binaryMessenger:[registrar messenger]];
    ReplayKitLauncherPlugin* instance = [[ReplayKitLauncherPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    
    FlutterEventChannel* eventChannel =
    [FlutterEventChannel eventChannelWithName:@"plugins.flutter.io/replay.event.channel"
                              binaryMessenger:[registrar messenger]];
    [eventChannel setStreamHandler:instance];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    
    if ([@"launchReplayKitBroadcast" isEqualToString:call.method]) {
        // Add an observer for stop broadcast notification
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        (__bridge const void *)(self),
                                        onBroadcastFinish,
                                        (CFStringRef)@"ZGFinishBroadcastUploadExtensionProcessENDNotification",
                                        NULL,
                                        CFNotificationSuspensionBehaviorDeliverImmediately);
        
        [self launchReplayKitBroadcast:call.arguments[@"extensionName"] result:result];
        
    } else if ([@"isScreen" isEqualToString:call.method]) {
        /// 真正判断是否开启屏幕共享
        UIScreen *mainScreen = [UIScreen mainScreen];
        /// 只有在iOS11版本及以上才进行判断
        if (@available(iOS 11.0, *)) {
            ///mainScreen.isCaptured 为 true 表示当前已经开启屏幕共享，否则就没开启屏幕共享
            ///这里发送数据到flutter那边接收处理。
            if (mainScreen.isCaptured) {
                /// 发送数据前判断 eventSinkAction 是否为空，否则发送的话就会报错崩溃。
                if(eventSinkAction!=NULL)eventSinkAction(@"ScreenOpened");
            } else {
                if(eventSinkAction!=NULL)eventSinkAction(@"ScreenClosed");
            }
        }
        
    } else if ([@"finishReplayKitBroadcast" isEqualToString:call.method]) {
        
        NSString *notificationName = call.arguments[@"notificationName"];
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)notificationName, NULL, nil, YES);
        result(@(YES));
        
    } else {
        result(FlutterMethodNotImplemented);
    }
}

// Handle stop broadcast notification from main app process
void onBroadcastFinish(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    // Remove observer for stop broadcast notification
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                       NULL,
                                       (CFStringRef)@"ZGFinishBroadcastUploadExtensionProcessENDNotification",
                                       NULL);
}

- (void)launchReplayKitBroadcast:(NSString *)extensionName result:(FlutterResult)result {
    if (@available(iOS 12.0, *)) {
        
        RPSystemBroadcastPickerView *broadcastPickerView = [[RPSystemBroadcastPickerView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:extensionName ofType:@"appex" inDirectory:@"PlugIns"];
        if (!bundlePath) {
            NSString *nullBundlePathErrorMessage = [NSString stringWithFormat:@"Can not find path for bundle `%@.appex`", extensionName];
            NSLog(@"%@", nullBundlePathErrorMessage);
            result([FlutterError errorWithCode:@"NULL_BUNDLE_PATH" message:nullBundlePathErrorMessage details:nil]);
            return;
        }
        
        NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
        if (!bundle) {
            NSString *nullBundleErrorMessage = [NSString stringWithFormat:@"Can not find bundle at path: `%@`", bundlePath];
            NSLog(@"%@", nullBundleErrorMessage);
            result([FlutterError errorWithCode:@"NULL_BUNDLE" message:nullBundleErrorMessage details:nil]);
            return;
        }
        
        broadcastPickerView.preferredExtension = bundle.bundleIdentifier;
        
        
        // Traverse the subviews to find the button to skip the step of clicking the system view
        
        // This solution is not officially recommended by Apple, and may be invalid in future system updates
        
        // The safe solution is to directly add RPSystemBroadcastPickerView as subView to your view
        
        for (UIView *subView in broadcastPickerView.subviews) {
            if ([subView isMemberOfClass:[UIButton class]]) {
                UIButton *button = (UIButton *)subView;
                [button sendActionsForControlEvents:UIControlEventAllEvents];
            }
        }
        result(@(YES));
        
    } else {
        NSString *notAvailiableMessage = @"RPSystemBroadcastPickerView is only available on iOS 12.0 or above";
        NSLog(@"%@", notAvailiableMessage);
        result([FlutterError errorWithCode:@"NOT_AVAILIABLE" message:notAvailiableMessage details:nil]);
    }
    
}


#pragma mark FlutterStreamHandler impl

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    NSLog(@"onListenWithArguments");
    /// 赋值[eventSinkAction]
    eventSinkAction = eventSink;
    return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    /// 关闭时候设置eventSinkAction为空，这样的话调用isScreen就不会再触发了。
    eventSinkAction = nil;
    return nil;
}
@end
