use serde::de::DeserializeOwned;
use tauri::{
    plugin::{PluginApi, PluginHandle},
    AppHandle, Runtime,
};

use crate::models::*;

#[cfg(target_os = "ios")]
tauri::ios_plugin_binding!(init_plugin_mobile_push);

/// Initializes the Kotlin or Swift plugin classes.
pub fn init<R: Runtime, C: DeserializeOwned>(
    _app: &AppHandle<R>,
    api: PluginApi<R, C>,
) -> crate::Result<MobilePush<R>> {
    #[cfg(target_os = "android")]
    let handle = api.register_android_plugin("app.tauri.mobilepush", "MobilePushPlugin")?;
    #[cfg(target_os = "ios")]
    let handle = api.register_ios_plugin(init_plugin_mobile_push)?;
    Ok(MobilePush(handle))
}

/// Access to the mobile-push APIs.
pub struct MobilePush<R: Runtime>(PluginHandle<R>);

impl<R: Runtime> MobilePush<R> {
    pub fn request_permission(&self) -> crate::Result<PermissionResponse> {
        self.0
            .run_mobile_plugin("requestPermissions", ())
            .map_err(Into::into)
    }

    pub fn get_token(&self) -> crate::Result<TokenResponse> {
        self.0
            .run_mobile_plugin("getToken", ())
            .map_err(Into::into)
    }
}
