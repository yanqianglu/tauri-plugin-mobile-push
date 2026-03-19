use tauri::{
    plugin::{Builder, TauriPlugin},
    Manager, Runtime,
};

pub use models::*;

#[cfg(desktop)]
mod desktop;
#[cfg(mobile)]
mod mobile;

mod commands;
mod error;
mod models;

pub use error::{Error, Result};

#[cfg(desktop)]
use desktop::MobilePush;
#[cfg(mobile)]
use mobile::MobilePush;

/// Extensions to [`tauri::App`], [`tauri::AppHandle`] and [`tauri::Window`] to access the mobile-push APIs.
pub trait MobilePushExt<R: Runtime> {
    fn mobile_push(&self) -> &MobilePush<R>;
}

impl<R: Runtime, T: Manager<R>> MobilePushExt<R> for T {
    fn mobile_push(&self) -> &MobilePush<R> {
        self.state::<MobilePush<R>>().inner()
    }
}

/// Initializes the plugin.
pub fn init<R: Runtime>() -> TauriPlugin<R> {
    Builder::<R, ()>::new("mobile-push")
        .invoke_handler(tauri::generate_handler![
            commands::request_permission,
            commands::get_token
        ])
        .setup(|app, api| {
            #[cfg(mobile)]
            let mobile_push = mobile::init(app, api)?;
            #[cfg(desktop)]
            let mobile_push = desktop::init(app, api)?;
            app.manage(mobile_push);
            Ok(())
        })
        .build()
}
