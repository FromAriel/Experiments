# Godot 4 Node Blueprint – Dice Roller UI (1080×1920 Portrait)

> **Purpose**: Minimal, non‑functional scene tree that Codex (or any generator) can instantiate.  Focuses on major containers, anchors, and placeholder controls only.

---

## 0. Scene Root

```text
MainUI (Control)
  • Size: 1080×1920  (StretchMode = 2D, Aspect = keep)
```

---

## 1. Top Bar (Status / Title)

```text
TopBar (PanelContainer)
  • Anchors: 0,0 → 1,0   (full width, top)
  • Custom Minimum Size: 0×120
  └─BarHBox (HBoxContainer)
      ├─TitleLabel (Label)           # "LIVEdie"
      ├─Spacer (Control, size flags ExpandH)
      ├─IconBattery (TextureRect)    # placeholder 32×32
      └─IconLock (TextureRect)       # placeholder 32×32
```

---

## 2. Dice Pad (Priority Layout)

```text
DicePad (VBoxContainer)
  • Anchors: 0,0 → 1,0   (docked under TopBar)
  • Size Flags: FillH, ShrinkCenterV
  • Margin Top: 120

  ├─QtyRow (HBoxContainer)
  │   • 6× QtyButton (Button, 80×80, captions "1×", "2×", 3×", 4×", 5×","10×")
  │
  ├─CommonDiceRow (HBoxContainer)
  │   • 6× DieButton (Button, 80×80, captions D4, D6, D8, D10, D12, D20)
  │
  ├─AdvancedRow (HBoxContainer)
  │   • D2Btn  D100Btn  PipeBtn  DXPromptBtn  RollBtn  BackspaceBtn
  │   • RollBtn custom min width 120
  │
  ├─SystemDropdown (Button)
  │   • Size: 48×48, icon "chevron_down"
  │
  └─QueueLabel (Label)
      • Custom Min Height 40, autowrap, marquee script placeholder
```

Note: `DicePad` has `CustomMinimumSize.y = 700` to **prefer** upper‑half occupancy but will expand until LowerPane overlays.

---

## 3. Lower Pane (Slide Drawer)

```text
LowerPane (PanelContainer)
  • Anchors: 0,1 → 1,1   (bottom‑anchored)
  • Height: 960 (initial) – animated via script
  └─TabHost (TabContainer)
      • Tabs: Roll  History  Systems  Settings  Keyboard  QR
```

### 3.1 Roll Tab

```text
RollTab (Control)
  └─DiceArea (Node2D)  # placeholder for dice sprites
```

### 3.2 History Tab

```text
HistoryTab (ScrollContainer)
  └─HistoryVBox (VBoxContainer)  # 100× HistoryItem (Label placeholders)
```

### 3.3 Systems Tab

```text
SystemsTab (ScrollContainer)
  └─SystemVBox (VBoxContainer)  # SystemButton + StarCheckBox items
```

### 3.4 Settings Tab

```text
SettingsTab (VBoxContainer)
  ├─ThemeColor (ColorPickerButton)
  ├─FontScaleSlider (HSlider)
  ├─AnimLevelOption (OptionButton)
  └─Spacer
```

### 3.5 Keyboard Tab

```text
KeyboardTab (StackContainer)     # holds two pages
  ├─PageA (GridContainer 5×5)    # numeric / math
  └─PageB (GridContainer 5×5)    # parser tokens
```

### 3.6 QR Tab

```text
QRTab (Control)
  └─QRCode (TextureRect, expand)
```

---

## 4. Global Scripts / Singletons (placeholders only)

* **DrawerController.gd** – handles LowerPane slide, lock/unlock.
* **UIEventBus.gd (Autoload)** – central signal hub (`roll_requested`, `system_selected`, etc.).

---

### Dimension Cheat‑Sheet

| Element                  | W×H (px)       |
| ------------------------ | -------------- |
| Qty / Die Buttons        | 80×80          |
| Roll Button              | 120×80         |
| Dropdown Trigger         | 48×48          |
| DiceArea                 | fills RollTab  |
| LowerPane Closed Height  | 0              |
| LowerPane Preview Height | 600 *(approx)* |
| LowerPane Full Height    | 960            |

---

**End Blueprint**
