# 📋 Transparent Security Camera Overlay — Complete System Design Plan

### 🧭 Purpose

To create a lightweight overlay application that connects to an RTSP security camera, displays the live video feed in a semi-transparent window on the screen, enables user interaction for resizing and opacity adjustment, and records one frame per second to compile into a time-lapse video.

---

## 🧱 System Components Overview

| Component                  | Role                                                                                       |
| -------------------------- | ------------------------------------------------------------------------------------------ |
| **Overlay Window**         | Always-on-top, frameless window in the corner of the screen displaying the live video feed |
| **RTSP Stream Client**     | Connects to camera and pulls video feed from `rtsp://...`                                  |
| **Mouse Hover Detection**  | Detects when user hovers over the window, triggering UI changes                            |
| **Resizable UI Handles**   | Interactive corner controls styled like “blue petal” shapes for resizing                   |
| **Opacity Control Slider** | Horizontal slider for adjusting base transparency (0–10%)                                  |
| **Snapshot Capture**       | Saves one frame per second to disk for timelapse                                           |
| **Timelapse Encoder**      | Compiles captured frames into a 1 FPS video on demand                                      |
| **Configuration Memory**   | Stores user preferences like window size, position, opacity, etc.                          |

---

## 🧠 Functional Behavior Specification

### 1. 🖼 Overlay Window

* **Always-on-top**
* **Frameless** (no title bar or borders)
* **Small size by default** (e.g., 300×200 px)
* **Initial position:** top-left of screen
* **Supports dragging** by clicking anywhere inside the frame (optional)
* **Transparency:**

  * Base opacity: 5–10% (user-defined via slider)
  * Full opacity (100%) when hovered by mouse
  * Smooth fade-in/out transitions if possible

---

### 2. 🎥 RTSP Video Feed

* Connect to this RTSP stream:

  ```
  rtsp://fromariel%40gmail.com:VMonkey%21%401@192.168.1.169:554/stream1
  ```
* Maintain continuous playback in the overlay window
* Automatically reconnect if stream drops
* Frame resolution can be scaled to fit window dimensions

---

### 3. 🖱 Mouse Hover Behavior

* Detect mouse entering/exiting the overlay area
* On hover:

  * Fade opacity to 100%
  * Show:

    * Four corner resize handles (styled as blue “flower petal” icons)
    * An opacity slider (see below)
* On mouse exit:

  * Fade to user-defined base opacity
  * Hide all UI elements (handles, slider)

---

### 4. 🌼 Resizable UI Handles

* Four corner handles (Top-Left, Top-Right, Bottom-Left, Bottom-Right)
* Visible only on mouse hover
* Style: blue, radial “petal” or “leaf”-like shapes for high visibility
* Each handle responds to click-drag for resizing the window
* Resize behavior should feel smooth and intuitive
* Optionally:

  * Add edge (midpoint) handles for vertical/horizontal resizing
  * Include animated hover glow to indicate interactivity

---

### 5. 🎚️ Opacity Slider

* Appears at bottom edge of overlay window (or floating just above it)
* Horizontal control:

  * Range: 0% to 10% (mapped internally to 0.0–0.1 window opacity)
  * Step: 1% (or continuous slider if supported)
* Affects the **base opacity** applied when the mouse is *not* hovering
* Stores last value in configuration

---

### 6. 🖼 Snapshot Frame Capture

* Automatically save **one frame per second** from the video feed
* Save location: a user-defined or default directory
* Naming convention:

  ```
  ./timelapse/YYYYMMDD_HHMMSS.jpg
  ```
* Capture resolution should match what’s displayed in the overlay
* File format: JPEG or PNG

---

### 7. 🎞 Timelapse Video Encoding

* On command (button, hotkey, or on application exit):

  * Compile saved frames into a video file
  * Output:

    ```
    ./timelapse/output_YYYYMMDD_HHMMSS.mp4
    ```
* Frame rate: 1 FPS input → 1 FPS output
* Output format: MP4 (H.264), compatible with most video players
* Use external tool like FFmpeg or equivalent encoder

---

### 8. 🧠 Persistent Configuration

* Save and load:

  * Window position and size
  * Base opacity level
  * Last save directory
  * Whether to auto-compile timelapse on exit
* Storage format:

  * INI file, JSON, or platform-native preferences

---

## 🧪 Error Handling & Edge Cases

| Case                      | Behavior                                           |
| ------------------------- | -------------------------------------------------- |
| RTSP stream drops         | Attempt automatic reconnection with backoff        |
| Disk full                 | Stop saving snapshots; show warning if possible    |
| No write permission       | Warn user and disable frame saving                 |
| Window dragged off-screen | Auto-snap back or prevent move out of bounds       |
| UI elements clipped       | Keep resize handles and slider within visible area |

---

## 🧰 Optional Features (Future Enhancements)

* 📷 Manual snapshot button
* 🕐 Timer display showing duration of recording
* ⏱ Frame interval adjustment (e.g., 1 per 5s, 1 per 10s)
* 🔍 Zoom/pan inside video view
* 📡 Multi-camera support (tabs or multiple overlays)
* 🌒 Night mode / theme switching

---

## 🧪 Testing Strategy

* Verify RTSP stream connects and displays consistently
* Ensure snapshot frequency is exactly 1 per second
* Confirm all mouse interactions work correctly (hover, resize, drag)
* Validate opacity slider works and stores setting
* Test video compilation with FFmpeg and play output
* Simulate camera dropouts and disk permission issues

---

## 🏁 Summary

This application is a **lightweight, high-visibility transparent overlay** to monitor your RTSP camera with interactive UI elements:

* 📺 Real-time video preview
* 🖱️ Hover-based interactivity
* 🌼 Radial resize handles
* 🎚️ Adjustable transparency
* 📸 Frame capture for timelapse
* 🎞 Automatic video compilation
* ⚙️ Persistent config for ease of use

---
