// ###############################################################
// VidCam/src/config.rs
// Key Structs      • Config – persistent user settings
// Key Functions    • load_config() – read settings from disk
//                   • save_config() – write settings to disk
// Critical Consts  • CONFIG_PATH – default config location
// Dependencies     • serde_json, chrono
// Last Major Rev   • 2024-05-?? – initial scaffold
// ###############################################################

use chrono::Local;
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::{Path, PathBuf};
use tokio::task;

const CONFIG_PATH: &str = "config.json";

#[derive(Debug, Serialize, Deserialize, PartialEq, Clone)]
pub struct Config {
    pub window_position: (i32, i32),
    pub window_size: (u32, u32),
    pub base_opacity: f32,
    pub last_save_dir: PathBuf,
    pub auto_compile: bool,
    pub rtsp_url: String,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            window_position: (0, 0),
            window_size: (300, 200),
            base_opacity: 0.05,
            last_save_dir: PathBuf::from("timelapse"),
            auto_compile: true,
            rtsp_url: "rtsp://fromariel%40gmail.com:VMonkey%21%401@192.168.1.169:554/stream1"
                .to_string(),
        }
    }
}

pub fn load_config() -> Result<Config, Box<dyn std::error::Error>> {
    load_config_from(Path::new(CONFIG_PATH))
}

pub fn save_config(cfg: &Config) -> Result<(), Box<dyn std::error::Error>> {
    save_config_to(cfg, Path::new(CONFIG_PATH))
}

pub fn load_config_from(path: &Path) -> Result<Config, Box<dyn std::error::Error>> {
    let data = fs::read_to_string(path)?;
    let cfg = serde_json::from_str(&data)?;
    Ok(cfg)
}

pub fn save_config_to(cfg: &Config, path: &Path) -> Result<(), Box<dyn std::error::Error>> {
    let data = serde_json::to_string_pretty(cfg)?;
    fs::write(path, data)?;
    Ok(())
}

/// Save configuration without blocking the main task.
pub fn save_config_async(cfg: Config) {
    task::spawn_blocking(move || {
        let _ = save_config(&cfg);
    });
}

/// Generate a timestamped frame path within the configured directory.
pub fn next_frame_path(dir: &Path) -> PathBuf {
    dir.join(format!("{}.jpg", Local::now().format("%Y%m%d_%H%M%S")))
}
