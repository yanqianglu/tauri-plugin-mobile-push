use tauri::{command, AppHandle, Runtime};

use crate::models::*;
use crate::{MobilePushExt, Result};

#[command]
pub(crate) async fn request_permission<R: Runtime>(
    app: AppHandle<R>,
) -> Result<PermissionResponse> {
    app.mobile_push().request_permission()
}

#[command]
pub(crate) async fn get_token<R: Runtime>(app: AppHandle<R>) -> Result<TokenResponse> {
    app.mobile_push().get_token()
}
