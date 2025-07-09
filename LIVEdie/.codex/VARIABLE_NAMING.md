# Variable Naming Convention for AI/Code Agent–Friendly Refactoring

## Overview

This project uses a structured variable and function naming scheme designed for maximum compatibility with AI code agents such as Codex, Copilot, or similar automated tools.
The scheme encodes script/class context, variable/function name, and functional ownership into every exported/shared identifier, supporting safe automation and large-scale refactoring.

---

## Naming Pattern

Each relevant variable or function name follows this pattern:

<SC>_<variable_name>_<FN>

- <SC> = Two-letter abbreviation for the **owning script or class**
- <variable_name> = Descriptive snake_case core name
- <FN> = Two-letter abbreviation for the **primary function or method** responsible for the logic or modification of this variable/function

**Example:**  
TK_fish_count_CS  
- TK = Tank.gd script  
- fish_count = number of fish  
- CS = Census() function (main logic/owner)

---

## Rationale

- **Unambiguous:** Prevents accidental variable shadowing or collision across scripts/functions.
- **Traceable:** Every identifier encodes both code context and logic owner, making navigation and debugging easier.
- **AI/Agent Parsing:** Enables rapid, context-aware search, analysis, and bulk edits by LLMs or automation tools.
- **Scalable:** Supports regex- or agent-driven refactoring with zero ambiguity.
- **Human-Friendly:** Instantly communicates "where and why" for every identifier.

---

## Pattern Details

### 1. <SC> — Script/Class Abbreviation
- Always **two uppercase letters**
- Example assignments:
  - TK = Tank.gd
  - FS = Fish.gd
  - BM = BoidManager.gd

### 2. <variable_name> — Core Name
- Always **snake_case**
- Should be concise, clear, and descriptive
- Examples: fish_count, color, flock_speed

### 3. <FN> — Function/Method Abbreviation
- Always **two uppercase letters**
- Indicates the **primary function, method, or behavior group** responsible for logic/ownership
- Example assignments:
  - CS = Census (population counting)
  - IN = Initialization
  - MV = Move
  - SH = Shared/multiple owners

---

## Example Table

| Variable Name         | Meaning                              | Script   | Function/Method |
|---------------------- |--------------------------------------|----------|-----------------|
| TK_fish_count_CS      | Tank's fish count, managed by Census | Tank.gd  | Census          |
| FS_color_IN           | Fish color, set during Init          | Fish.gd  | Initialization  |
| BM_flock_speed_MV     | Flock speed, modified in Move        | BoidMgr  | Move            |
| FS_position_UP        | Position, updated in Update          | Fish.gd  | Update          |

---

## Best Practices

- **Maintain a master mapping table** of script/class and function/method abbreviations (see above).
- **Update abbreviations** if logic/function names change.
- **Apply this pattern** to all exported, signal, and cross-script/shared data. Local private variables may use short forms as appropriate.

---

## Regex/Linting

This scheme supports regex or static analysis for enforcement. Example regex pattern:
```
^[A-Z]{2}_[a-z0-9_]+_[A-Z]{2}$
```
---

## Codex/AI Agent Instructions

- **When generating new variables/functions, always use this pattern.**
- **When searching or refactoring, leverage the <SC> and <FN> segments to group and map related data.**
- **Never omit context or function ownership from major/shared identifiers.**

---

## Summary

**This naming convention is mandatory for all shared/project-level code.  
Adherence enables robust, AI-assisted, and easily maintainable development workflows.**
