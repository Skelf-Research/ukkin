import Flutter
import UIKit

/// iOS Automation Plugin
/// Note: iOS has strict sandboxing - cannot read other apps' UI or perform gestures in them
/// This plugin provides graceful degradation with limited capabilities
public class AutomationPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.ukkin/automation",
            binaryMessenger: registrar.messenger()
        )
        let instance = AutomationPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isAccessibilityEnabled":
            // iOS doesn't have equivalent accessibility service for automation
            result(false)

        case "openAccessibilitySettings":
            openSettings()
            result(nil)

        case "getCapabilities":
            result(getCapabilities())

        case "launchApp":
            if let args = call.arguments as? [String: Any],
               let urlScheme = args["urlScheme"] as? String {
                launchApp(urlScheme: urlScheme, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "urlScheme required", details: nil))
            }

        case "canLaunchApp":
            if let args = call.arguments as? [String: Any],
               let urlScheme = args["urlScheme"] as? String {
                result(canLaunchApp(urlScheme: urlScheme))
            } else {
                result(false)
            }

        case "triggerShortcut":
            if let args = call.arguments as? [String: Any],
               let shortcutName = args["name"] as? String {
                triggerShortcut(name: shortcutName, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "name required", details: nil))
            }

        case "shareContent":
            if let args = call.arguments as? [String: Any] {
                shareContent(args: args, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "content required", details: nil))
            }

        case "openURL":
            if let args = call.arguments as? [String: Any],
               let urlString = args["url"] as? String {
                openURL(urlString: urlString, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "url required", details: nil))
            }

        // Unsupported operations - return graceful failure
        case "getScreenContent",
             "findElementByText",
             "clickOnText",
             "clickAt",
             "typeText",
             "scroll",
             "swipe",
             "pressBack",
             "pressHome",
             "getCurrentPackage",
             "extractAllText",
             "waitForElement":
            result(FlutterError(
                code: "UNSUPPORTED",
                message: "This operation is not supported on iOS due to platform restrictions",
                details: [
                    "reason": "iOS sandboxing prevents apps from reading or controlling other apps",
                    "alternatives": ["Use URL schemes to launch apps", "Use Shortcuts app for automation"]
                ]
            ))

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Capabilities

    private func getCapabilities() -> [String: Any] {
        return [
            "platform": "iOS",
            "canReadScreen": false,
            "canPerformTaps": false,
            "canTypeText": false,
            "canLaunchApps": true,
            "canUseShortcuts": true,
            "canShareContent": true,
            "canOpenURLs": true,
            "limitations": [
                "iOS sandboxing prevents reading other apps' content",
                "Cannot perform gestures in other apps",
                "App launching limited to registered URL schemes"
            ],
            "supportedFeatures": [
                "launchApp - Open apps via URL schemes",
                "triggerShortcut - Run Siri Shortcuts",
                "shareContent - Share via system share sheet",
                "openURL - Open URLs in Safari or appropriate app"
            ]
        ]
    }

    // MARK: - App Launching

    private func canLaunchApp(urlScheme: String) -> Bool {
        guard let url = URL(string: urlScheme + "://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    private func launchApp(urlScheme: String, result: @escaping FlutterResult) {
        var urlString = urlScheme
        if !urlScheme.contains("://") {
            urlString = urlScheme + "://"
        }

        guard let url = URL(string: urlString) else {
            result(FlutterError(code: "INVALID_URL", message: "Invalid URL scheme", details: nil))
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
                result(success)
            }
        } else {
            result(false)
        }
    }

    // MARK: - Shortcuts Integration

    private func triggerShortcut(name: String, result: @escaping FlutterResult) {
        // Open Shortcuts app with the specified shortcut
        // Format: shortcuts://run-shortcut?name=ShortcutName
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let urlString = "shortcuts://run-shortcut?name=\(encodedName)"

        guard let url = URL(string: urlString) else {
            result(FlutterError(code: "INVALID_NAME", message: "Invalid shortcut name", details: nil))
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
                result(success)
            }
        } else {
            result(FlutterError(
                code: "SHORTCUTS_UNAVAILABLE",
                message: "Shortcuts app not available",
                details: nil
            ))
        }
    }

    // MARK: - Share Content

    private func shareContent(args: [String: Any], result: @escaping FlutterResult) {
        var items: [Any] = []

        if let text = args["text"] as? String {
            items.append(text)
        }

        if let urlString = args["url"] as? String, let url = URL(string: urlString) {
            items.append(url)
        }

        guard !items.isEmpty else {
            result(FlutterError(code: "NO_CONTENT", message: "No content to share", details: nil))
            return
        }

        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)

            if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                // iPad requires popover presentation
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = rootVC.view
                    popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                }

                rootVC.present(activityVC, animated: true) {
                    result(true)
                }
            } else {
                result(false)
            }
        }
    }

    // MARK: - URL Opening

    private func openURL(urlString: String, result: @escaping FlutterResult) {
        guard let url = URL(string: urlString) else {
            result(FlutterError(code: "INVALID_URL", message: "Invalid URL", details: nil))
            return
        }

        UIApplication.shared.open(url, options: [:]) { success in
            result(success)
        }
    }

    // MARK: - Settings

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

// MARK: - Common URL Schemes Reference
// This provides a mapping of common apps to their URL schemes
public struct CommonAppSchemes {
    static let schemes: [String: String] = [
        "com.apple.safari": "https",
        "com.apple.mobilemail": "mailto",
        "com.apple.mobilesms": "sms",
        "com.apple.facetime": "facetime",
        "com.apple.Maps": "maps",
        "com.apple.Music": "music",
        "com.apple.Preferences": "app-settings",
        "com.google.chrome.ios": "googlechrome",
        "com.google.Gmail": "googlegmail",
        "com.google.Maps": "comgooglemaps",
        "com.google.youtube": "youtube",
        "com.facebook.Facebook": "fb",
        "com.burbn.instagram": "instagram",
        "com.twitter.twitter": "twitter",
        "net.whatsapp.WhatsApp": "whatsapp",
        "com.linkedin.LinkedIn": "linkedin",
        "com.spotify.client": "spotify",
        "com.slack.Slack": "slack",
        "com.microsoft.teams": "msteams",
        "com.zoom.videomeetings": "zoomus"
    ]

    static func getURLScheme(for bundleId: String) -> String? {
        return schemes[bundleId]
    }
}
