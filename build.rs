fn main() {
    tauri_plugin::Builder::new(&["request_permission", "get_token", "register_listener"])
        .android_path("android")
        .ios_path("ios")
        .build();
}
