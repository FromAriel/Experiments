// ###############################################################
// VidCam/src/rtsp.rs
// Key Structs      • RtspClient – stream frames via ffmpeg
// Key Functions    • run() – spawn ffmpeg and broadcast frames
//                   • connect_with_retry() – retry helper for tests
// Dependencies     • tokio, image, thiserror
// Last Major Rev   • 2024-05-?? – initial implementation
// ###############################################################

use image::DynamicImage;
use std::process::Stdio;
use std::time::Duration;
use thiserror::Error;
use tokio::io::{AsyncReadExt, BufReader};
use tokio::process::Command;
use tokio::sync::broadcast;
use tokio::time;

/// Broadcast channel type for decoded frames.
pub type FrameSender = broadcast::Sender<DynamicImage>;

/// An asynchronous RTSP client that uses `ffmpeg` to decode frames.
pub struct RtspClient {
    url: String,
    tx: FrameSender,
    reconnect_delay: Duration,
}

impl RtspClient {
    /// Create a new client and associated receiver for frames.
    pub fn new(url: String) -> (Self, broadcast::Receiver<DynamicImage>) {
        let (tx, rx) = broadcast::channel(2);
        (
            Self {
                url,
                tx,
                reconnect_delay: Duration::from_secs(1),
            },
            rx,
        )
    }

    /// Run the client, reconnecting on failure.
    pub async fn run(mut self) {
        loop {
            if let Err(e) = self.spawn_and_stream().await {
                eprintln!("RTSP error: {e:?}; retrying...");
                time::sleep(self.reconnect_delay).await;
            }
        }
    }

    async fn spawn_and_stream(&mut self) -> Result<(), RtspError> {
        let mut child = Command::new("ffmpeg")
            .arg("-rtsp_transport")
            .arg("tcp")
            .arg("-i")
            .arg(&self.url)
            .arg("-f")
            .arg("mjpeg")
            .arg("-")
            .stdout(Stdio::piped())
            .stderr(Stdio::null())
            .spawn()?;

        let stdout = child.stdout.take().ok_or(RtspError::NoStream)?;
        let mut reader = BufReader::new(stdout);
        let mut buf: Vec<u8> = Vec::new();
        let mut tmp = [0u8; 4096];
        loop {
            let n = reader.read(&mut tmp).await?;
            if n == 0 {
                break;
            }
            buf.extend_from_slice(&tmp[..n]);
            while let Some(pos) = find_jpeg_eoi(&buf) {
                let frame_bytes = buf.drain(..=pos).collect::<Vec<_>>();
                if let Ok(img) = image::load_from_memory(&frame_bytes) {
                    let _ = self.tx.send(img);
                }
            }
        }
        let _ = child.wait().await;
        Err(RtspError::StreamEnded)
    }
}

fn find_jpeg_eoi(buf: &[u8]) -> Option<usize> {
    buf.windows(2).position(|w| w == [0xFF, 0xD9]).map(|p| p + 1)
}

/// Errors that may occur while streaming frames.
#[derive(Debug, Error)]
pub enum RtspError {
    #[error("ffmpeg not available or could not start")]    Io(#[from] std::io::Error),
    #[error("ffmpeg produced no stream")]    NoStream,
    #[error("RTSP stream ended")]         StreamEnded,
}

/// Helper to test retry logic by invoking an async connector multiple times.
pub async fn connect_with_retry<F, Fut>(mut connect: F, retries: usize, delay: Duration) -> Result<(), RtspError>
where
    F: FnMut() -> Fut,
    Fut: std::future::Future<Output = Result<(), RtspError>>,
{
    let mut last_err = None;
    for _ in 0..retries {
        match connect().await {
            Ok(_) => return Ok(()),
            Err(e) => {
                last_err = Some(e);
                time::sleep(delay).await;
            }
        }
    }
    Err(last_err.unwrap_or(RtspError::StreamEnded))
}
