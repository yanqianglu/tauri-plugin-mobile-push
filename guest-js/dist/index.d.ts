import { PluginListener } from '@tauri-apps/api/core';

/** Payload delivered with push notification events. */
interface PushNotification {
    title?: string;
    body?: string;
    data: Record<string, unknown>;
    badge?: number;
    sound?: string;
}
/**
 * Request permission to display push notifications.
 *
 * On iOS this triggers the system permission dialog. On Android 13+
 * (API 33) it requests the `POST_NOTIFICATIONS` runtime permission.
 * Earlier Android versions return `{ granted: true }` immediately.
 */
declare function requestPermission(): Promise<{
    granted: boolean;
}>;
/**
 * Return the current device push token.
 *
 * - iOS: APNs device token (hex string)
 * - Android: FCM registration token
 *
 * The token may change over the lifetime of the app. Use
 * {@link onTokenRefresh} to stay up-to-date.
 */
declare function getToken(): Promise<string>;
/**
 * Called when a push notification is received while the app is in the
 * foreground.
 */
declare function onNotificationReceived(handler: (notification: PushNotification) => void): Promise<PluginListener>;
/**
 * Called when the user taps a push notification to open the app.
 */
declare function onNotificationTapped(handler: (notification: PushNotification) => void): Promise<PluginListener>;
/**
 * Called when the platform issues a new push token (e.g., after an
 * APNs token refresh or FCM token rotation). Send the new token to
 * your backend whenever this fires.
 */
declare function onTokenRefresh(handler: (payload: {
    token: string;
}) => void): Promise<PluginListener>;

export { type PushNotification, getToken, onNotificationReceived, onNotificationTapped, onTokenRefresh, requestPermission };
