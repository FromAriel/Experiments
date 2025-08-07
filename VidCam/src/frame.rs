// ###############################################################
// VidCam/src/frame.rs
// Shared frame type carrying raw RGBA/BGRA bytes.
// ###############################################################

#[derive(Clone, Debug)]
pub struct RawFrame {
    pub data: Vec<u8>,
    pub width: u32,
    pub height: u32,
}
