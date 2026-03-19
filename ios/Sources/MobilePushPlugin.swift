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
        print("[mobile-push] Plugin loaded, instance set")
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
        print("[mobile-push] getToken called, registering for remote notifications...")
        self.pendingTokenInvoke = invoke

        DispatchQueue.main.async {
            let app = UIApplication.shared
            print("[mobile-push] isRegisteredForRemoteNotifications: \(app.isRegisteredForRemoteNotifications)")
            app.registerForRemoteNotifications()
            print("[mobile-push] registerForRemoteNotifications() called")
        }
    }

    // MARK: - AppDelegate callbacks

    /// Called from AppDelegate's didRegisterForRemoteNotificationsWithDeviceToken.
    public func handleToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        print("[mobile-push] handleToken called: \(tokenString.prefix(16))...")

        // Resolve the pending getToken invoke if present
        if let invoke = self.pendingTokenInvoke {
            print("[mobile-push] Resolving pending getToken invoke")
            invoke.resolve(["token": tokenString])
            self.pendingTokenInvoke = nil
        } else {
            print("[mobile-push] WARNING: handleToken called but no pending invoke")
        }

        // Also fire the event for listeners
        self.trigger("token-received", data: ["token": tokenString])
    }

    /// Called from AppDelegate's didFailToRegisterForRemoteNotificationsWithError.
    public func handleTokenError(_ error: Error) {
        print("[mobile-push] handleTokenError: \(error.localizedDescription)")
        if let invoke = self.pendingTokenInvoke {
            invoke.reject(error.localizedDescription)
            self.pendingTokenInvoke = nil
        } else {
            print("[mobile-push] WARNING: handleTokenError called but no pending invoke")
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
