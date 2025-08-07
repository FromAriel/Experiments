// ###############################################################
// VidCam/tests/overlay_tests.rs
// Key Test        • geometry_persisted – overlay saves new size/pos
// Dependencies    • vidcam::overlay, tempfile
// ###############################################################

use std::sync::{Arc, Mutex};
use tempfile::tempdir;
use vidcam::config::{load_config_from, save_config_to, Config};
use vidcam::overlay::run_overlay_headless_once;
use std::time::Duration;
use std::thread::sleep;
use eframe::egui;

#[test]
fn geometry_persisted() {
    if std::env::var("DISPLAY").is_err() && std::env::var("WAYLAND_DISPLAY").is_err() {
        eprintln!("skipping test: no display available");
        return;
    }
    let dir = tempdir().unwrap();
    std::env::set_var("VIDCAM_ROOT", dir.path());
    let mut cfg = Config::default();
    save_config_to(&cfg, &dir.path().join("config.json")).unwrap();
    let shared = Arc::new(Mutex::new(cfg));
    run_overlay_headless_once(shared.clone(), |ctx| {
        ctx.send_viewport_cmd(egui::ViewportCommand::InnerSize(egui::Vec2::new(400.0,300.0)));
        ctx.send_viewport_cmd(egui::ViewportCommand::OuterPosition(egui::Pos2::new(10.0,20.0)));
        ctx.send_viewport_cmd(egui::ViewportCommand::Close);
    });
    sleep(Duration::from_millis(1500));
    let cfg = load_config_from(&dir.path().join("config.json")).unwrap();
    assert_eq!(cfg.window_size, (400,300));
    assert_eq!(cfg.window_position, (10,20));
}
