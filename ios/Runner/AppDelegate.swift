import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // مطلوب من flutter_local_notifications على iOS: يجعل التطبيق مستقبِلًا لأحداث
    // مركز الإشعارات كي تُعرض التذكيرات والتطبيق في المقدمة ويصل حدث النقر عليها.
    // يجب أن يسبق استدعاء super حتى تتمكن الإضافات من الربط عليه بعد ذلك.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
