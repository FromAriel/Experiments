# 🎲 Glossary of Common Dice Notation and Nomenclature

This glossary defines commonly used dice notation systems in tabletop RPG apps and dice rollers (e.g., AnyDice, Foundry VTT, Roll20, RPG Dice Roller libraries). Where multiple formats are in use, variations are listed side by side. This section has been reviewed against the detailed technical documentation for the LIVEdie project, GNOLL parser, roll.py, AnyDice, Foundry VTT, Icepool, OmniDice, dyce, and rpg-dice-roller to ensure comprehensive coverage.

---

## 🎯 Core Dice Roll Format

### Basic Roll

| Format | Meaning                         |
| ------ | ------------------------------- |
| `NdX`  | Roll N dice with X sides        |
| `3d6`  | Roll 3 six-sided dice           |
| `d20`  | Shorthand for `1d20`            |
| `d%`   | Percentile die (same as `d100`) |

---

## 🧮 Arithmetic Modifiers

### Add/Subtract

| Format  | Meaning                 |
| ------- | ----------------------- |
| `3d6+2` | Roll 3d6 and add 2      |
| `d8-1`  | Roll 1d8 and subtract 1 |

### Multiply/Divide *(less common, mostly in scripting)*

| Format             | Meaning              |
| ------------------ | -------------------- |
| `2d6*2` or `2d6×2` | Multiply result by 2 |
| `4d10/2`           | Divide total by 2    |

---

## 🎯 Target & Success-Based Rolls (e.g., White Wolf, Shadowrun)

### Success Thresholds

| Format      | Meaning                                             |
| ----------- | --------------------------------------------------- |
| `8d10>=7`   | Count how many dice rolled 7 or more                |
| `10d6>4`    | Count results > 4                                   |
| `6d10>=8f1` | Count dice 8+ as successes; 1s are failures/botches |
| `5d6=6`     | Count how many dice rolled exactly 6                |

### Exploding Dice

| Format             | Meaning                             |
| ------------------ | ----------------------------------- |
| `5d6!`             | Reroll and add dice that rolled max |
| `5d6!!`            | Recursively explode dice            |
| `4d10!10`          | Explode only if 10 is rolled        |
| `4d6!>4`           | Explode if greater than 4           |
| `4d6!<3`           | Explode if less than 3              |
| `4d6!p` or `4d6p!` | Penetrating explosion (reroll -1)   |

---

## 🔁 Keep, Drop, Reroll, Sort

### Keep/Drop Dice

| Format                | Meaning                  |
| --------------------- | ------------------------ |
| `4d6k3` or `4d6kh3`   | Keep highest 3 of 4 dice |
| `4d6kl2`              | Keep lowest 2 of 4 dice  |
| `5d10d1` or `5d10dl1` | Drop lowest 1 die        |
| `6d8dh2`              | Drop highest 2           |

### Reroll Rules

| Format   | Meaning                                |
| -------- | -------------------------------------- |
| `4d6r1`  | Reroll any die showing 1               |
| `4d6ro1` | Reroll once if 1 is rolled (only once) |
| `4d6r<2` | Reroll dice that rolled 1 or 2         |
| `4d6R<3` | Reroll dice less than 3 indefinitely   |

### Sorting

| Format  | Meaning                   |
| ------- | ------------------------- |
| `4d6s`  | Sort dice ascending       |
| `4d6sa` | Sort ascending (explicit) |
| `4d6sd` | Sort descending           |

---

## 📊 Conditional Evaluation & Labels

### Success Tests with Conditions

| Format      | Meaning                              |
| ----------- | ------------------------------------ |
| `6d10>=8`   | Count successes rolling 8+           |
| `6d10>=8f1` | Also count 1s as failures or botches |
| `5d6>4f<2`  | Count >4 as success, <2 as failure   |

### Named Rolls or Labels

| Format            | Meaning                   |
| ----------------- | ------------------------- |
| `damage: 2d6+3`   | Label result as "damage"  |
| `atk[d20]+mod[3]` | Separate named components |

---

## 🧠 Boolean and Logic Expressions

| Format         | Meaning                              |
| -------------- | ------------------------------------ |
| `(2d6+3) > 10` | Returns true/false if total > 10     |
| `4d6r1k3>=5`   | Complex: reroll 1s, keep 3, count 5+ |

---

## 🔄 Pools, Nested Rolls, and Macros

### Dice Pools

| Format         | Meaning                             |
| -------------- | ----------------------------------- |
| `pool(5d6>=4)` | Count how many of 5d6 are 4 or more |

### Inline Rolls

| Format          | Meaning                         |
| --------------- | ------------------------------- |
| `1d6 + 2d4`     | Add together two separate rolls |
| `2d6 + (1d4*2)` | Parentheses used for math order |

### Macros / References

| Format          | Meaning                      |
| --------------- | ---------------------------- |
| `$atk = 1d20+5` | Save macro called "atk"      |
| `$atk + 2d6`    | Use macro and add extra dice |

---

## 🎲 Fate/Fudge Dice Notation

| Format  | Meaning                               |
| ------- | ------------------------------------- |
| `dF`    | Fate die: returns -1, 0, or +1        |
| `4dF`   | Standard Fate roll, range of –4 to +4 |
| `4dF+2` | Standard roll with modifier           |

---

## 🔍 Rare/Alternate Notations from Other Engines

| Format                | Engine/Context            | Meaning                            |
| --------------------- | ------------------------- | ---------------------------------- |
| `NdXcs>=Y`            | Roll20                    | Critical success threshold (cs)    |
| `NdXcf<=Z`            | Roll20                    | Critical failure threshold (cf)    |
| `Xd6 vs Yd6`          | Genesys-style             | Opposed dice pool comparison       |
| `d100<=TN`            | Warhammer/AoS             | Target number check for percentile |
| `adv[d20]`            | Macros/labels (some DSLs) | Advantage-style roll (see below)   |
| `2d20kh1` / `2d20kl1` | Foundry, Roll20           | Advantage/disadvantage             |
| `F` or `4F`           | Alternate Fudge notation  | Equivalent to `dF`                 |

---

## 🧩 Parser Design Notes (Advanced Use)

### Suggested Regex Patterns (Simplified Examples)

```regex
(?P<count>\d*)d(?P<faces>\d+|%)
(?P<expr>\d*d\d+[a-z0-9<>!=]+\d*)
```

### Parser Behaviors

* Accept whitespace-insensitive formats: `3 d6`, `d 8`, etc.
* Normalize inputs before evaluation (e.g., convert `d%` to `d100`)
* Support nested expressions and macros with inline evaluation

### Validation Recommendations

* Reject illegal dice sizes (e.g. `0d6`, `2d0`, negative sides)
* Return syntax errors with helpful hints

### Libraries to Reference or Wrap:

* **rpg-dice-roller** (JavaScript)
* **dyce** (Python)
* **Icepool** (Python)
* **AnyDice** (analysis via static code)
* **Foundry VTT's** built-in dice engine
* **GNOLL parser** (live session support)

---

This glossary has been matched to known conventions in AnyDice, GNOLL, Icepool, OmniDice, Roll20, Foundry VTT, dyce, and rpg-dice-roller. Further expansions may include visual flowcharts, debug modes, or graphical parser trees.
