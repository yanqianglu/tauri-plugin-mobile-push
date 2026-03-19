# tauri-plugin-mobile-push

Push notifications for Tauri v2 apps on iOS and Android.

Uses **APNs** (Apple Push Notification service) on iOS and **FCM** (Firebase Cloud Messaging) on Android. Desktop platforms are a graceful no-op.

> **Why not `tauri-plugin-notification`?** The official plugin only supports *local* notifications. This plugin handles **remote/server-sent push notifications** with native APNs and FCM integration.

## Platform Support

| Platform | Token Source | Push Delivery |
|----------|-------------|---------------|
| iOS 13+ | APNs device token | APNs HTTP/2 |
| Android 7+ (API 24) | FCM registration token | FCM HTTP v1 |
| macOS / Windows / Linux | No-op (returns error) | N/A |

On unsupported platforms the plugin registers without error, but commands return an `Err`.

## Install

### Rust

Add to your `src-tauri/Cargo.toml`:

```toml
[dependencies]
tauri-plugin-mobile-push = { git = "https://github.com/yanqianglu/tauri-plugin-mobile-push" }
```

### JavaScript

```bash
npm install tauri-plugin-mobile-push-api
# or
bun add tauri-plugin-mobile-push-api
```

### Permissions

Add to your capabilities file (e.g., `src-tauri/capabilities/mobile.json`):

```json
{
  "permissions": ["mobile-push:default"]
}
```

### Register the Plugin

In `src-tauri/src/lib.rs`:

```rust
tauri::Builder::default()
    .plugin(tauri_plugin_mobile_push::init())
    // ...
```

## iOS Setup

### 1. Enable Push Notifications Capability

In Xcode, select your target, go to **Signing & Capabilities**, and add the **Push Notifications** capability. This adds the `aps-environment` entitlement automatically.

### 2. Create an AppDelegate

The plugin does **not** use method swizzling. You must explicitly forward APNs callbacks to the plugin. Create `src-tauri/gen/apple/Sources/AppDelegate.swift`:

```swift
import SwiftUI
import Tauri
import UIKit
import UserNotifications
import WebKit

class AppDelegate: TauriAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // APNs token received — forward to plugin
    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)

        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        NotificationCenter.default.post(
            name: Notification.Name("APNsTokenReceived"),
            object: nil,
            userInfo: ["token": hex]
        )
    }

    // APNs registration failed
    override func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)

        NotificationCenter.default.post(
            name: Notification.Name("APNsRegistrationFailed"),
            object: nil,
            userInfo: ["error": error.localizedDescription]
        )
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Foreground notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        NotificationCenter.default.post(
            name: Notification.Name("PushNotificationReceived"),
            object: nil,
            userInfo: userInfo as? [String: Any]
        )
        completionHandler([.banner, .sound, .badge])
    }

    // Notification tapped
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        NotificationCenter.default.post(
            name: Notification.Name("PushNotificationTapped"),
            object: nil,
            userInfo: userInfo as? [String: Any]
        )
        completionHandler()
    }
}
```

### 3. Entitlements

Ensure your `.entitlements` file includes:

```xml
<key>aps-environment</key>
<string>development</string>
```

Change to `production` for App Store / TestFlight builds. If you added the Push Notifications capability in Xcode, this is handled automatically.

## Android Setup

### 1. Add Firebase

1. Create a Firebase project and add your Android app.
2. Download `google-services.json` and place it in `src-tauri/gen/android/app/`.
3. Ensure your `build.gradle.kts` applies the Google Services plugin:

```kotlin
// project-level build.gradle.kts
plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}

// app-level build.gradle.kts
plugins {
    id("com.google.gms.google-services")
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.8.0"))
    implementation("com.google.firebase:firebase-messaging")
}
```

### 2. Register the FCM Service

Add to your `AndroidManifest.xml` inside `<application>`:

```xml
<service
    android:name="app.tauri.plugin.mobile_push.FcmService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

## Usage

```typescript
import {
  requestPermission,
  getToken,
  onNotificationReceived,
  onNotificationTapped,
  onTokenRefresh,
} from "tauri-plugin-mobile-push-api";

// 1. Request permission (shows system dialog on iOS / Android 13+)
const { granted } = await requestPermission();
if (!granted) {
  console.warn("Push permission denied");
}

// 2. Get the device push token
const token = await getToken();

// 3. Send token to your backend
await fetch("https://your-api.com/push/register", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ token, platform: "ios" }),
});

// 4. Listen for foreground notifications
const unsubReceived = await onNotificationReceived((notification) => {
  console.log("Notification received:", notification.title, notification.body);
  console.log("Custom data:", notification.data);
});

// 5. Listen for notification taps (app opened from notification)
const unsubTapped = await onNotificationTapped((notification) => {
  console.log("User tapped notification:", notification.data);
  // Navigate to relevant screen based on notification.data
});

// 6. Listen for token refreshes (re-register with your backend)
const unsubToken = await onTokenRefresh(({ token }) => {
  console.log("Token refreshed:", token);
  // Send new token to your backend
});

// Cleanup when done
unsubReceived.unregister();
unsubTapped.unregister();
unsubToken.unregister();
```

## API Reference

### Commands

| Function | Returns | Description |
|----------|---------|-------------|
| `requestPermission()` | `Promise<{ granted: boolean }>` | Request push notification permission |
| `getToken()` | `Promise<string>` | Get the current APNs/FCM device token |

### Event Listeners

| Function | Event Payload | Description |
|----------|--------------|-------------|
| `onNotificationReceived(handler)` | `PushNotification` | Foreground notification received |
| `onNotificationTapped(handler)` | `PushNotification` | User tapped a notification |
| `onTokenRefresh(handler)` | `{ token: string }` | Device token was refreshed |

All event listeners return `Promise<PluginListener>`. Call `.unregister()` on the returned listener to stop receiving events.

### Types

```typescript
interface PushNotification {
  title?: string;
  body?: string;
  data: Record<string, unknown>;
  badge?: number;
  sound?: string;
}
```

## Architecture

This plugin takes an **explicit delegation** approach rather than using method swizzling or automatic configuration:

- **No swizzling.** On iOS, you create an `AppDelegate` that explicitly forwards APNs callbacks to the plugin via `NotificationCenter`. This is more transparent, easier to debug, and avoids conflicts with other plugins or libraries that might also swizzle the same methods.
- **No bundled Firebase SDK.** On Android, you add Firebase as a direct dependency of your app. The plugin provides a `FirebaseMessagingService` subclass that forwards tokens and messages to the Tauri event system.
- **Desktop no-op.** On macOS, Windows, and Linux, the plugin registers without error so your code compiles on all targets. Commands return errors at runtime, letting you gate push logic behind platform checks.

## Sending Push Notifications from Your Server

Once you have the device token, send pushes via:

- **iOS (APNs):** Use the [APNs HTTP/2 API](https://developer.apple.com/documentation/usernotifications/sending-notification-requests-to-apns) with a `.p8` signing key or `.p12` certificate.
- **Android (FCM):** Use the [FCM HTTP v1 API](https://firebase.google.com/docs/cloud-messaging/send-message) with a service account.

The notification payload should include `title`, `body`, and any custom `data` fields your app needs. These will be delivered to your `onNotificationReceived` and `onNotificationTapped` handlers.

## License

Licensed under either of [Apache License, Version 2.0](LICENSE-APACHE) or [MIT License](LICENSE-MIT) at your option.
