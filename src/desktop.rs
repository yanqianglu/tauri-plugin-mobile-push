use serde::de::DeserializeOwned;
use tauri::{plugin::PluginApi, AppHandle, Runtime};

use crate::models::*;

pub fn init<R: Runtime, C: DeserializeOwned>(
    app: &AppHandle<R>,
    _api: PluginApi<R, C>,
) -> crate::Result<MobilePush<R>> {
    Ok(MobilePush(app.clone()))
}

/// Access to the mobile-push APIs.
pub struct MobilePush<R: Runtime>(AppHandle<R>);

impl<R: Runtime> MobilePush<R> {
    pub fn request_permission(&self) -> crate::Result<PermissionResponse> {
        Ok(PermissionResponse { granted: false })
    }

    pub fn get_token(&self) -> crate::Result<TokenResponse> {
        Ok(TokenResponse {
            token: String::new(),
        })
    }
}
