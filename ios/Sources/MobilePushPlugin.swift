import UIKit
import WebKit
import UserNotifications
import Tauri

@objc(MobilePushPlugin)
public class MobilePushPlugin: Plugin {
    public static var instance: MobilePushPlugin?

    /// Pending getToken invoke — resolved when handleToken() is called from AppDelegate.
    private var pendingTokenInvoke: Invoke?

    override public func load(webview: WKWebView) {
        MobilePushPlugin.instance = self
    }

    // MARK: - Commands

    @objc override public func requestPermissions(_ invoke: Invoke) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                invoke.reject(error.localizedDescription)
                return
            }
            invoke.resolve(["granted": granted])
        }
    }

    @objc public func getToken(_ invoke: Invoke) {
        // Store the invoke — it will be resolved when handleToken() is called
        // from the AppDelegate after registerForRemoteNotifications succeeds.
        self.pendingTokenInvoke = invoke

        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    // MARK: - AppDelegate callbacks

    /// Called from AppDelegate's didRegisterForRemoteNotificationsWithDeviceToken.
    public func handleToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()

        // Resolve the pending getToken invoke if present
        if let invoke = self.pendingTokenInvoke {
            invoke.resolve(["token": tokenString])
            self.pendingTokenInvoke = nil
        }

        // Also fire the event for listeners
        self.trigger("token-received", data: ["token": tokenString])
    }

    /// Called from AppDelegate's didFailToRegisterForRemoteNotificationsWithError.
    public func handleTokenError(_ error: Error) {
        if let invoke = self.pendingTokenInvoke {
            invoke.reject(error.localizedDescription)
            self.pendingTokenInvoke = nil
        }
    }

    /// Called from AppDelegate when a notification arrives in the foreground.
    public func handleNotification(_ userInfo: [AnyHashable: Any]) {
        var data: JSObject = [:]
        for (key, value) in userInfo {
            guard let stringKey = key as? String else { continue }
            if let stringValue = value as? String {
                data[stringKey] = stringValue
            } else if let numberValue = value as? NSNumber {
                data[stringKey] = numberValue.intValue
            }
        }
        self.trigger("notification-received", data: data)
    }

    /// Called when the user taps a notification.
    public func handleNotificationTap(_ userInfo: [AnyHashable: Any]) {
        var data: JSObject = [:]
        for (key, value) in userInfo {
            guard let stringKey = key as? String else { continue }
            if let stringValue = value as? String {
                data[stringKey] = stringValue
            } else if let numberValue = value as? NSNumber {
                data[stringKey] = numberValue.intValue
            }
        }
        self.trigger("notification-tapped", data: data)
    }
}

@_cdecl("init_plugin_mobile_push")
func initPlugin() -> Plugin {
    return MobilePushPlugin()
}
