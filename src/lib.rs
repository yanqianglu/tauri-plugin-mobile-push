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

/// Initializes the plugin.
pub fn init<R: Runtime>() -> TauriPlugin<R> {
    Builder::<R, ()>::new("mobile-push")
        .invoke_handler(tauri::generate_handler![
            commands::request_permission,
            commands::get_token,
            commands::register_listener
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
