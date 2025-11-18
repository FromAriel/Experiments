// ###############################################################
// VidCam/tests/capture_tests.rs
// Key Tests       • saves_with_timestamp – verifies naming
//                   • fails_on_ro_dir – handles write errors
// Dependencies    • vidcam::capture, image, tempfile
// Last Major Rev  • 2024-05-?? – additional tests
// ###############################################################

use image::DynamicImage;
use std::path::Path;
use tempfile::tempdir;
use vidcam::capture::save_frame;

#[test]
fn saves_with_timestamp() {
    let dir = tempdir().unwrap();
    let frame = DynamicImage::new_rgb8(1, 1);
    let path = save_frame(&frame, dir.path()).unwrap();
    assert!(path.file_name().unwrap().to_string_lossy().ends_with(".jpg"));
}

#[test]
fn fails_on_ro_dir() {
    let frame = DynamicImage::new_rgb8(1, 1);
    // Attempt to write into a non-directory path to trigger an error.
    let res = save_frame(&frame, Path::new("/dev/null"));
    assert!(res.is_err());
}
