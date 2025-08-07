// ###############################################################
// VidCam/src/capture.rs
// Key Functions    • save_frame() – write decoded frame to disk
//                   • capture_loop() – periodic capture scheduler
// Critical Consts  • none
// Dependencies     • chrono, image, tokio
// Last Major Rev   • 2024-05-?? – initial scaffold
// ###############################################################

use chrono::Local;
use crate::frame::RawFrame;
use image::{DynamicImage, ImageFormat, RgbaImage};
use std::fs;
use std::path::{Path, PathBuf};
use tokio::sync::broadcast;
use tokio::time::{self, Duration};

/// Save the provided frame to disk using timestamp-based naming.
pub fn save_frame(frame: &RawFrame, dir: &Path) -> image::ImageResult<PathBuf> {
    fs::create_dir_all(dir)?;
    let filename = dir.join(format!("{}.jpg", Local::now().format("%Y%m%d_%H%M%S")));
    let img: RgbaImage = RgbaImage::from_raw(frame.width, frame.height, frame.data.clone())
        .ok_or(image::ImageError::Limits(image::error::LimitError::from_kind(
            image::error::LimitErrorKind::DimensionError,
        )))?;
    DynamicImage::ImageRgba8(img).save_with_format(&filename, ImageFormat::Jpeg)?;
    Ok(filename)
}

/// Capture the latest frame once per second and persist it.
const MAX_ERRORS: usize = if cfg!(test) { 3 } else { 5 };

/// Capture the latest frame once per second and persist it.
pub async fn capture_loop(mut rx: broadcast::Receiver<RawFrame>, dir: PathBuf) {
    fs::create_dir_all(&dir).ok();
    let mut interval = time::interval(Duration::from_secs(1));
    let mut latest: Option<RawFrame> = None;
    let mut errors = 0usize;
    loop {
        tokio::select! {
            _ = interval.tick() => {
                if let Some(ref frame) = latest {
                    if let Err(e) = save_frame(frame, &dir) {
                        errors += 1;
                        eprintln!("capture error: {e}");
                        if errors >= MAX_ERRORS {
                            eprintln!("capture halted after repeated errors");
                            return;
                        }
                    } else {
                        errors = 0;
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
