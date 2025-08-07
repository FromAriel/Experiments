// ###############################################################
// VidCam/src/main.rs
// Key Functions    • main() – bootstrap async tasks and overlay
// Dependencies     • config, rtsp, overlay, capture, timelapse
// Last Major Rev   • 2024-05-?? – async integration
// ###############################################################

use std::sync::{Arc, Mutex};
use vidcam::capture;
use vidcam::config::{load_config, save_config, save_config_async, Config};
use vidcam::overlay::run_overlay;
use vidcam::rtsp::RtspClient;
use vidcam::timelapse;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Spin up async runtime
    let rt = tokio::runtime::Runtime::new()?;

    // Load configuration or create defaults
    let cfg = load_config().unwrap_or_else(|_| {
        let cfg = Config::default();
        let _ = save_config(&cfg);
        cfg
    });
    let shared_cfg = Arc::new(Mutex::new(cfg));

    // Start RTSP client and frame capture loop
    let (client, frame_rx) = {
        let url = shared_cfg.lock().unwrap().rtsp_url.clone();
        RtspClient::new(url)
    };
    let capture_dir = shared_cfg.lock().unwrap().last_save_dir.clone();
    rt.spawn(client.run());
    rt.spawn(capture::capture_loop(frame_rx.resubscribe(), capture_dir.clone()));

    // Run overlay (blocking) on current thread
    run_overlay(shared_cfg.clone(), frame_rx)?;

    // Persist config and optionally compile timelapse on exit
    let final_cfg = shared_cfg.lock().unwrap().clone();
    rt.block_on(async move {
        save_config_async(final_cfg.clone());
        if final_cfg.auto_compile {
            let dir = final_cfg.last_save_dir.clone();
            let _ = tokio::task::spawn_blocking(move || {
                let _ = timelapse::compile_timelapse(&dir, &dir);
            })
            .await;
        }
    });

    Ok(())
}
