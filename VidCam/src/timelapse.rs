// ###############################################################
// VidCam/src/timelapse.rs
// Key Functions    • compile_timelapse() – combine frames into video
// Critical Consts  • none
// Dependencies     • chrono, std::process (ffmpeg placeholder)
// Last Major Rev   • 2024-05-?? – initial scaffold
// ###############################################################

use chrono::Local;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::io::{BufRead, BufReader};

/// Compile captured frames into an MP4 using `ffmpeg`.
/// For now, this creates an empty file as a placeholder.
pub fn compile_timelapse(frames_dir: &Path, output_dir: &Path) -> std::io::Result<PathBuf> {
    fs::create_dir_all(output_dir)?;
    let output = output_dir.join(format!(
        "output_{}.mp4",
        Local::now().format("%Y%m%d_%H%M%S")
    ));

    let input = frames_dir.join("*.jpg").to_string_lossy().replace('\\', "/");
    let total = fs::read_dir(frames_dir)?.filter(|e| e.as_ref().ok().map_or(false, |e| e.path().extension().map_or(false, |ext| ext == "jpg"))).count();

    let mut cmd = Command::new("ffmpeg");
    cmd.arg("-y")
        .arg("-framerate").arg("1")
        .arg("-pattern_type").arg("glob")
        .arg("-i").arg(input)
        .arg("-progress").arg("pipe:1")
        .arg(&output)
        .stdout(Stdio::piped())
        .stderr(Stdio::null());

    let child = cmd.spawn();
    let mut child = match child {
        Ok(c) => c,
        Err(e) => {
            eprintln!("ffmpeg not found: {e}");
            fs::write(&output, b"")?;
            return Ok(output);
        }
    };

    if let Some(stdout) = child.stdout.take() {
        let mut reader = BufReader::new(stdout);
        let mut line = String::new();
        while reader.read_line(&mut line)? > 0 {
            if let Some(frame_str) = line.strip_prefix("frame=") {
                if let Ok(frame) = frame_str.trim().parse::<usize>() {
                    let pct = if total > 0 { frame * 100 / total } else { 0 };
                    println!("timelapse progress: {}%", pct);
                }
            }
            if line.trim() == "progress=end" {
                break;
            }
            line.clear();
        }
    }
    let _ = child.wait();
    if !output.exists() {
        fs::write(&output, b"")?;
    }
    Ok(output)
}
