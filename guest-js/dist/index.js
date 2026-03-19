// index.ts
import {
  invoke,
  addPluginListener
} from "@tauri-apps/api/core";
async function requestPermission() {
  return invoke("plugin:mobile-push|request_permission");
}
async function getToken() {
  const result = await invoke(
    "plugin:mobile-push|get_token"
  );
  return result.token;
}
async function onNotificationReceived(handler) {
  return addPluginListener(
    "mobile-push",
    "notification-received",
    handler
  );
}
async function onNotificationTapped(handler) {
  return addPluginListener(
    "mobile-push",
    "notification-tapped",
    handler
  );
}
async function onTokenRefresh(handler) {
  return addPluginListener(
    "mobile-push",
    "token-received",
    handler
  );
}
export {
  getToken,
  onNotificationReceived,
  onNotificationTapped,
  onTokenRefresh,
  requestPermission
};
