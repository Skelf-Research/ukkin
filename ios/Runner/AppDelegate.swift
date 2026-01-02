import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Register custom automation plugin for iOS
    AutomationPlugin.register(with: self.registrar(forPlugin: "AutomationPlugin")!)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
