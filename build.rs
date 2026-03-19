fn main() {
    tauri_plugin::Builder::new(&["request_permission", "get_token"])
        .android_path("android")
        .ios_path("ios")
        .build();
}
