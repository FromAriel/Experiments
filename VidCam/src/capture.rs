// ###############################################################
// VidCam/src/capture.rs
// Key Functions    • save_frame() – write decoded frame to disk
//                   • capture_loop() – periodic capture scheduler
// Critical Consts  • none
// Dependencies     • chrono, image, tokio
// Last Major Rev   • 2024-05-?? – initial scaffold
// ###############################################################

use chrono::Local;
use image::{DynamicImage, ImageFormat};
use std::fs;
use std::path::{Path, PathBuf};
use tokio::sync::broadcast;
use tokio::time::{self, Duration};

/// Save the provided frame to disk using timestamp-based naming.
pub fn save_frame(frame: &DynamicImage, dir: &Path) -> image::ImageResult<PathBuf> {
    fs::create_dir_all(dir)?;
    let filename = dir.join(format!("{}.jpg", Local::now().format("%Y%m%d_%H%M%S")));
    frame.save_with_format(&filename, ImageFormat::Jpeg)?;
    Ok(filename)
}

/// Capture the latest frame once per second and persist it.
pub async fn capture_loop(
    mut rx: broadcast::Receiver<DynamicImage>,
    dir: PathBuf,
) {
    fs::create_dir_all(&dir).ok();
    let mut interval = time::interval(Duration::from_secs(1));
    let mut latest: Option<DynamicImage> = None;
    loop {
        tokio::select! {
            _ = interval.tick() => {
                if let Some(ref frame) = latest {
                    if let Err(e) = save_frame(frame, &dir) {
                        eprintln!("capture error: {e}");
                    }
                }
            }
            Ok(frame) = rx.recv() => {
                latest = Some(frame);
            }
            else => break,
        }
    }
}
