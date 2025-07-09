# Dice Roller — UI & Layout Spec (Portrait 1080×1920)

> **Scope**: Pure GUI layout & interaction.  Logic, rulesets, and RNG live elsewhere—only placeholders appear here.

---

## 1. Screen Regions & Spatial Budget

| Region                   | Y‑Range       | Height              | Notes                                                                                                           |
| ------------------------ | ------------- | ------------------- | --------------------------------------------------------------------------------------------------------------- |
| **Status / Title Bar**   | 0 – 120 px    | \~120 px            | Contains title and runtime status icons (battery, network ping, lock). Fixed height.                            |
| **Dice Pad**             | 120 – 960 px  | ≤ 50 % (max 840 px) | Two rows of quick‑quantity chips + two rows of dice buttons + advanced row + system dropdown button.            |
| **Lower Pane (Dynamic)** | 960 – 1920 px | ≥ 50 %              | Hosts Animated Roll, System Drawer, History, QR screen, Dice Keyboard—each shown exclusively via gestures/tabs. |

The **Dice Pad** is the spatial priority—our aesthetic goal is to keep it around the upper half of the screen, but it may expand beyond 50 % when necessary. Secondary panels (History, Systems, etc.) slide over or under it, and the Dice Pad only yields space as a last resort, never falling below the 70 px minimum touch target height.

---

## 2. Dice Pad Composition (Upper 50 %)

### 2.1 Quick‑Quantity Row

* Six square chips (80×80 px, 8 px radius) horizontally centered with 12 px gutters.
* **Default labels**: `1×`, `2×`, `3×`, `4×`, `5×`, `10×`.
* Typeface: Semi‑bold, 32 pt; auto‑contrast against theme background.

### 2.2 Common Dice Row

* Six buttons (80×80 px): `D4`, `D6`, `D8`, `D10`, `D12`, `D20`.
* Glyph rendering uses two‑layer approach (shape + numeral) specified in core plan.

### 2.3 Advanced Row

* `D2`, `D100`, `|` (segment), `DX?` (prompt die), **ROLL**, **⌫**.
* **ROLL** uses accent color & larger width (120 px) for emphasis.
* **⌫** icon only; long‑press clears queue.

### 2.4 System Dropdown Trigger

* Down‑arrow button (48 × 48 px) centered below rows.
* **Gesture**: single tap toggles **Favorite Systems List** overlay (see §3.2).
* Overlay appears anchored to this button, but never overlaps Dice Pad rows.

### 2.5 Queue Display

* Single‑line `Label` (marquee on overflow) beneath dropdown trigger.
* Shows comma‑ & pipe‑separated notation auto‑formatted per active ruleset.
* Font 28 pt; truncates leftmost text first to keep most recent items visible.

---

## 3. Lower Pane (Exclusive Views)

Lower 50 % operates as a **slide‑up container** with lock/unlock logic.

### 3.1 Pane States & Gestures

| Gesture                        | Result                                                          |
| ------------------------------ | --------------------------------------------------------------- |
| **Slide ↑ once** (from bottom) | Preview height (\~30 %) + dim background.                       |
| **Slide ↑ again**              | Full open (covers Lower Pane).                                  |
| **Slide ↓**                    | Close to bottom.                                                |
| **Double‑slide ↑ when closed** | Unlock + immediately open (prevents accidental drags mid‑game). |

Internally the container hosts a `TabBar` with **ROLL**, **HISTORY**, **SYSTEMS**, **SETTINGS**, **KEYBOARD**, **QR**.

### 3.2 Animated Roll View (Tab: ROLL)

* Default content if dice animation enabled.
* Placeholder: randomly placed 2D glyphs representing rolled dice; fade‑in/out 300 ms.
* User can select **Animation Level** in Settings (Off / Basic / Static / 2D / 3D). Only **Basic** stubbed for MVP.

### 3.3 History (Tab: HISTORY)

* `ListView` showing last 100 rolls (newest on top).
* Timestamp logic:

  * < 1 min: *“just now”*
  * < 24 h: HH\:MM\:SS
  * < 30 d: *weekday + HH\:MM*
  * ≥ 30 d: *MM/DD/YYYY*
* Row tap reveals full timestamp + raw breakdown.

### 3.4 System Drawer (Tab: SYSTEMS)

* Scrollable list of all rulesets (placeholder strings).
* Star button toggles favorite; starred items populate **Favorite Systems List** overlay (see §2.4).

### 3.5 App Settings (Tab: SETTINGS)

* **Theme Color** swatch, **Font Scale** slider, **Animation Level** dropdown.
* For DLC skins/SFX placeholders, reserve a collapsible “Store” section (disabled by default).

### 3.6 Dice Keyboard (Tab: KEYBOARD)

> Goal: lightning‑fast entry of any legal dice expression without a full QWERTY.

#### 3.6.1 Layout & Pagination

* **Grid:** 5 columns × variable rows, 64 × 64 px buttons, 8 px gutters.
* **Pages:** numeric/math page ⇄ notation page (swipe horizontally or tap “α/β” toggle in top‑right corner).

| Page                   | Rows (top → bottom) | Button Sets                   |           |
| ---------------------- | ------------------- | ----------------------------- | --------- |
| **A (Numeric / Math)** | R1                  | `7  8  9  +  (`               |           |
|                        | R2                  | `4  5  6  –  )`               |           |
|                        | R3                  | `1  2  3  ×  /`               |           |
|                        | R4                  | \`0  D                        |   \*  !\` |
|                        | R5                  | **ROLL** (span 3)  ⌫ (span 2) |           |
| **B (Parser Strings)** | R1                  | `kh  kl  k  sa  sd`           |           |
|                        | R2                  | `s  r  ro  R  !!`             |           |
|                        | R3                  | `>=  <=  >  <  =`             |           |
|                        | R4                  | `f1  f<  cs  cf  p!`          |           |
|                        | R5                  | **ROLL** (span 3)  ⌫ (span 2) |           |

* Multi‑character tokens render right‑aligned within the button for legibility.
* Long‑press a token opens a small tooltip with its meaning (e.g., “kh = keep highest”).
* The grid auto‑scales down to 56 × 56 px on < 720 px wide devices.

#### 3.6.2 Interaction Rules

* **Button press** → inserts token at cursor in queue line.
* **Swipe left/right** → switch between Page A and Page B.
* **ROLL** → triggers `roll_requested` signal.
* **⌫ short‑press** → delete last token; **long‑press** → clear entire input.

The keyboard stays hidden unless explicitly selected via the KEYBOARD tab or revealed by a downward swipe on the queue label.

### 3.7 QR Connect (Tab: QR) (Tab: QR)

* Full‑panel QR placeholder image.
* Caption explains “Scan to download / sync.”
* Future: read session IDs to sync two devices.

---

## 4. Global Interaction Notes

* All buttons meet minimum 44×44 pt touch target.
* **Haptic feedback** on critical actions: roll, clear, lock/unlock drawer.
* Use `clamp()` sizing tokens to adapt layout down to 720 × 1480 devices.
* Orientation change → Dice Pad shifts left; Lower Pane becomes right‑side drawer (future landscape spec).

---

## 5. Placeholder API Hooks

| Component           | Signal                     | Placeholder Action                    |
| ------------------- | -------------------------- | ------------------------------------- |
| Quick‑Quantity Chip | `quantity_selected(n)`     | Appends `n×` prefix to queue.         |
| Dice Button         | `die_pressed(faces)`       | Appends `d{faces}` or replaces `DX?`. |
| Roll Button         | `roll_requested(notation)` | Emits event; animation view listens.  |
| Drawer Tab Change   | `tab_changed(id)`          | Swaps content container.              |
| Settings Change     | `theme_changed(v)`         | Updates UI tokens instantly.          |

All signals tote plain data objects; no backend calls in this spec.

---

## 6. MVP Cut‑List

These items render as **stub placeholders** in initial release:

* 3D dice animation (show static PNG).
* DLC skin store (disabled).
* QR sync logic (static QR image).
* Multi‑device seed replay workflow.
* System ruleset parsing—only UI list population.

---

**End of Document**
