// ###############################################################
// VidCam/tests/rtsp_tests.rs
// Key Tests       • retry_logic_succeeds – ensures reconnection attempts
// Dependencies    • vidcam::rtsp, tokio
// Last Major Rev  • 2024-05-?? – initial tests
// ###############################################################

use std::sync::atomic::{AtomicUsize, Ordering};
use std::time::Duration;
use vidcam::rtsp::{connect_with_retry, RtspError};

#[tokio::test]
async fn retry_logic_succeeds() {
    let attempts = AtomicUsize::new(0);
    let result = connect_with_retry(
        || {
            let n = attempts.fetch_add(1, Ordering::SeqCst);
            async move {
                if n < 1 {
                    Err(RtspError::StreamEnded)
                } else {
                    Ok(())
                }
            }
        },
        3,
        Duration::from_millis(10),
    )
    .await;
    assert!(result.is_ok());
    assert_eq!(attempts.load(Ordering::SeqCst), 2);
}
