"use strict";
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// index.ts
var index_exports = {};
__export(index_exports, {
  getToken: () => getToken,
  onNotificationReceived: () => onNotificationReceived,
  onNotificationTapped: () => onNotificationTapped,
  onTokenRefresh: () => onTokenRefresh,
  requestPermission: () => requestPermission
});
module.exports = __toCommonJS(index_exports);
var import_core = require("@tauri-apps/api/core");
async function requestPermission() {
  return (0, import_core.invoke)("plugin:mobile-push|request_permission");
}
async function getToken() {
  const result = await (0, import_core.invoke)(
    "plugin:mobile-push|get_token"
  );
  return result.token;
}
async function onNotificationReceived(handler) {
  return (0, import_core.addPluginListener)(
    "mobile-push",
    "notification-received",
    handler
  );
}
async function onNotificationTapped(handler) {
  return (0, import_core.addPluginListener)(
    "mobile-push",
    "notification-tapped",
    handler
  );
}
async function onTokenRefresh(handler) {
  return (0, import_core.addPluginListener)(
    "mobile-push",
    "token-received",
    handler
  );
}
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {
  getToken,
  onNotificationReceived,
  onNotificationTapped,
  onTokenRefresh,
  requestPermission
});
