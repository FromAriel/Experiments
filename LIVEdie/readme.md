# Project Plan: LIVEdie Dice Roller UI Implementation (Godot 4)

## Prompt 1: Create Base Scene and TopBar UI

**Project Context:** This first step establishes the main UI scene and the top status bar, which persist throughout the app. It lays the foundation (root node and top bar) that subsequent UI components (dice pad and tabs) will attach to.

**Step Summary:** We will set up a `MainUI` Control as the root sized for 1080×1920, and add a TopBar at the top. The TopBar (height \~120px) will contain the app title and status icons (battery, lock). This ensures a consistent header across screens.

**Prompt Parts:**

* Initialize a new `MainUI` **Control** node as the scene root (1080×1920 resolution, 2D stretch, aspect “keep”). Name it **MainUI**.
* Add a **PanelContainer** named **TopBar** as a child of MainUI, anchored to the top (Left/Top anchors = 0, Right = 1, Bottom = 0). Set its **Custom Minimum Size** to height 120 (px) to reserve the top bar area.
* Inside TopBar, add an **HBoxContainer** (name it *BarHBox*) to arrange contents horizontally.

  * In BarHBox, add a **Label** named **TitleLabel** with text “LIVEdie” (the app title).
  * Add a **Spacer** Control (expanding horizontally) after the title to push later items to the right.
  * Add a **TextureRect** named **IconBattery** for a battery icon placeholder (set Custom Min Size to 32×32). (No texture yet; it will serve as a placeholder square.)
  * Add another **TextureRect** named **IconLock** for a lock icon placeholder (32×32).
* Ensure the HBoxContainer content is vertically centered (default) and spaced properly (you can use a small separation if needed, e.g., 8px).
* (Leave the middle and bottom of the screen empty for now – the DicePad and LowerPane will be added next steps.) Confirm that running the scene shows a top panel with “LIVEdie” at left and two small squares at right, as our base UI header.

## Prompt 2: Build DicePad – Quantity and Common Dice Rows

**Project Context:** The DicePad is the core input area occupying the upper half of the screen, where users select quantities and dice. In this step, we construct the first two rows of the DicePad (quick quantity chips and common dice buttons) to allow basic dice expression input.

**Step Summary:** We will add a `DicePad` container below the TopBar and populate it with two horizontal rows: one for quick quantity selectors (1×, 2×, 3×, 4×, 5×, 10×) and one for common dice (D4, D6, D8, D10, D12, D20). These buttons will be laid out evenly and centered with consistent sizing (80×80 each).

**Prompt Parts:**

* Add a **VBoxContainer** named **DicePad** as a child of MainUI, to hold the dice pad rows. Anchor it to the top of MainUI just below the TopBar (Left = 0, Top = 0, Right = 1, Bottom = 0; then set its **Margin Top** = 120 to position it under the 120px TopBar). Give DicePad horizontal **Size Flags** = Fill, and vertical **Size Flags** = “Shrink Center” (so it prefers a centered height but can shrink if needed). Also set DicePad’s **Custom Minimum Size** Y to \~700px – this biases it to occupy about the upper half of the screen.
* **Quick-Quantity Row:** Inside DicePad, add an **HBoxContainer** named **QtyRow** for the quantity chips. This row will contain 6 Buttons:

  * Create 6 **Button** nodes (80×80 px each) with text labels: “1×”, “2×”, “3×”, “4×”, “5×”, “10×”. Set each button’s **Custom Minimum Size** to (80, 80) to enforce the size.
  * To center these buttons within the row, add an empty **Control** as a left spacer *and* another as a right spacer inside QtyRow, both with **Size Flags** → Expand on horizontal. This will push the buttons together to the center. Also set the HBox’s **separation** to 12 px to give a uniform gap between buttons.
* **Common Dice Row:** Add another **HBoxContainer** under DicePad named **CommonDiceRow**. This will hold 6 Buttons for common dice:

  * Create Buttons (80×80) labeled: “D4”, “D6”, “D8”, “D10”, “D12”, “D20”. Again, set each to 80×80 min size.
  * Add left and right spacer Controls (ExpandH) to center this row as well, and set separation = 12 px for even spacing.
* Ensure both rows stack in the DicePad VBox without overlap. The DicePad VBox should now contain QtyRow and CommonDiceRow, each centered. At this stage, clicking the buttons does nothing (signals will be connected after the queue display is added).

## Prompt 3: Complete DicePad – Advanced Row, System Dropdown, and Queue Display

**Project Context:** We now finish the DicePad by adding the third row of advanced controls, the system selection dropdown, and the queue display label. This completes the input pad, allowing the user to include special dice (D2, D100, etc.), roll or backspace, and see the composed dice expression.

**Step Summary:** We will create an **AdvancedRow** with buttons for D2, D100, the “|” pipe (group separator), “DX?” (custom die prompt), a prominent **ROLL** button, and a **⌫** backspace button. We also add a small **SystemDropdown** button (down-arrow icon) below, and a **QueueLabel** under that to show the current dice formula. All interactive buttons will be wired to update the queue or trigger roll signals. Notably, the **ROLL** button will trigger a roll event (placeholder), and **⌫** will support short-press to delete last character and long-press to clear the queue (per spec).

**Prompt Parts:**

* **Advanced Controls Row:** Add an **HBoxContainer** named **AdvancedRow** as the next child of DicePad. This row contains 6 buttons:

  * **D2 Button:** Text “D2”, size 80×80.
  * **D100 Button:** Text “D100”, size 80×80.
  * **Pipe Button:** Text “|” (the group separator), 80×80.
  * **DX? Button:** Text “DX?”, 80×80 (represents prompting for a custom die).
  * **Roll Button:** Text “ROLL”, with a **Custom Minimum Size** width of 120px (height 80px) to make it larger and emphasize it. You can also give it a distinct style or color (e.g., an accent-color modulate) to stand out.
  * **Backspace Button:** Use the “⌫” symbol as its text (you can copy-paste a delete symbol, or simply use “⌫”). Make it 80×80. This button should have no text label aside from the icon.
  * Set AdvancedRow’s separation to 12 px and again use an Expand spacer on left and right to center the row contents.
* **System Dropdown Button:** Below AdvancedRow (still within DicePad VBox), add a **Button** named **SystemDropdown**. This will toggle the favorite systems overlay. Set its size to 48×48 px (Custom Min Size). For now, use a down-arrow glyph as text (e.g., “▼”) or a placeholder icon for the dropdown. Give it horizontal **Size Flags** = “Shrink Center” so that it centers itself horizontally under the row above.
* **Queue Label:** Finally, add a **Label** named **QueueLabel** at the bottom of DicePad (last child of the VBox). This label will display the dice notation the user has built. Set its **Custom Minimum Height** to 40 px and enable **Autowrap** so it can scroll text if needed. Initially it can be blank or say “(no dice)” as a placeholder.
* **Attach Script for DicePad Logic:** Attach a new GDScript (e.g., `DicePad.gd`) to the DicePad node. This script will manage the state of the dice pad (like current quantity selection) and handle button presses to update the QueueLabel.

  * In the script, define a variable `currentQuantity = 1` (default multiplier).
  * **Connect Quantity Buttons:** For each quantity chip (1× … 10×), connect their `pressed` signal to a method (e.g., `_on_Quantity_pressed(value)`). In that method: set `currentQuantity = value` (e.g., 5 if "5×" pressed). Optionally, give feedback by highlighting the selected button (for simplicity, you might skip visual toggle now). Do **not** immediately update the QueueLabel on quantity press (the multiplier will apply when a die is pressed).
  * **Connect Die Buttons:** Connect each die button (D4…D20, and also D2, D100) to a method `_on_Die_pressed(faces)`. This method should append a new entry to the queue string:

    * Determine the faces (e.g., 6 for “D6” – you can parse the text by stripping the “D”). For “D100”, faces = 100.
    * Format the new dice notation segment as `"N×Dfaces"`. Use the `currentQuantity` selected; if it’s 1, you can include “1×” or omit the prefix (including “1×” consistently is fine for now). For example, if currentQuantity=3 and faces=6, produce `"3×D6"`.
    * Append this string to the QueueLabel’s text. If the label was not empty already, prepend a comma and space `“, ”` before the new segment for separation. (Use a comma to separate multiple dice groups in the queue.)
    * Reset `currentQuantity` to 1 (so subsequent dice default to 1× again).
  * **Connect DX? Button:** Connect its pressed signal to a method `_on_CustomDie_pressed()`. As a placeholder, simply append a “DX?” token to the QueueLabel (or you may just print a message “Custom die prompt not implemented”). In a real app, this would open a dialog for the user to input a number of sides.
  * **Connect Pipe Button:** On press, append `" | "` (space-pipe-space) to the QueueLabel text. This is used to separate dice pools/groups. (If the queue is empty or already ends with a pipe, you might avoid adding another, but basic handling is fine.)
  * **Connect Backspace Button:** We need to handle short vs long press:

    * Connect the Backspace’s `pressed` signal to `_on_Backspace_pressed()`, and also connect its `gui_input` to detect long press duration.
    * In `_on_Backspace_pressed()`: remove the last character of the QueueLabel’s text (if any). You can do: `queue_label.text = queue_label.text.substr(0, queue_label.text.length() - 1)`. If the queue ends with a comma or pipe and space, you might remove those extra characters as well (optional).
    * For long-press clear: Use `gui_input(event)` on the backspace button. If `event is InputEventMouseButton` or touch and `event.pressed = true`, start a Timer (say 0.5s). If the timer times out without the button being released, treat it as a long press – clear the entire QueueLabel (set text to “”). If the button is released before timeout, cancel the timer (so only a short press occurred). This way, holding backspace for >0.5s will wipe the whole queue (as per spec, long-press = clear all).
  * **Connect Roll Button:** Connect the Roll button’s `pressed` signal to a method `_on_Roll_pressed()`. For now, implement this as:

    * Print the current QueueLabel text to the console (as a placeholder for rolling logic).
    * (We will later integrate this with a global event to trigger the roll animation.)
* With these connections, test the DicePad interactions: e.g., pressing “2×” then “D8” should make the QueueLabel show “2×D8”, pressing another die adds “, 1×D6”, pipe adds “ | ”, backspace removes characters, and long-press backspace clears the line. The Roll button currently just prints the notation.

## Prompt 4: Set Up LowerPane and Tabs (Placeholder Content)

**Project Context:** The LowerPane is a slide-up drawer that will host multiple tabbed views (Roll animation, History, Systems, Settings, Keyboard, QR). In this step, we create the LowerPane and its TabContainer with each tab as an empty placeholder. This gives us the structure to navigate between tabs, even though content will be filled in subsequent steps.

**Step Summary:** We will add a bottom-anchored **LowerPane** (PanelContainer) and inside it a **TabContainer** (TabHost) with six tabs: **Roll**, **History**, **Systems**, **Settings**, **Keyboard**, **QR**. Each tab’s content will be created according to the UI spec – for now, we use simple placeholder controls (like a label or an empty container) for each tab so that the tab navigation is functional. The LowerPane will initially be set to a partially open state for testing (later we’ll add slide animations).

**Prompt Parts:**

* Add a **PanelContainer** node named **LowerPane** as a child of MainUI. Anchor it to the bottom of the screen (Left = 0, Top = 1, Right = 1, Bottom = 1). Set its initial **Rect Size** height to about 960 px (the full open height) so we can see it for now (we will adjust dynamically later). This panel will serve as the drawer background.
* Inside LowerPane, add a **TabContainer** (name it **TabHost** or **ContentTabs**). This will automatically provide tab headers for each child control.
* Create the six tab content placeholders:

  * **RollTab:** Add a **Control** node (simple Control) as a child of TabContainer. Name it **RollTab**. After adding it, use `TabContainer.set_tab_title(index, "Roll")` or set the tab name in the editor to “Roll”. In RollTab, add a **Label** with text “Roll View (animation)” as a placeholder.
  * **HistoryTab:** Add a **ScrollContainer** named **HistoryTab** as the next child of TabContainer. Set tab title “History”. Inside it, add a **VBoxContainer** named **HistoryVBox**. For now, add one Label like “(History list placeholder)” inside the VBox.
  * **SystemsTab:** Add a **ScrollContainer** named **SystemsTab** as next child, title “Systems”. Inside it, add a **VBoxContainer** named **SystemVBox** and put a Label e.g. “(Systems list placeholder)” for now.
  * **SettingsTab:** Add a **VBoxContainer** named **SettingsTab**, title “Settings”. Inside it put a placeholder Label “(Settings placeholder)”.
  * **KeyboardTab:** We will create a container for the on-screen dice keyboard. For now, add a **StackContainer** named **KeyboardTab** (title “Keyboard”). Inside it, add two dummy children:

    * Add a **Control** node named **PageA** with a Label “Numeric Page (A)” inside.
    * Add another **Control** named **PageB** with a Label “Notation Page (B)”.
      (These pages will later be replaced with actual GridContainers of keys.)
  * **QRTab:** Add a **Control** named **QRTab**, title “QR”. Inside it, add a Label “(QR code placeholder)”.
* After adding each, ensure the TabContainer has the tab titles correctly set (the name or `set_tab_title` can be used to label each tab). We should now have 6 tabs visible on the LowerPane’s tab bar.
* Adjust layout: make sure the TabContainer is set to fill the LowerPane panel (anchors 0,0 → 1,1 within LowerPane). The panel’s appearance can be a default Panel for now (gray background).
* **Initial State:** For now, leave LowerPane visible (height 960) so that the tabs are accessible. You should be able to switch tabs and see each placeholder label. (Later, we’ll implement the sliding open/close and actual content for each tab.)

## Prompt 5: Implement Roll Tab Animated View

**Project Context:** The Roll tab provides a visual animation for dice rolls. In this step, we implement a basic 2D animation placeholder to simulate dice being “rolled” when a roll is triggered. This makes the Roll view interactive and prepares it to display outcomes.

**Step Summary:** We will enhance the RollTab content by adding a dedicated area (DiceArea) for dice animations. We’ll attach a script that listens for roll events and spawns some placeholder dice visuals (e.g., numbers or icons) at random positions, fading them in/out. This stub simulates an animation (300ms fade as per spec) for rolled dice.

**Prompt Parts:**

* **DiceArea Node:** In **RollTab** (the Control we created), add a **Node2D** or **Control** named **DiceArea** that covers the tab (anchors 0,0→1,1 if Control, or position at (0,0) if Node2D with size of RollTab). This area will hold animated dice sprites or labels.
* **RollTab Script:** Attach a GDScript (e.g., `RollTab.gd`) to the RollTab node (or DiceArea). This script will handle showing the dice animation.

  * In the script, define a function `play_basic_animation()` (or `_on_roll_requested()` if connecting directly to a signal later) that simulates a dice roll animation. For example:

    * Determine a number of dice to show (for placeholder, maybe 3 dice).
    * For each, create a Label or Sprite. If using a Label, you could display a random result like a number “4” or text “D6” etc. For now, display something simple (e.g., a random number 1–6 as result).
    * Position each label at a random position within DiceArea’s bounds. For instance, random x in \[0, width], random y in \[0, height].
    * Set the label’s initial **modulate.a** (alpha) to 0 (fully transparent). Then add it as a child of DiceArea.
    * Animate it: use a **Tween** (or AnimationPlayer) to interpolate the alpha from 0 to 1 (fade in over 0.15s), maybe keep it briefly, then fade out back to 0 over another 0.15s. Total \~300ms visible.
    * After the tween completes (connect the tween’s completion or use a callback), `queue_free()` the label so it doesn’t accumulate.
  * Ensure the script has access to DiceArea node (if separate). If RollTab is Control containing DiceArea, you can do `onready var dice_area = $DiceArea`.
* **Integrate Trigger:** For testing now, you can temporarily call `play_basic_animation()` directly when the Roll tab is selected or via a temporary button. (In the next steps, we will connect it to the actual roll event.)
* Test the RollTab: you can manually invoke the animation function (e.g., via the Godot editor Remote or by adding a temporary button that calls it). It should spawn a few labels (or sprites) that flash on screen then disappear, simulating dice being rolled.

## Prompt 6: Implement History Tab Content

**Project Context:** The History tab shows a scrollable log of past dice rolls. This step populates the History list with placeholder entries, allowing the UI to demonstrate scrolling and list layout. It sets up the structure for future integration of real roll records.

**Step Summary:** We will fill the HistoryTab’s VBox with a number of dummy history entries (e.g., 100 entries as the spec suggests). Each entry will be a simple Label for now (could be styled later), and we’ll ensure the ScrollContainer allows scrolling through them. We’ll also (optionally) outline how timestamp formatting and click-to-expand might work, but implement only placeholders.

**Prompt Parts:**

* Access the **HistoryVBox** (child of HistoryTab ScrollContainer). We created it as a placeholder; now we populate it via script or the editor.
* **Populate History:** Add \~100 **Label** nodes as children of HistoryVBox to simulate past roll entries. For example, create a loop that adds 100 labels:

  * Label text could be something like `"Roll #X – Result placeholder"` or a faux timestamp. For instance:

    * Newest (first label) text: “Roll 100: just now – \[2×D20 = 17]”
    * Later ones: “Roll 99: 10:15:30 – \[D6+5 = 9]”, etc.
      (You can keep it simple, e.g., Label 1: "Roll 100 (just now)", Label 100: "Roll 1 (earlier)".)
  * Set the newest roll at the top or bottom as desired. Typically, newest would be at top, so you might add labels in reverse order (100 down to 1).
* Make sure the ScrollContainer’s vertical scroll is enabled (usually automatic when content exceeds viewport). You can test scroll by running and dragging the list.
* (Optional enhancements, not fully implemented now: In a real app, we’d format timestamps as “just now”, “HH\:MM\:SS”, etc., and allow tapping an entry to expand details. These can be left as future improvements.)
* Test the History tab: It should display a long list of entries that you can scroll through smoothly. This verifies that the scroll container and list sizing work properly.

## Prompt 7: Implement Systems Tab Content (All Systems List with Favorites)

**Project Context:** The Systems tab lists all available game systems/rulesets and allows marking favorites. We will create a scrollable list of system entries, each with a name and a star icon to favorite it. This provides the data for the favorites overlay and system selection feature.

**Step Summary:** We will populate the SystemsTab with a list of dummy systems (e.g., “System 1”, “System 2”, etc.), each entry consisting of a label (or button) for the system name and a star toggle to mark it as favorite. We’ll implement toggling logic to maintain a favorites list. Also, when a system name is clicked, we’ll simulate selecting that system (e.g., print or later trigger an event).

**Prompt Parts:**

* Access the **SystemVBox** (child VBox in SystemsTab ScrollContainer). We will add one item per system.
* Decide on some dummy system names. For example, `"System A"`, `"System B"`, ..., or more thematic names (e.g., “D\&D 5E”, “Pathfinder 2E”) – any identifiers are fine for placeholders.
* **Populate Systems List:** For each system:

  * Create an **HBoxContainer** for the entry.

    * Add a **Button** (or Label) for the system name. Using a Button for the name allows click selection. Set its text to the system name (e.g., “System A”). We’ll treat clicking this as selecting that system.
    * Add a **Button** for the star icon. Set this button’s **Toggle Mode** = On (so it can stay pressed). Use a star character for icon: e.g., default text “☆” (a hollow star, U+2606) for not favorite, and when toggled, we’ll switch it to “★” (filled star, U+2605).

      * Set the star button’s size to, say, 32×32 (min size) so it’s smaller than a full button, or keep default if comfortable next to text.
      * Alternatively, use a **CheckBox** or **TextureButton** if available, but a toggle Button with text star is simplest.
    * Align the star to the right side of the HBox (you can add an expanding spacer between name and star, or set the name button to expand, pushing the star to the far right).
  * Add this HBox to the SystemVBox.
* Repeat for \~10–15 systems to have a scrollable list (or as many as desired for testing).
* **Attach Script for Systems Logic:** Create a GDScript for the Systems tab (attach to SystemVBox or SystemsTab). This will handle favorite toggling and system selection.

  * In the script, maintain an array `favorites = []` to keep track of favorite system names (or IDs).
  * **Connect Star Toggles:** For each star button, connect its `toggled(bool pressed)` signal to a handler (you can do this in code as you create the buttons). For example, `_on_Star_toggled(system_name, pressed)`. In this function:

    * If `pressed` is true, add the system name to `favorites` array; if false, remove it.
    * Also change the button’s text: set to “★” when pressed (favorite), back to “☆” when not. (Since it’s toggle mode, Godot might not automatically swap text, so handle it manually.)
  * **Connect System Name Buttons:** Connect each name button’s `pressed` signal to a handler `_on_System_pressed(system_name)`. In this function:

    * Print or log something like `"System X selected"`. (Later we’ll emit a global signal for system change.)
    * You might also visually indicate the selection (not required now, but e.g., highlight the selected system’s name).
    * (For now, we won’t actually change other UI state on selection, just log it.)
  * As a utility, implement a method `select_system(name)` that can be called both when a user clicks a system in this list or chooses one via the favorites overlay. This method could simply log the selection (and later emit an event). Use this in the `_on_System_pressed` handler.
* **Initial Favorites:** You can initialize some favorites for demonstration. For example, after creating the list, programmatically toggle one or two star buttons (set them pressed = true and update favorites list accordingly) so the overlay will have some entries initially.
* Test the Systems tab: The list should scroll. Clicking a star toggles it on/off (star character filling in), and the script’s favorites list updates. Clicking a system name prints a message (e.g., in output) that that system was “selected”. These behaviors set up data for the next step (the overlay of favorites).

## Prompt 8: Implement Favorite Systems Overlay

**Project Context:** The favorite systems overlay is a small panel that appears when the user taps the system dropdown button on the DicePad. It lists the user’s favorited systems for quick selection. In this step, we create that overlay and connect it to the dropdown trigger, so favorites can be chosen without opening the full Systems tab.

**Step Summary:** We will add a hidden overlay panel anchored near the SystemDropdown button (per spec, anchored to the button but not covering the dice pad). This overlay will show a list of starred systems (from the Systems tab). We’ll implement toggling it visible on button press, populating it with the current favorites, and closing it when a selection is made or if the user taps outside the panel.

**Prompt Parts:**

* **Overlay Node:** In MainUI (root), create a new **Control** node for the overlay. Name it **FavOverlay** and keep it as a direct child of MainUI (so it’s on top of DicePad but we’ll manage layering). Set **Visible** = false initially.

  * Set FavOverlay’s anchors to **Full Rect** (Left/Top = 0, Right/Bottom = 1) so it covers the whole screen – this will let it catch outside taps. However, we will make most of it transparent except the actual list panel.
* **Dim Background:** Add a **ColorRect** as a child of FavOverlay (or use the FavOverlay itself) to act as dimming backdrop. Make it cover the full screen (anchors 0,0→1,1) with Color black and alpha \~0.5. This will dim everything when overlay is open.

  * Set FavOverlay’s **Mouse Filter** to *Stop* so that clicks on the dim area are captured by the overlay.
* **List Panel:** Add a **PanelContainer** (or Panel) as another child of FavOverlay, named **FavListPanel**. This will hold the favorite systems list. Give it a semi-transparent or panel background for clarity.

  * Position: We want this panel to appear just below the SystemDropdown button. We can calculate at runtime, but for now:

    * Anchor the panel’s top-left near the SystemDropdown. For example, use Layout->Top Wide or similar and then adjust margins: set its **Margin Top** to \~DicePad’s bottom or \~ (DicePad height). We will refine by code for exact anchor.
    * Alternatively, leave it and position via script to exactly anchor to the dropdown’s global position.
  * Give the panel a fixed width (e.g. 300 px) for consistency. (You can set Custom Minimum Size X = 300.) Height can adjust to content.
* **Favorites List:** Inside FavListPanel, add a **VBoxContainer** (name it e.g. FavListVBox). We will populate this with favorite system entries.

  * For each system in the favorites list (from SystemsTab), add a **Button** with the system name. These will be clickable to select that system. Since all in this list are favorites, we might not need a star icon here; the purpose is quick selection. (Optionally, you could include a small star icon indicating they are favorited, but it’s redundant.)
  * Ensure the VBox is sized by its children. The panel will expand to fit this VBox (since PanelContainer can shrink to content, or set panel’s min height accordingly).
* **Overlay Script:** Attach a script to FavOverlay (e.g., `FavOverlay.gd`). This script will handle showing/hiding the overlay and populating the list:

  * Get references to relevant nodes: the FavListVBox and the FavListPanel, and the SystemDropdown button (for positioning).
  * **Toggle Function:** Implement a method `toggle_overlay()`:

    * If overlay is currently visible: hide it (`FavOverlay.visible = false`).
    * If it’s hidden:

      * Rebuild the list: clear any existing children in FavListVBox, then get the current favorites list from the Systems logic. For example, access the SystemVBox script via `get_node("LowerPane/TabHost/SystemsTab/SystemVBox")` and call a method or property that returns the `favorites` array. (We ensured in step 7 that the Systems script tracks favorites.)
      * For each favorite system name in that list, create a Button with that name and add to FavListVBox (you can also reuse an existing list if stored).
      * Optionally, if no favorites, add a Label “(No favorites)” as a placeholder.
      * Position the FavListPanel: Calculate the global position of the SystemDropdown button. e.g.

        ```gdscript
        var dropdown = get_node("DicePad/SystemDropdown")
        var pos = dropdown.get_global_position()
        ```

        Then set FavListPanel’s `rect_position`. For example, `FavListPanel.rect_position = Vector2(pos.x - 150, pos.y + dropdown.rect_size.y)` to center it horizontally around the button (assuming 300px width, subtract half of that from button x) and place it just below the button.
      * Now set `FavOverlay.visible = true` to show the overlay (dimming background and panel).
  * **Connect Outside Tap:** In FavOverlay’s script, override `_gui_input(event)` or connect an input signal:

    * If `event is InputEventMouseButton` and event.pressed is true:

      * Determine if the click was outside the FavListPanel. You can get the panel’s Rect (position and size) and check if `event.position` lies outside that rectangle.
      * If outside, call `toggle_overlay()` (to hide). This ensures tapping the dim area closes the overlay.
  * **Connect Favorite Selection:** For each Button added to FavListVBox (favorite system entry), connect its `pressed` signal to a handler that:

    * Calls the Systems script’s `select_system(name)` method (to handle selection logic globally – e.g., update active system, emit event, etc.). Or simply emits a global event (we’ll do global events in the next step).
    * Hides the overlay (`FavOverlay.visible = false`).
* **Connect Dropdown Button:** In the DicePad script (or somewhere appropriate), connect the **SystemDropdown** button’s `pressed` signal to the FavOverlay’s toggle function. For example:

  * In DicePad.gd’s `_ready()`, do:

    ```gdscript
    var overlay = get_parent().get_node("FavOverlay")
    $SystemDropdown.connect("pressed", overlay, "toggle_overlay")
    ```

    This way, tapping the dropdown calls toggle\_overlay on our overlay.
* Test the overlay:

  * Mark some systems as favorite in the Systems tab (stars toggled).
  * On the main screen, tap the SystemDropdown (down arrow) button. **Expected:** The screen dims and a small panel appears near the button, listing the favorite systems.
  * Tap outside the panel (on the dim area): overlay should close.
  * Open again and tap a system name in the overlay: it should select that system (check console or intended feedback) and then close the overlay.
  * The overlay should not overlap the dice pad rows (it should appear just below the dice pad, anchored to the dropdown button), and it should only list the favorites (no other systems).

## Prompt 9: Implement Settings Tab and QR Tab Content

**Project Context:** The Settings tab allows the user to customize UI preferences (theme color, font scale, animation level, etc.), and the QR tab shows a QR code for syncing or download. This step will build out the Settings controls and the static QR display according to the spec.

**Step Summary:** We will add actual UI controls to the Settings tab: a ColorPicker for theme color, a font size slider, and an animation level dropdown. We’ll connect these to placeholder behaviors (like changing a color or printing values). For the QR tab, we’ll embed a placeholder QR image and a caption text.

**Prompt Parts:**

* **SettingsTab Controls:** Access the **SettingsTab** VBox (from step 4, we added it as a VBoxContainer).

  * Remove the placeholder label inside SettingsTab (if any).
  * Add a **ColorPickerButton** (name it **ThemeColorPicker**) as the first child of SettingsTab. This control shows a color swatch and opens a color picker popup when pressed. It will represent “Theme Color”.

    * Optionally, set an initial **Color** (maybe the default theme accent or any color).
    * Label it by setting its text or by adding a small Label before it like “Theme Color:” (for clarity, you can add a Label above it).
  * Next, add an **HSlider** (Horizontal Slider) named **FontScaleSlider**. Set its **Min** value to 0.5 and **Max** to 2.0 (assuming font scale 50% to 200%). Set **Step** to 0.05 for fine adjustment. You might also set an initial value of 1.0 (100%).

    * Again, optionally precede it with a Label “Font Scale:” in the VBox.
  * Next, add an **OptionButton** (dropdown) named **AnimLevelOption**. This will list animation level choices.

    * Populate its items: e.g., `AnimLevelOption.add_item("Off", 0)`, `"Basic", 1`, `"Static", 2`, `"2D", 3`, `"3D", 4`. (Use the spec’s terms Off/Basic/Static/2D/3D for animation detail levels.)
    * Set an initial selection, e.g., index 1 (“Basic”) as a default.
    * This corresponds to the “Animation Level” setting.
  * Finally, add a **Control** node as a **Spacer** (expand vertical) to push these controls to the top. Give the Spacer VSizeFlag = Expand. (This mirrors the spec note to reserve space for a future “Store” section; we won’t implement the store now, but the spacer holds space.)
* **Settings Signals:** Attach a script to SettingsTab (e.g., `SettingsTab.gd`) or handle signals in one central script. We can do it here for modularity:

  * Connect **ThemeColorPicker**’s `color_changed(color)` signal to a method `_on_Color_changed(color)`. In this handler:

    * For now, apply this color to the UI theme as a placeholder action. For example, change the Roll button’s modulate or background color to this new color to simulate theme change. (Alternatively, print the color or store it – but it’s nice to see some effect.)
    * E.g., `get_node("/root/MainUI/DicePad/AdvancedRow/RollButton").modulate = color` as a simple feedback (this tints the roll button).
    * Also, you might later emit a global signal (UIEventBus.theme\_changed) – we’ll handle that in the next step.
  * Connect **FontScaleSlider**’s `value_changed(value)` signal to `_on_FontScale_changed(value)`. Handler:

    * As a placeholder, you can scale some UI element or just print the value. For example, print `("Font scale set to %.2f" % value)`.
    * (Full implementation would adjust font sizes globally via theme; skipping actual scaling for now.)
  * Connect **AnimLevelOption**’s `item_selected(index)` (or `option_pressed` in Godot 4) signal to `_on_AnimLevel_changed(index)`. Handler:

    * You can print the chosen option text: e.g., `print("Animation level:", AnimLevelOption.get_item_text(index))`.
    * Optionally, if “Off” is selected (index 0), you could set a flag to disable roll animations; if non-Off, enable them. (Our roll animations are basic anyway, so just a print is fine.)
  * These controls changes should reflect immediately if possible (theme color does instantly tint the roll button in our placeholder).
* **QRTab Content:** Switch to **QRTab** control.

  * Remove the placeholder label if present.
  * Add a **TextureRect** named **QRCode** that will display a QR code image. Anchor it to full size (0,0→1,1) inside QRTab, and set **Expand** = true (so it scales to available space while keeping aspect).
  * For placeholder image: if you have a sample QR code image file, load it as `QRCode.texture`. If not, use a built-in icon as a stand-in:

    * For example, use Godot’s default icon: `QRCode.texture = preload("res://icon.png")` (This obviously isn’t a QR, but shows an image).
    * Alternatively, create a simple black-white pattern dynamically (not necessary here).
  * Below the TextureRect (or on top if overlapping), add a **Label** for the caption. For instance, anchor a Label to bottom center of QRTab with text “Scan to download / sync.” (Spec mentions this caption.)

    * You can create a small **VBoxContainer** in QRTab, put the TextureRect and Label inside it (TextureRect with VSizeFlag Expand, then Label). This will place the label below the image.
    * Center the label text.
  * Ensure the QRTab content is nicely scaled: You might limit the TextureRect size if needed (for example, set a min size or use `keep_aspect_cover` if you want to fill).
* Test **Settings Tab:** Switch to Settings tab in the running app. Try the ColorPicker, choose a color – the Roll button (or whichever element you decided) should change color to reflect it. Move the Font slider – you should see console output or any chosen effect. Change Animation level – see console print. These confirm the UI controls work.
* Test **QR Tab:** Switch to the QR tab. You should see the placeholder QR image (or icon image) filling most of the area and the caption text below it. (Since this is static, there’s no interaction to test, but verify it looks correct.)

## Prompt 10: Implement Keyboard Tab (Custom Dice Keyboard Pages)

**Project Context:** The Keyboard tab provides a custom on-screen keyboard for dice notation entry, with two pages (numeric/math and dice notation tokens). We will implement both pages with a grid of buttons as specified, and allow switching between them via a toggle button and swipe gestures. This gives users a fast way to input complex expressions without a physical keyboard.

**Step Summary:** We will create a 5×5 grid of buttons for **Page A** (digits and math symbols) and another 5×5 grid for **Page B** (dice notation tokens like “kh”, “!!”, etc.) following the layout in the spec. We’ll add a toggle button labeled “α/β” to switch pages, and implement swipe left/right on the keyboard area to also flip between pages. Each button press will insert its token into the QueueLabel (updating the dice expression). The ROLL and ⌫ backspace on the keyboard will mimic the ones in the dice pad (trigger roll event, delete input).

**Prompt Parts:**

* **Restructure KeyboardTab:** In the TabContainer, we previously have **KeyboardTab** as a StackContainer with PageA and PageB. To add a persistent toggle button overlay, we will wrap this in a container:

  * Remove the current KeyboardTab StackContainer from TabContainer (or rename it).
  * Create a **Control** node (Container) named **KeyboardPanel**. This will serve as the content for the Keyboard tab.
  * Add **KeyboardPanel** to the TabContainer (instead of StackContainer) and set its tab title to "Keyboard". (If needed, adjust TabContainer to use this new node for the Keyboard tab.)
  * Move or re-add the **StackContainer** (name it **PagesStack** for clarity) as a child of KeyboardPanel. Ensure it fills the area (anchors full).
  * The StackContainer should have two children **PageA** and **PageB** (GridContainers) – we will recreate them as GridContainer nodes for the actual keys.
* **Create Page Grids:**

  * Add **GridContainer** named **PageA** as child of PagesStack. Set its **Columns** property to 5.
  * Add **GridContainer** named **PageB** likewise (5 columns).
  * (We won’t add any more children to PagesStack; it will show one of these grids at a time.)
* **Add Toggle Button:** In **KeyboardPanel**, add a **Button** named **TogglePageBtn** with text “α/β” (Greek alpha and beta characters). Position it at the top-right corner of the panel:

  * You can anchor it: set `TogglePageBtn.anchor_right = 1.0, anchor_top = 0.0, anchor_bottom = 0.0` and adjust margins so it hugs top-right (or simpler: set layout = TopRight, then give a small margin from edges).
  * Make it small (maybe 50×30 px or so).
  * This button will not be part of the StackContainer, so it remains visible regardless of which page is shown.
* **Populate Page A (Numeric/Math):** According to spec layout:

  * Row 1: `7, 8, 9, +, (`
  * Row 2: `4, 5, 6, –, )`  (Use a normal hyphen "-" for minus)
  * Row 3: `1, 2, 3, ×, /` (Use “×” U+00D7 for multiply symbol)
  * Row 4: `0, D, [blank], *, !`

    * Here, the third column is intentionally left blank (no button) to align things. We will insert a placeholder control for that blank.
    * The fourth column "\*", we interpret as multiplication sign or wildcard? (The spec shows `*` and `!` which likely mean wildcard and factorial/explode).
    * Use "\*" and "!" as given.
  * Row 5: **ROLL** (span 3 columns), **⌫** (span 2 columns).

    * Our grid container doesn’t support spanning cells automatically. We will handle this by using dummy placeholders:
    * We’ll add ROLL button, then two dummy controls, then Backspace button, then another dummy, so that effectively ROLL occupies first cell but is sized to span three, backspace in fourth spanning two.
  * Implementation in GridContainer PageA:

    * Add Buttons for each non-blank token in order. For numeric and single-char tokens, 64×64 is our base size. Set each button’s Custom Min Size = (64,64).
    * Where a blank is needed (Row4 col3): add a **Control** node with Custom Min Size (64,64) as a spacer placeholder.
    * For ROLL and Backspace (Row5):

      * Add a **Button** “ROLL”. Set its Custom Min Width to \~200 px (to cover roughly 3 columns of 64px + gaps) and height 64. This will visually span multiple columns.
      * Add two dummy **Control** placeholders for the two cells it spans beyond the first (Row5 col2 and col3 dummy). Give them min size (64,64).
      * Add a **Button** for backspace “⌫”. Set its Custom Min Width \~136 px (2 columns + gap). Height 64.
      * Add one dummy Control for the last cell (Row5 col5 dummy).
    * By adding in this sequence, the GridContainer will place them in cells:

      * Row1: 7,8,9,+,(
      * Row2: 4,5,6,-,)
      * Row3: 1,2,3,×,/
      * Row4: 0,D, \[dummy], \*, !
      * Row5: ROLL, \[dummy], \[dummy], ⌫, \[dummy]
    * This achieves the intended layout. The ROLL button will overlap the dummy cells next to it (since it’s wider than one cell) – that’s fine as those dummy controls are invisible. Ensure dummy placeholders have no visible skin (just empty Control).
    * **Note**: Mark the ROLL and ⌫ buttons distinctly (e.g., different color for ROLL).
* **Populate Page B (Notation Tokens):** Based on spec layout:

  * Row 1: `kh, kl, k, sa, sd`
  * Row 2: `s, r, ro, R, !!`
  * Row 3: `>=, <=, >, <, =`
  * Row 4: `f1, f<, cs, cf, p!`
  * Row 5: **ROLL** (span 3), **⌫** (span 2) – same idea as page A.
  * Add Buttons to PageB grid:

    * For each token, create a Button with that text. Use Custom Min Size (64,64) for uniform size.
    * If a token has multiple characters (e.g., "kh", "ro", "f<", "p!"), align its text to the right within the button for legibility. You can do: `button.align = HORIZONTAL_ALIGNMENT_RIGHT` (in Godot 4, for Button, set `text_align = TextAlign.RIGHT`).
    * Add them in the correct sequence. (No blank gaps needed on rows 1-4 here; all 5 columns are filled with tokens.)
    * For Row5 in PageB: same approach as PageA:

      * Add ROLL button (duplicate text "ROLL") with width \~200 px, then two dummy Controls, then Backspace "⌫" with width \~136 px, then one dummy.
  * Now PageB has all tokens.
* **Keyboard Script:** Attach a script to **KeyboardPanel** (the parent container) or the StackContainer to handle page switching and input insertion. (We’ll use KeyboardPanel so we can also control toggle button and pages.)

  * In the script’s `_ready()`, get references:

    * `pageA = $PagesStack/PageA`, `pageB = $PagesStack/PageB`, `stack = $PagesStack`, and `toggle_btn = $TogglePageBtn`.
    * Ensure initially: pageA is visible, pageB is hidden. (StackContainer typically only shows the first child by default; to be safe, set `pageB.visible = false`.)
  * **Toggle Button Logic:** Connect `TogglePageBtn.pressed` signal to a method `_on_TogglePage_pressed()`. In this handler:

    * If pageA is currently visible: hide pageA (`pageA.visible = false`), show pageB (`pageB.visible = true`).
    * Else if pageB visible: do the opposite.
    * (This effectively toggles which page is shown. The StackContainer will not automatically switch since we manually control visibility here.)
  * **Swipe Gesture Logic:** We want to allow swiping left/right on the keyboard to switch pages.

    * Override `_gui_input(event)` on KeyboardPanel or use `_unhandled_input` (since child buttons may consume events). We’ll attempt `_unhandled_input` on the parent:

      * If `event is InputEventScreenTouch` or `InputEventMouseButton`:

        * If `event.pressed` true, store the position `start_x = event.position.x` and maybe `dragging = true`.
      * If `event is InputEventScreenDrag` or `InputEventMouseMotion` and `dragging` true, (you can track movement but we might just check on release).
      * If `event is InputEventScreenTouch` or MouseButton with pressed false (release):

        * If we had a `start_x`, compute `dx = event.position.x - start_x`.
        * If `abs(dx) > 50` (threshold for a swipe):

          * If `dx < 0` (swiped left): user swiped from right to left, meaning go to next page → show pageB if currently on pageA.
          * If `dx > 0` (swiped right): user swiped left to right, meaning go to previous page → show pageA if currently on pageB.
        * (If a swipe is detected, toggle the pages accordingly, same as pressing the toggle button. If already on the appropriate edge page, you can ignore the swipe.)
      * Reset `dragging = false` on release.
    * Note: Since each button in the grid might capture the touch if tapped directly on it, swiping might need to start on empty space between buttons (there might be minimal empty space). This is a limitation, but we assume the user can find a spot or quickly drag to trigger.
  * **Connect Keyboard Buttons:** Now link all those keys to input insertion:

    * We can loop through all children of both PageA and PageB GridContainers. For each child that is a Button (and not a dummy Control):

      * Connect the button’s `pressed` signal to a common method `_on_Key_pressed(button_text)` (you can use the `button.text` as the token).

        * Use the `connect` with a bound parameter: e.g., `button.connect("pressed", callable(self, "_on_Key_pressed").bind(button.text))`.
    * Alternatively, connect individually where needed. But loop is efficient.
    * In `_on_Key_pressed(token)`: when any key is pressed:

      * If token is “ROLL”: trigger the Roll action (simulate pressing the main Roll button). We can call the same method as DicePad roll or emit the roll event (to be integrated with UIEventBus later). For now, you might directly call `DicePad._on_Roll_pressed()` or better, emit the roll request event (we will set that up in next prompt). For placeholder, just reuse DicePad’s function or print “Roll pressed”.
      * Else if token is “⌫” (backspace): perform the same backspace logic as the DicePad backspace. For simplicity, you can call the DicePad’s `_on_Backspace_pressed()` if accessible, or duplicate logic: remove last char of QueueLabel text.
      * Otherwise (any other token):

        * Append the token text to the **QueueLabel**. For example:

          ```gdscript
          var queue_label = get_node("/root/MainUI/DicePad/QueueLabel")
          queue_label.text += token
          ```
        * Some tokens are meant to be preceded by something (like if a user presses an operator “+” at start, it’s odd – we won’t handle such validation here). We simply insert the characters.
      * For spacing: the tokens provided already include necessary characters. We won’t add extra spaces except perhaps around certain tokens for readability, but the spec doesn’t mention adding spaces from keyboard input, so just concatenate.
  * Because we directly update QueueLabel here, the quantity selection logic (currentQuantity in DicePad) is bypassed for keyboard input. That’s acceptable since keyboard is a free-form input method; we treat it as literal insertion.
* Test the **Keyboard tab:**

  * The tab should default to Page A visible. Try pressing digit buttons – they should appear at the end of the queue label text. Press math symbols like “+”, “(” – they append as well. Try the “D” button – it appends “D” (user can then type a number after to form like D100, etc.).
  * Press ROLL on the keyboard – it should trigger the same action as the main Roll (currently perhaps printing or later will emit event).
  * Press backspace “⌫” on keyboard – it should remove the last char from the queue label (if any).
  * Toggle pages: Tap the “α/β” toggle button – Page B should become visible (Page A hidden). The tokens now are dice notation tokens. Press a few (e.g., “kh”, “<=”) – they should append exactly as their text (multi-character tokens just appear as those characters).
  * Swipe gesture: while on one page, try swiping horizontally on the keyboard area. If you swipe left (drag finger leftwards), it should switch to Page B (if on A). Swipe right should switch to Page A (if on B). Ensure the toggle button state also effectively changes (since we manually show/hide, the toggle button itself doesn’t need a state – it always just toggles current state).
  * The multi-character tokens should be right-aligned on their buttons (check that “kh”, “kl”, etc. appear right-justified within the button).
  * Now you have a fully functional on-screen keyboard for dice input.

## Prompt 11: Implement DrawerController – Sliding LowerPane Mechanics

**Project Context:** With all UI elements in place, we now enable the interactive sliding behavior of the LowerPane (the bottom drawer). This includes dragging gestures to open (preview or full) and close the drawer, and handling the locked state that requires a double-swipe to unlock. We’ll animate the drawer’s height and also dim the background during preview as specified.

**Step Summary:** We will create a global controller (Autoload or a script attached to LowerPane) to handle drag gestures for the drawer. It will:

* Manage a `locked` state (initially locked so one upward swipe unlocks without opening).
* Respond to upward drag: if locked, just unlock (and require a second swipe to actually open). If unlocked, open to preview height on first swipe, and to full height on second swipe (or a quick double-swipe opens fully immediately).
* Respond to downward drag: close the drawer (slide down to bottom).
* Animate the panel movement smoothly with tweens.
* Dim the main screen (dice pad area) when in preview state, and remove dimming when closed or fully open.

**Prompt Parts:**

* **DrawerController Setup:** Create a new GDScript named `DrawerController.gd`. This can be an Autoload (so it can capture input globally). For simplicity, we’ll attach it to an Autoload.

  * In Project Settings (or via code), add `DrawerController.gd` as an Autoload singleton (name it “DrawerController”). (If not via editor, we assume it’s autoloaded at runtime.)
  * In `DrawerController.gd`, `extends Node`.
* **References:** In \_ready(), get references to:

  * `lower_pane = get_node("/root/MainUI/LowerPane")` (the PanelContainer drawer).
  * Also get `main_ui = get_node("/root/MainUI")` and perhaps the dice pad node if needed for dimming.
  * Define constants for target heights: e.g., `FULL_HEIGHT = 960`, `PREVIEW_HEIGHT = 600`, `CLOSED_HEIGHT = 0` (closed).
  * Initialize state: `var locked = true`, `var is_open = false` (closed initially).
  * Create a **ColorRect** dim overlay to dim background on preview:

    * `var dimmer = ColorRect.new()`. Set `dimmer.color = Color(0,0,0,0.5)` and anchor full rect.
    * Add it as a child of MainUI *below* LowerPane. Use `main_ui.add_child_below_node(lower_pane, dimmer)` so that it covers dice pad but is under the LowerPane.
    * `dimmer.visible = false` initially.
* **Input Handling:** Use the singleton’s `_unhandled_input(event)` to catch global input (especially when LowerPane is closed and not catching events):

  * If `event is InputEventMouseButton or InputEventScreenTouch`:

    * If `event.pressed` true, store `start_y = event.position.y` and `dragging = true`.
    * If `event.pressed` false (release) and `dragging`:

      * Compute `dy = start_y - event.position.y` (a positive `dy` means an upward drag).
      * Also compute total drag time or velocity if needed via `event` properties.
      * If `dy > 50` (significant upward swipe):

        * If `locked`:

          * Check double-swipe logic: if we have a timestamp of last unlock attempt:

            * If this is the second quick swipe within, say, 1 second of last attempt: **unlock and fully open**.

              * Set `locked = false`.
              * Call a function to animate LowerPane to FULL\_HEIGHT immediately.
            * Else (first swipe):

              * **Unlock** without opening: set `locked = false`.
              * (Optionally, you might give a small feedback – e.g., a slight jiggle or haptic if available – but not required.)
              * Do NOT change drawer height (keep closed).
              * Record the time of unlock (for next swipe to detect double).
          * End.
        * If not locked (already unlocked):

          * If drawer is currently closed (`!is_open`):

            * **Open to preview:** animate LowerPane height to PREVIEW\_HEIGHT (600 px).
            * Set `is_open = true` and maybe track a state `current_state = "preview"`.
            * Show the dimmer overlay: `dimmer.visible = true` (this dims the background because we are in preview).
          * Else if current state is "preview":

            * **Open to full:** animate height from 600 to 960.
            * Set `current_state = "full"`.
            * (At full open, we can optionally hide the dimmer because now the lower pane covers its portion fully. The dice pad above is still visible but according to spec, dimming is mainly for preview. We will turn off dimmer on full open.)
            * So, `dimmer.visible = false` once fully open.
          * Else if current state is already "full":

            * (If user swipes up when full, nothing to do or you might keep it as full.)
      * If `dy < -50` (a downward swipe):

        * If LowerPane is currently open in any state (preview or full):

          * **Close the drawer:** animate height to CLOSED\_HEIGHT (0).
          * Set `is_open = false`, `current_state = "closed"`.
          * Hide the dimmer overlay: `dimmer.visible = false` (no dim needed when closed).
          * (Also, if you want to relock on close for next time, you might reset `locked = true` depending on desired behavior. Possibly once unlocked, it stays unlocked during a session. Spec implies lock is to prevent accidental open mid-game; might re-lock after a certain condition. We can choose to **not** relock on every close, so user doesn’t always double-swipe. Perhaps lock can be toggled via a UI lock icon (the TopBar lock icon we have). For now, we’ll assume the lock icon in TopBar might be intended to lock/unlock the drawer. If so, initial state locked, but user can unlock via double-swipe or maybe tapping lock. We haven’t wired IconLock – could be a manual lock toggle.)
          * For simplicity, we’ll leave `locked` as is (once unlocked, remain unlocked unless explicitly toggled).
      * End dragging (`dragging = false`).
  * If `event is InputEventMouseMotion or ScreenDrag` and `dragging`:

    * We can optionally implement real-time follow: e.g., if not locked and the user is dragging, adjust LowerPane.height in real-time to follow the finger (between 0 and full). This would make the drawer track the drag for a smoother feel.
    * For example, if closed and dragging upward: `new_height = clamp(dy, 0, FULL_HEIGHT)`, set `lower_pane.rect_size.y = new_height` as they drag.
    * Similarly for dragging down from open: decrease height accordingly.
    * This is a nice-to-have; if not comfortable, we can skip continuous updates and just snap on release with the above logic.
  * **Animation Implementation:** Use a Tween for smooth transitions:

    * Create a Tween node (or use `lower_pane.tween_property`). Example:

      ```gdscript
      lower_pane.tween_property(lower_pane, "rect_size:y", target_height, 0.3)
      ```

      This animates the panel’s height to `target_height` in 0.3 seconds.
    * Do this when opening to preview, opening full, or closing, instead of jumping instantly.
* **TopBar Lock Icon (Optional):** We have an IconLock TextureRect in TopBar. We can tie it to the lock state:

  * You could toggle its texture or modulate when locked/unlocked. For now, perhaps on unlock you could hide an overlay on it or change icon.
  * If we want, connect a mouse event on IconLock:

    * If tapped, toggle `locked` true/false. (That would allow user to manually lock the drawer closed again.)
    * Update its appearance accordingly (e.g., a closed lock vs open lock icon). Since we only have a placeholder, you might just print or modulate color (green for unlocked).
    * This is an extra; not in original scope explicitly, but logical. We can mention it.
* Test the drawer behavior:

  * Start with app running: LowerPane presumably closed (if we manually set initial height to 0 now, or programmatically at start).

    * If we didn’t, set `lower_pane.rect_size.y = 0` at start of DrawerController to ensure closed.
  * Try to drag up on the bottom of the screen: Because it was locked, the first drag should do nothing visible (just unlock internally). The second quick drag up:

    * If done quickly (within 1 second), DrawerController should interpret as double-swipe and open fully. The LowerPane should animate all the way up to 960px (half screen open, covering dice pad bottom). Dimmer likely off at full open.
    * If the second drag was slower (after 1s), it would not trigger the “immediate full open” shortcut, so it should open only to preview (600px) on that second drag. In preview state, the dice pad above should still be partially visible; we turn on the dim overlay so dice pad and background appear dimmed behind the semi-open drawer.
  * If in preview (600px open, dimmed top):

    * Another upward drag (now with unlocked state and in preview) should animate to full (960px) and we remove dimming.
  * Drag down from either preview or full:

    * The drawer should slide closed to 0, and the dimming overlay should hide. The drawer remains unlocked in our logic, so a single drag up later would directly open preview.
    * Check if you want to re-lock on close. If not, the IconLock might always show unlocked after first double-swipe.
  * The transitions should be smooth due to tweens.
  * Ensure the dimmer overlay covers and dims the dice pad region only when expected (when in preview). At full open, dice pad might not be visible at all (depending if we overlapped or pushed it). In our design, LowerPane at 960px meets dice pad bottom at 960px, so dice pad fully visible above. We chose to turn off dimming at full open as per design (dimming specifically mentioned for preview).
  * Adjust timing or threshold if needed. The drawer should feel responsive but not open on tiny accidental drags.
  * (If the drag detection is finicky due to UI events, you might consider making a small invisible handle area at screen bottom always active to catch drags. For now, assume unhandled\_input will catch it if no UI consumed it.)
  * Now the sliding drawer is implemented with lock/unlock logic and proper animations.

## Prompt 12: Create UIEventBus and Connect Global Signals

**Project Context:** Now we integrate a global event bus for the UI, to decouple UI components and prepare for backend integration. This involves defining signals for key actions (roll requests, system selection, etc.) and connecting our UI elements to emit/listen to these signals. This final step ties the independent pieces together – when the Roll button is pressed, the RollTab animation plays; when a system is selected, it could be handled globally; and so on.

**Step Summary:** We will implement `UIEventBus.gd` as an Autoload singleton with signals like `roll_requested(notation)`, `system_selected(system_name)`, etc. Then:

* Modify the Roll button and Keyboard ROLL to emit `roll_requested` (with the queue notation string).
* Connect the RollTab script to listen for `roll_requested` and trigger its animation.
* Emit `system_selected` when a system is chosen from the Systems list or favorites overlay.
* (Optionally, emit `theme_changed(color)` when theme color changes, etc., to illustrate extensibility.)
* This event bus will allow the UI to notify the game logic or other parts without direct references.

**Prompt Parts:**

* **UIEventBus Autoload:** Create a new script `UIEventBus.gd`, `extends Node`. In it, define signals:

  ```gdscript
  signal roll_requested(notation)
  signal system_selected(system_name)
  signal theme_changed(color)
  # (Add any others you foresee, e.g., dice_expression_updated, etc., but we'll focus on these.)
  ```

  * In Project Settings, add this script as an Autoload named **UIEventBus**.
* **Emit Roll Requested:** Update the DicePad Roll button handler (from Prompt 3) and the Keyboard ROLL handler (Prompt 10) to emit this signal:

  * In DicePad.gd’s `_on_Roll_pressed()`, instead of just printing, do:

    ```gdscript
    UIEventBus.emit_signal("roll_requested", QueueLabel.text)
    ```

    (Because UIEventBus is autoload, we can call it globally by name.)
  * In the Keyboard `_on_Key_pressed(token)` logic, when token == "ROLL", similarly:

    ```gdscript
    UIEventBus.emit_signal("roll_requested", queue_label.text)
    ```

    Make sure to get the QueueLabel’s current text (you can store a reference or fetch via node path).
  * Now a single source of truth: whenever any UI roll action happens, the `roll_requested` event fires with the notation string.
* **Connect RollTab to Roll Requested:** In RollTab.gd (the script handling animation in Prompt 5), connect to this signal:

  * In RollTab’s `_ready()`, add:

    ```gdscript
    UIEventBus.connect("roll_requested", self, "_on_RollRequested")
    ```

    (Make sure you have a corresponding method `_on_RollRequested(notation)` defined.)
  * Implement `_on_RollRequested(notation)` to trigger the animation:

    * For example, call the existing `play_basic_animation()` function (you may use the notation if you want to customize animation based on it; e.g., decide number of dice, or simply ignore content).
    * If you want, parse `notation` string to count how many dice or which type, but that’s beyond placeholder scope. For now, we might just print it or decide a fixed animation.
    * E.g.:

      ```gdscript
      func _on_RollRequested(notation):
          print("Roll requested for: ", notation)
          play_basic_animation()
      ```
    * This way, whenever the user hits Roll (from dice pad or keyboard), the RollTab will receive the event and play the dice animation.
* **Emit System Selected:** Update SystemsTab script and FavOverlay script to emit this signal when a system is chosen:

  * In SystemsTab (SystemVBox) `_on_System_pressed(name)`, after logging or doing local changes, add:

    ```gdscript
    UIEventBus.emit_signal("system_selected", name)
    ```
  * Similarly, in FavOverlay, when a favorite is clicked (before hiding overlay), emit:

    ```gdscript
    UIEventBus.emit_signal("system_selected", system_name)
    ```

    (And possibly call the SystemsTab.select\_system as we did to keep UI consistent, which itself might emit again – to avoid duplicate, you could either rely only on event or sync carefully. It’s okay if both emit; it just means two signals to same listeners, which likely won’t hurt if idempotent.)
* **(Optional) Listen for system selection:** We don’t have a direct UI change tied to system selection yet (like changing active ruleset label). If needed, you could connect `system_selected` to some label in TopBar or dice pad to show current system.

  * For completeness, if the TopBar had a label for the active system or an icon, you’d update it here. We’ll skip, as design didn’t specify such display explicitly.
  * But we ensure the signal is emitted for backend or other logic to use.
* **Emit Theme Changed:** In SettingsTab’s color picker handler `_on_Color_changed(color)`, after applying the color, emit:

  ```gdscript
  UIEventBus.emit_signal("theme_changed", color)
  ```

  * This allows, for instance, an external module or the app to save the theme or apply globally.
  * We might not have any listener for theme\_changed in UI now, but we define it for completeness. (Alternatively, we could have connected this to change theme on the fly if we had a unified theme system.)
* **Test Signals Flow:**

  * Press the Roll button on the interface:

    * It should emit `roll_requested` with the queue notation. The RollTab should receive this and execute its animation (watch the console for any prints or the animation visuals).
    * So now clicking Roll actually triggers the dice roll animation in the Roll tab view.
  * Press Roll on the keyboard tab:

    * Should do the same as above (because we connected both to event).
  * Select a system from the Systems list or favorites overlay:

    * The `system_selected` signal fires with that name. We don’t have a visible UI change, but you can test by connecting this signal temporarily to a print. For example, in UIEventBus.gd \_ready, do:

      ```gdscript
      connect("system_selected", self, "_on_system_selected")
      func _on_system_selected(name):
          print("System changed to: ", name)
      ```
    * Or observe any debug output from where we handle it. This demonstrates the event is working.
  * Change the theme color in Settings:

    * Ensure it emits `theme_changed` (if you connected something to it, like printing, you’d see it).
    * Also see that it still changes the UI element color as before.
  * With these, our UI is fully wired: the central event bus means the roll logic can be handled in one place (RollTab), and system changes broadcast to any part of the app or game logic (e.g., a game manager could listen to `UIEventBus.system_selected` to load rule definitions, etc.).

**Sources:**

* Dice Roller Node Blueprint and UI Spec provided by the project. These guided the layout and signal design for each component.
