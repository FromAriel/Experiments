# 🎲 Dice Roller App: UI & Interaction Design Spec

## 🌟 Overall Goals

Design a highly usable, fast-access dice roller interface tailored to chaotic tabletop gaming environments. The system must balance speed, flexibility, and safety, ensuring that users can input complex rolls quickly without risk of accidental errors.

---

## 🎮 Quick Roll Bar 

### Dice Types

**Standard Dice:**

* D2 (Coin Flip)
* D4, D6, D8, D10, D12
* D20, D100 (D%)

**Advanced Dice:** *(collapsible or toggleable behind > )*

* D13, D16, D24, D30, D60

### UI Layout (Mobile Example)

```
💰 | D4 | D6 | D8 | D10 | D12 | D20 | D% | <> | DX? ROLL
💰 | D4 | D6 | D8 | D10 | D12 | D20 | <D13 | D16 | D24 | D30 | D60> | D% | DX? ROLL

Possibly:

💰 | D4 | D6 | D8 | D10 | D12 | D20 | ⬇️ | D% | DX? | ROLL
                            <D16 | D24 | D30 | D60>

OR:

💰 | D4 | D6 | D8 | D10 | D12 | D20
D16 | D24 | D30 | D60 | D% | DX? | ROLL
```

* 💰 = Coin (D2)
* DX? = Custom user-defined die

These alternate layouts support different screen sizes and user preferences. The "Advanced Dice" set may be toggled into view through a chevron (<>), dropdown, or secondary row toggle, keeping the interface clean by default while ensuring all dice types remain accessible.

---

## ➕ Additive Dice Stack Logic

Users can build roll queues through either:

### Method 1: Tap-Based Accumulation

* Tap a die multiple times to queue multiple instances.
* Example: Tap D4 four times = **4d4**

### Method 2: Repeater Buttons ("xN")

* Tap a die once, then tap a `×N` button to queue multiple copies of the **last tapped die**.
* Example: Tap D6, then ×4 = **4d6**
* Does **not** multiply the whole queue (unless using advanced mode; see below).

---

## 🔁 Repeat / Multiply Buttons

### Normal Tap (Green Mode)

* Repeats **last die** N times.

### Long-Press (Red Mode: Full Multiply)

* Multiplies the **entire current die pool** by N (one level deep).
* Color change: Green ➔ Red when entering this mode
* Confirmation required: visual preview or optional undo

#### Example:

Queue = 2d6, 3d4

* Long-press ×4 = 8d6, 12d4

---

## 🔒 Slide-to-Unlock Systems Panel

### States:

| State  | Behavior                                                |
| ------ | ------------------------------------------------------- |
| Locked | Requires **two** full slide gestures to unlock and open |
| Closed | Requires **one** slide to open; panel is unlocked       |
| Open   | Slide to close; returns to **Closed** state             |

### Purpose:

* Prevents accidental activation during fast-paced sessions
* Example failure scenario avoided: Bard sneezes, rolls 9d100 instead of 8d10 😅

### Panel Features:

* Create, edit, and save named roll presets
* Reconfigure Quick Roll Bar on system select
* Use scripting language for custom behavior

---

## 📉 Ghost Die + Quantity Spinner

### Ghost Die Behavior

* After tapping a die, a translucent "ghost" die appears in the queue
* User can:

  * Tap ×N to finalize multiple copies
  * Tap another die to finalize as 1
  * Tap Roll to finalize as 1 and roll

### Quantity Spinner (Long-Press Die)

* Long-press any die opens a **rotational scroll spinner**:

  * Circular dial interface
  * Accelerates quantity change as thumb rotates outward
  * Each tick increases value progressively faster
  * Cap value (e.g. 999)

### Visual/UX Features

* Spinner shows tick marks or texture
* Center number readout
* Haptic feedback on tick
* Optional: Flick up to confirm, down to cancel

---

## 📱 Visual Notation for Queue

### Display Options:

* **Superscript:** `D6⁴` (or D6^4)
* **Subscript:** `D6ₓ₄` or `D6₄`
* **Stacked Die Badge:**

```
🎲
  4
```

* Queue preview shows all dice before roll: `3d6 + 4d4 + D8⁴`

---

## 🧪 3D Dice Roll Display (Bottom Window)

### Feature Overview

Add a small 3D dice window at the bottom of the screen to visually roll dice that match the RNG results.

### Behavior:

* The 3D dice appear and tumble when a roll is triggered.
* They animate with physics-based random-looking motion.
* Their final facing matches the actual roll results from the RNG.

### Portrait Mode Display:

* Takes up full width: **1080px**
* Height is determined by a 16:9 aspect ratio:

  * Height = 1080 × (9/16) = **607.5px** (rounded to 608px)
* Dimensions: **1080×608 pixels**

### Notes:

* Should not obscure the roll queue or quick bar.
* Could be toggleable or auto-hide after a few seconds.
* Optional sound effects and vibration on bounce.
* May allow tap-to-clear or replay animation button.

---

## 📳 Shake-to-Roll Option

### Overview:

* Optional motion input that triggers a roll of the **last rolled dice set**.

### Behavior:

* Shake the device to re-roll the previous set of dice.
* Uses accelerometer input to detect a shake or tap impact.
* Users can configure sensitivity thresholds (e.g. light shake, strong shake, physical tap).

### Settings:

* **Shake Sensitivity:** Slider or step selector (e.g. low / medium / high)
* **Shake-to-Roll Toggle:** On/off toggle in settings menu

### Notes:

* Prevents accidental rerolls with debounce timing (e.g. can't trigger again within 2 seconds)
* May play vibration feedback or sound
* Shake animation optionally mirrors 3D dice movement

---

## 🔁 Undo & Safety

* Optional undo toast for actions like long-press multiply
* Drag-off cancels accidental multiplier use
* Tap-to-clear or trash button for queue wipe

---

## 🔧 Optional Enhancements

* Long-press ×N to bring up spinner-based actual multiplier mode
* Loop-gesture mode for continuous scroll
* Safety cap warning (e.g. "Rolling more than 1000 dice may lag")

---

## 🛰️ Stretch Features: Secure Roll Sync

### 🔄 Roll Sync Session UI

* "Start Sync Session" button generates a unique session code
* Display QR code with animated pulse and session ID
* "Listening for QR" screen allows others to scan via camera
* Confirmation bubble: "Synced with: \[PlayerName]"

### 📩 Auto-Import from QR/Text

* If a player scans or pastes a valid roll code, prompt:

  * "Verify roll from \[PlayerName]?"
  * Show visual breakdown of roll input and result
  * Include pass/fail hash check

### ⚠️ Tamper Detection

* If hash validation fails:

  * Display ⚠️ warning
  * Prevent use of result in shared pool, session logs, or sync state

### 🧹 Post-Session Cleanup

* Rolls can be set to expire after a session ends
* Option to clear session data manually
* Allows players to reset identity and reseed randomness

---

Ready for UI flow wireframes, scripting spec, or implementation planning next. This document reflects actual game-tested realities and thumb-safe design priorities. 🌯️



