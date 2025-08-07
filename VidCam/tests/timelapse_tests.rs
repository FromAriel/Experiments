// ###############################################################
// VidCam/tests/timelapse_tests.rs
// Key Tests       • output_file_naming – ensures mp4 naming convention
// Dependencies    • vidcam::timelapse, tempfile
// Last Major Rev  • 2024-05-?? – additional tests
// ###############################################################

use tempfile::tempdir;
use vidcam::timelapse::compile_timelapse;

#[test]
fn output_file_naming() {
    let dir = tempdir().unwrap();
    let out = compile_timelapse(dir.path(), dir.path()).unwrap();
    let name = out.file_name().unwrap().to_string_lossy();
    assert!(name.starts_with("output_"));
    assert!(name.ends_with(".mp4"));
    assert!(out.exists());
}
