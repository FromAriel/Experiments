// ###############################################################
// VidCam/tests/config_tests.rs
// Key Functions    • round_trip_config() – ensure config save/load works
// Dependencies     • vidcam::config, tempfile
// Last Major Rev   • 2024-05-?? – initial scaffold
// ###############################################################

use tempfile::tempdir;
use vidcam::config::{load_config_from, save_config_to, Config};

#[test]
fn round_trip_config() {
    let dir = tempdir().unwrap();
    let path = dir.path().join("config.json");

    let cfg = Config::default();
    save_config_to(&cfg, &path).unwrap();
    let loaded = load_config_from(&path).unwrap();
    assert_eq!(cfg, loaded);
}
