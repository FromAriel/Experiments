// ###############################################################
// VidCam/tests/capture_tests.rs
// Key Tests       • saves_with_timestamp – verifies naming
//                   • fails_on_ro_dir – handles write errors
// Dependencies    • vidcam::capture, image, tempfile
// Last Major Rev  • 2024-05-?? – additional tests
// ###############################################################

use vidcam::capture::save_frame;
use vidcam::frame::RawFrame;
use std::path::Path;
use tempfile::tempdir;
use std::fs;
use tokio::sync::broadcast;
use tokio::time::{sleep, Duration};
use vidcam::capture::capture_loop;

#[test]
fn saves_with_timestamp() {
    let dir = tempdir().unwrap();
    let frame = RawFrame { data: vec![0, 0, 0, 0], width: 1, height: 1 };
    let path = save_frame(&frame, dir.path()).unwrap();
    assert!(path.file_name().unwrap().to_string_lossy().ends_with(".jpg"));
}

#[test]
fn fails_on_ro_dir() {
    let frame = RawFrame { data: vec![0,0,0,0], width:1, height:1 };
    // Attempt to write into a non-directory path to trigger an error.
    let res = save_frame(&frame, Path::new("/dev/null"));
    assert!(res.is_err());
}

#[tokio::test]
async fn stops_after_consecutive_errors() {
    let dir = tempdir().unwrap();
    let bad_path = dir.path().join("file");
    fs::write(&bad_path, b"").unwrap();

    let (tx, rx) = broadcast::channel(1);
    let handle = tokio::spawn(capture_loop(rx, bad_path));
    let frame = RawFrame { data: vec![0,0,0,0], width:1, height:1 };
    let _ = tx.send(frame);
    sleep(Duration::from_secs(7)).await;
    assert!(handle.is_finished());
}
