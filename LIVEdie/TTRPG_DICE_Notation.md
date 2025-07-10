
Below is an **extensive breakdown** of the most common dice-notation terms and abbreviations you’ll encounter in RPG engines, libraries, and virtual tabletops. For each, you’ll see what the abbreviation stands for, how it’s used in formulas, and an example of its syntax.

---

## **1\. Basic Notation**

| Abbrev. | Stands For | Usage | Example |
| ----- | ----- | ----- | ----- |
| `NdX` | **N** dice of **X** sides | Base roll of N dice, each with X faces | `3d6` |
| `d%` | Percentile die | Two ten-sided dice, one for tens and one for ones | `1d%` (00–99) |
| `dF` | Fudge/Fate die | Special die returning –1, 0, or \+1 | `4dF` |
| `F` | Fudge shorthand | Equivalent to `dF` | `4F` |

---

## **2\. Arithmetic Operators**

| Symbol | Meaning | Usage | Example |
| ----- | ----- | ----- | ----- |
| `+` | Add constant | Add a fixed modifier to the total | `2d8+3` |
| `-` | Subtract constant | Subtract a fixed modifier | `5d6-1` |
| `*` | Multiply | Multiply final result | `(1d6+2)*3` |
| `/` | Divide | Divide final result | `(2d10)/2` |
| `()` | Grouping | Control order of operations | `(4d6kh3)+2` |

---

## **3\. Keep/Drop Dice**

| Abbrev. | Stands For | Usage | Example |
| ----- | ----- | ----- | ----- |
| `khN` | **k**eep **h**ighest N | Keep only the highest N dice of the roll | `4d6kh3` |
| `klN` | **k**eep **l**owest N | Keep only the lowest N dice | `4d6kl2` |
| `dhN` | **d**rop **h**ighest N | Drop the highest N dice, sum the rest | `5d10dh1` |
| `dlN` | **d**rop **l**owest N | Drop the lowest N dice | `5d10dl1` |

---

## **4\. Reroll Mechanics**

| Abbrev. | Stands For | Usage | Example |
| ----- | ----- | ----- | ----- |
| `r<k` | **r**eroll if `< k` | Any die less than k is rerolled once | `4d6r<2` (reroll 1s) |
| `r>k` | **r**eroll if `> k` | Reroll any die greater than k | `5d8r>7` |
| `r<=k` | reroll if `≤ k` | Includes equal | `3d10r<=2` |
| `ro<k` | **r**eroll once if `< k` | Like `r<k`, but only once per die | `4d6ro<2` |
| `ro>=k` | **r**eroll once if `≥ k` | Reroll only once if die meets condition | `5d6ro>=6` |
| `ra<k` | **r**eroll **a**ll if `< k` | Continue rerolling until the die is ≥ k (potentially infinite) | `4d6ra<2` |

---

## **5\. Exploding & Penetrating Dice**

| Abbrev. | Stands For | Usage | Example |
| ----- | ----- | ----- | ----- |
| `!` | **explode on max** | If a die rolls its maximum, roll it again and add (once) | `6d6!` |
| `!!` | **compound explode** | Explode repeatedly, summing all results | `6d6!!` |
| `!>k` | explode if `> k` | Explode on results above k (instead of max) | `4d10!>8` |
| `!<k` | explode if `< k` | Explode on low results | `4d10!<3` |
| `p` | **penetrate** | Explode but subtract 1 from each explosion (non-compound) | `6d6p` |
| `p!!` | **penetrate & compound** | Compound penetrate explosions | `6d6p!!` |

---

## **6\. Success & Failure Counting**

| Abbrev. | Stands For | Usage | Example |
| ----- | ----- | ----- | ----- |
| `>=N` | success on `≥ N` | Count dice whose result is at least N | `5d6>=5` (\# successes) |
| `<=N` | success on `≤ N` | Count dice whose result is at most N | `5d6<=2` |
| `>N` | success on `> N` | Strict greater than | `5d6>4` |
| `<N` | success on `< N` | Strict less than | `5d6<3` |
| `cs>=N` | **c**ritical **s**uccess ≥ N | Count critical successes | `1d20cs>=20` |
| `cf<=N` | **c**ritical **f**ail ≤ N | Count critical failures | `1d20cf<=1` |
| `count X` | count exact matches | Count how many dice equal X | `4d6count 6` |

---

## **7\. Pool Rolls & System-Specific**

| Notation | System / Usage | Example |
| ----- | ----- | ----- |
| `Xd6 vs Yd6` | Opposed roll (e.g. Genesys, SWADE) | `4d6 vs 3d6` |
| `Nd20adv` | Advantage (roll 2d20 keep highest 1\) | `d20adv` → `2d20kh1` |
| `Nd20dis` | Disadvantage (keep lowest) | `d20dis` → `2d20kl1` |
| `W` dice pools: e.g. `10d6` | Shadowrun-style success pools | `10d6>=5` (count successes) |

---

## **8\. Fate/Fudge-Style Dice**

| Notation | Meaning | Example |
| ----- | ----- | ----- |
| `dF` | Fudge die (–1, 0, \+1) | `4dF` |
| `F` | Shorthand for `dF` | `4F` |
| `+/-` | Fudge sum runs from –N to \+N | `4dF+2` |
| Success rules vary by system (e.g. \[+1 \= positive\] vs \[–1 \= negative\]) |  |  |

---

## **9\. Grouping & Nesting**

| Syntax | Purpose | Example |
| ----- | ----- | ----- |
| `()` | Control order, apply modifiers to sub-expression | `(2d6+1)d4` |
| `[]` | Some DSLs use square brackets for function args | `sum([1d6, 2d8, 1d4])` |
| `{}` | Set notation in AnyDice | `output [1d6, 1d8, 1d10]` |

---

## **10\. Functions & Advanced**

| Function | Purpose | Example |
| ----- | ----- | ----- |
| `min(a,b)` | Minimum of a and b | `min(1d6, 1d8)` |
| `max(a,b)` | Maximum | `max(1d6, 1d8)` |
| `floor(x)` | Round down | `floor((1d20)/2)` |
| `ceil(x)` | Round up | `ceil((1d20)/2)` |
| `sum(list)` | Sum elements of a list | `sum([2d6, 3d4])` |
| `rolls` | Return array of individual die results | `rolls(4d6kh3)` |
| `sort(a,b)` | Sort results | `sort(4d6)` |

---

## **11\. Putting It All Together**

A single formula might combine many of the above:

(4d6r\<2\! \+ 2d8p\!\! \>= 6\) \* max(1d4, 2\) \- sum(\[1d10dl1, 3d4\])

* **`4d6r<2!`**: roll 4d6, reroll any 1s once, then explode on max

* **`2d8p!! >=6`**: roll 2d8, penetrate-explode compound, then count successes ≥6

* **`max(1d4,2)`**: compare a 1d4 roll to 2, keep the higher

* **`sum([1d10dl1,3d4])`**: sum a 1d10 drop-lowest-1 plus 3d4

---

This guide should cover **dozens** of standard and extended notation terms you’ll see in libraries like **rpg-dice-roller**, VTTs like Roll20/Foundry, or modeling tools like AnyDice. Let me know if there are any other specialized modifiers or DSL features you’d like to explore\!

# **Dice Rolling Mechanics Across Major Tabletop RPG Systems**

Different tabletop RPGs use a variety of dice rolling mechanics to determine success or failure of actions. Below is a comprehensive, prioritized list of major systems and their core dice mechanics, followed by a few lesser-known examples. Each entry includes the standard dice notation, a formula or rule representation, and a Godot 4.4 GDScript code snippet demonstrating the roll logic.

## **Dungeons & Dragons (d20 System)**

**Core Mechanic:** D\&D uses a single twenty-sided die (d20) for resolution. To attempt an action, you roll 1d20 and add relevant modifiers (from skills, abilities, etc.), then compare the total to a target number called a Difficulty Class (DC). If the total is equal to or greater than the DC, the action succeeds; otherwise, it fails.

* **Dice Notation:** *1d20 \+ modifier vs. DC*

* **Formula:** `result = d20 + modifiers`; **Success** if `result ≥ DC`.

**Godot Code:** (Roll a d20 and check against a target DC)

 var rng \= RandomNumberGenerator.new()  
rng.randomize()  
var roll \= rng.randi\_range(1, 20\)     \# 1d20 roll  
var total \= roll \+ modifier           \# add ability/skill modifiers  
var success \= total \>= difficulty\_class

* 

## **Pathfinder (d20 System)**

**Core Mechanic:** Pathfinder (especially 1st edition, derived from D\&D 3.5) uses the same d20 resolution as D\&D. Roll a 20-sided die and add your modifiers, then compare to a target Difficulty Class. Meeting or exceeding the target means success. *(Pathfinder 2E adds “degree of success” rules, e.g. rolling 10 over the DC is a critical success, but the fundamental roll is still d20 vs DC.)*

* **Dice Notation:** *1d20 \+ modifier vs. DC*

* **Formula:** `result = d20 + modifiers`; **Success** if `result ≥ DC`.

**Godot Code:**

 var rng \= RandomNumberGenerator.new()  
rng.randomize()  
var roll \= rng.randi\_range(1, 20\)    \# 1d20 roll  
var total \= roll \+ modifier          \# add skill/ability bonus  
var success \= total \>= difficulty\_class

* 

## **World of Darkness (d10 Pool)**

**Core Mechanic:** Classic *World of Darkness* (Storyteller System) uses a **dice pool** of ten-sided dice. The player rolls a number of d10s equal to their skill \+ attribute. Each die that meets or exceeds a difficulty threshold (often 6 or higher by default) counts as one “success.” The action’s success is determined by the number of successes rolled (e.g. at least 1 success for a basic task). In older editions, rolling no successes and any die showing 1 is a **botch** (critical failure). Newer *Chronicles of Darkness* editions use a fixed threshold (8+ on d10) with 10s allowing an extra roll (exploding) for additional successes.

* **Dice Notation:** *Xd10 vs. threshold (count successes)*

* **Formula:** `successes = count_{i=1..N}(d10_i ≥ difficulty)`; **Success** if `successes ≥ required` (typically at least 1).

**Godot Code:** (Roll N d10s and count successes)

 var rng \= RandomNumberGenerator.new()  
rng.randomize()  
var successes \= 0  
for i in range(num\_dice):  
    var roll \= rng.randi\_range(1, 10\)   \# d10 roll  
    if roll \>= difficulty\_threshold:  
        successes \+= 1  
var success \= successes \>= required\_successes  \# e.g. \>=1 for a basic check

* 

## **Shadowrun (d6 Pool)**

**Core Mechanic:** *Shadowrun* uses a **dice pool** of six-sided dice. You roll a number of d6s equal to your skill \+ attribute. Each die that comes up 5 or 6 is counted as a “hit” (a success). The more hits, the better – you need to achieve a number of hits at or above the task’s difficulty to succeed. If you roll very few successes and a lot of 1s, the system can trigger a **glitch** (a critical failure). Shadowrun’s mechanic is roll-high (counting 5+ as success) in contrast to WoD’s d10 roll-under-a-threshold approach.

* **Dice Notation:** *Xd6 (5+ counts as success)*

* **Formula:** `hits = count_{i=1..N}(d6_i ≥ 5)`; **Success** if `hits ≥ threshold` (number of hits required).

**Godot Code:** (Roll N d6s and count “hits”)

 var rng \= RandomNumberGenerator.new()  
rng.randomize()  
var hits \= 0  
for i in range(num\_dice):  
    var roll \= rng.randi\_range(1, 6\)    \# d6 roll  
    if roll \>= 5:                      \# 5 or 6 counts as a success  
        hits \+= 1  
var success \= hits \>= required\_hits    \# compare to difficulty threshold

* 

## **Call of Cthulhu (Percentile System)**

**Core Mechanic:** *Call of Cthulhu* (and other BRP-based games) use a **percentile roll-under** system. Characters have skill percentages (1–100). To attempt an action, you roll 1d100 (percentile dice) and compare the result to your skill value. If the d100 roll is equal to or less than your skill, the action is a success. Rolling above the skill is a failure. Lower rolls can indicate greater degrees of success (and some games define “critical” success at very low rolls, or “fumbles” at very high rolls, but the basic check is roll under skill).

* **Dice Notation:** *1d100 (percentile) vs. skill %*

* **Formula:** `roll = d100`; **Success** if `roll ≤ skill_value`.

**Godot Code:** (Percentile roll-under check)

 var rng \= RandomNumberGenerator.new()  
rng.randomize()  
var roll \= rng.randi\_range(1, 100\)    \# d100 roll (1–100)  
var success \= roll \<= skill\_value

* 

## **GURPS (3d6 Roll-Under)**

**Core Mechanic:** *GURPS* resolves actions by rolling three six-sided dice and summing them (3d6). It is a **roll-under** system: you succeed if the total rolled is less than or equal to your skill or target number. The probability distribution of 3d6 is bell-curved (centered at 10 or 11), making extreme rolls less common. A roll of 3 or 4 is usually a critical success, and 17–18 a critical failure, but the core mechanic is simply checking if 3d6 ≤ skill.

* **Dice Notation:** *3d6 vs. skill (roll under)*

* **Formula:** `total = d6_1 + d6_2 + d6_3`; **Success** if `total ≤ skill`.

**Godot Code:** (Roll 3d6 and check against skill)

 var rng \= RandomNumberGenerator.new()  
rng.randomize()  
var total \= rng.randi\_range(1, 6\) \+ rng.randi\_range(1, 6\) \+ rng.randi\_range(1, 6\)  
var success \= total \<= skill\_value

* 

## **Fate Core (Fudge Dice 4dF)**

**Core Mechanic:** *Fate* uses four **Fudge dice** (notated as 4dF). Fudge dice are six-sided dice with faces marked \+1, 0, or –1 (two of each). Rolling 4dF produces a result between –4 and \+4 in a bell-curve distribution. In Fate Core, you add this 4dF roll to your skill level to get an outcome, and compare it to a target difficulty. If the final total meets or exceeds the difficulty, you succeed. (For example, if you have a skill of 3 and roll \+2 total on 4dF, your result is 5, which you compare to the target difficulty number.)

* **Dice Notation:** *4dF \+ skill vs. difficulty*

* **Formula:** `total = skill + Σ(4 Fudge dice)`; **Success** if `total ≥ difficulty`.

**Godot Code:** (Simulate 4dF by converting 1–6 rolls to \-1/0/+1)

 var rng \= RandomNumberGenerator.new()  
rng.randomize()  
var fudge\_result \= 0  
for i in range(4):           \# roll 4 Fudge dice  
    var d6 \= rng.randi\_range(1, 6\)  
    var face \= 0             \# convert d6 to fudge face value  
    if d6 \<= 2: face \= \-1    \# 1-2 \-\> \-1  
    elif d6 \<= 4: face \= 0   \# 3-4 \-\>  0  
    else: face \= 1           \# 5-6 \-\> \+1  
    fudge\_result \+= face  
var total \= skill\_level \+ fudge\_result  
var success \= total \>= difficulty

* 

## **Savage Worlds (Exploding Dice System)**

**Core Mechanic:** *Savage Worlds* uses variable-sized dice for skills and attributes and features **exploding dice** (called “acing”). Each trait is assigned a die type (d4, d6, d8, d10, or d12). To make a check, you roll the trait’s die; if you are a “Wild Card” (e.g., a player character), you also roll a d6 (Wild Die) and take the higher of the two rolls. The target number for most tasks is 4\. If the roll is 4 or higher, you succeed, with each additional 4 points indicating a raise (extra success level). Importantly, if you roll the maximum value on a die, it **explodes**: you roll that die again and add the result. This can repeat as long as you keep rolling the max value, allowing very high totals.

* **Dice Notation:** *1d{skill} (+1d6*) vs. TN 4, explode max\* *(Wild Die is d6, for Wild Cards)*

* **Formula:** `result = max( skill_die_rolls, wild_d6_rolls )`; each die roll *explodes* on max (roll again and add). **Success** if `result ≥ 4` (with 4+ increments as raises).

**Godot Code:** (Roll trait die with explosion, plus Wild Die)

 func roll\_exploding(die\_sides: int) \-\> int:  
    var rng \= RandomNumberGenerator.new()  
    rng.randomize()  
    var total \= 0  
    var roll \= rng.randi\_range(1, die\_sides)  
    total \+= roll  
    while roll \== die\_sides:           \# explode on max value  
        roll \= rng.randi\_range(1, die\_sides)  
        total \+= roll  
    return total

var trait\_result \= roll\_exploding(trait\_die\_sides)   
var wild\_result \= roll\_exploding(6)          \# Wild Die (d6) for Wild Card characters  
var result \= max(trait\_result, wild\_result)  \# take the higher result  
var success \= result \>= 4  
var raises \= (result \- 4\) / 4   \# number of raises, if needed

* 

## **Powered by the Apocalypse (2d6 System)**

**Core Mechanic:** *Powered by the Apocalypse* (PbtA) games, such as *Apocalypse World* and *Dungeon World*, use a **2d6 \+ modifier** mechanic with three tiers of outcomes. The player rolls two six-sided dice and adds a relevant stat modifier. If the total is 10 or higher, it’s a full success; on 7–9, the result is a partial or mixed success; and on 6 or below, it’s a failure (often with a narrative complication). This system emphasizes narrative outcomes (success with complications vs. outright failure) based solely on the dice total range.

* **Dice Notation:** *2d6 \+ modifier (results in 3 outcome tiers)*

* **Formula:** `total = d6 + d6 + modifier`; **Outcomes:** `total ≥ 10` ⇒ full success, `7–9` ⇒ partial success, `< 7` ⇒ failure.

**Godot Code:** (Roll 2d6 and evaluate outcome tier)

 var rng \= RandomNumberGenerator.new()  
rng.randomize()  
var total \= rng.randi\_range(1, 6\) \+ rng.randi\_range(1, 6\) \+ modifier  
var outcome: String \= ""  
if total \>= 10:  
    outcome \= "full\_success"  
elif total \>= 7:  
    outcome \= "partial\_success"  
else:  
    outcome \= "failure"

* 

## **Modiphius 2d20 System**

**Core Mechanic:** The *2d20 System* (used in *Star Trek Adventures, Conan, Dune RPG*, etc.) is a **dice pool of d20s with roll-under** mechanics. By default, a character rolls 2d20 for a task (additional d20s can be added by spending resources). Each d20 is compared to a target number (typically the sum of an Attribute \+ Skill in that game). Each die that rolls *under* the target number counts as one success. Higher difficulties require 2+ successes. If the number of successes rolled meets or exceeds the difficulty, the action succeeds. A roll of 1 on a d20 counts as two successes (critical success), and a roll of 20 can cause a complication (akin to a critical failure).

* **Dice Notation:** *Nd20 vs. target (count successes, roll-under)*

* **Formula:** `successes = count_{i=1..N}(d20_i ≤ target_number)`; **Success** if `successes ≥ difficulty`.

**Godot Code:** (Roll N d20s and count successes)

 var rng \= RandomNumberGenerator.new()  
rng.randomize()  
var successes \= 0  
for i in range(num\_d20s):  
    var roll \= rng.randi\_range(1, 20\)  
    if roll \<= target\_number:  
        successes \+= (roll \== 1 ? 2 : 1\)   \# count 1 as two successes  
    if roll \== 20:  
        \# note: handle complication (e.g., flag it)   
        pass  
var success \= successes \>= difficulty\_threshold

* 

## **Toward a Unified Dice Engine Abstraction**

Despite their differences, all these mechanics can be represented with a common abstraction to build a universal dice engine. Key parameters include:

* **Dice Pool Definition:** The number of dice and type of each die to roll (e.g. 1d20, 3d6, 4dF). This can include special die face distributions (Fate’s ±1/0 or even custom symbol dice).

* **Roll Outcome Calculation:** How to combine or interpret the dice results:

  * **Sum:** Add all dice (e.g. D\&D, GURPS sum their dice).

  * **Highest/Lowest:** Take the highest or lowest die (some systems or advantage/disadvantage mechanics).

  * **Count Successes:** Count how many dice meet a condition (e.g. ≥5 on d6 for Shadowrun, ≤ target on d20 for Modiphius).

  * **Success Thresholds:** A target number either for the sum or per-die. For example, D\&D’s target applies to the sum, whereas WoD/Shadowrun have a per-die threshold.

* **Comparison Rule:** Determine success by comparing the outcome to a target:

  * Roll-high vs target (≥ target is success) or roll-low (≤ target is success).

  * Or for dice pools, compare count of successes to required number.

* **Degrees of Success:** Optional rules for how far above or below the target the roll is (critical success, raises, partial success ranges, etc.).

* **Explosions/Re-rolls:** Whether dice explode on max (Savage Worlds), or allow re-rolls (some open-ended d100 systems).

* **Modifiers:** Flat bonuses or penalties to add to the roll total (as in d20 systems).

* **Special Cases:** e.g. Fate dice with non-numeric faces, or critical success/failure triggers.

By capturing each system’s rules in a configuration (dice pool \+ success criteria), a single engine can simulate any of them. For example:

* *D\&D 5e:* One d20, roll-high, success if ≥ DC.

* *WoD:* N d10, count successes (die ≥ threshold 6), success if count ≥ 1\.

* *Shadowrun:* N d6, count hits (die ≥5), success if hits ≥ threshold.

* *Fate:* 4 dice with values {–1,0,+1}, sum \+ skill, roll-high vs difficulty.

* *PbtA:* 2d6 \+ mod, evaluate range (≥10, 7–9, \<7).

* *Percentile:* 1d100, roll-low vs skill%.

* *2d20:* N d20, count successes (die ≤ target), roll-under vs difficulty count.

* etc.

A universal dice engine could define a structure or DSL (domain-specific language) for these parameters (for instance, an object or string like `"pool: NdX, rule: count>=Y@threshold, target: Z"` to mean “roll N dX, count results ≥ Y, success if count ≥ Z”). It could also support drawing cards or other random elements as needed.

Using such an abstraction, developers can **adapt to any RPG system’s dice mechanic** by plugging in the appropriate parameters without rewriting the core logic. The engine executes the roll, interprets successes/failures according to the configured rule, and returns the outcome. This approach covers everything from simple d20 checks to complex dice pool evaluations within one unified framework.

## **Addendum: Percentile Systems & Dice-Card Hybrids**

**Percentile-Based Systems:** Beyond *Call of Cthulhu*, many RPGs use d100 roll-under mechanics. For example, Warhammer Fantasy Roleplay and *Dark Heresy* (Warhammer 40k RPG) use percentile skills — roll 1d100 and succeed if the result is under your skill or characteristic. These systems often incorporate degrees of success by how much you roll under the target. Since percentile dice effectively give a 0–99 (or 1–100) range, they offer a fine-grained probability scale. In a unified engine, a percentile system is just a special case of **roll-under with a 100-sided die**.

**Dice \+ Card Hybrid Systems:** A few games mix card draws with dice rolls as part of their mechanics. For example, the classic *Deadlands* RPG uses standard playing cards for certain mechanics (like drawing poker hands for spellcasting effects) alongside dice rolls for skill checks. Its successor *Savage Worlds* retains cards solely for initiative order, while resolution is dice-based. Another example is *Torg* (and *Torg Eternity*), where players roll a d20 for action resolution but also play cards from a Drama Deck to influence the narrative. In a universal dice engine, such hybrids can be handled by incorporating a **card draw module** alongside dice rollers. A card draw can be abstracted as “draw a random value from a finite deck” – for instance, drawing from a standard 52-card deck can be simulated by generating a random number 1–52 or picking from a list of remaining cards. By treating cards as another form of random number generator (with optional deck memory and shuffling), the engine can accommodate systems that require both dice and cards.

# Godot Dice Physics Libraries (Open Source)

1. **godot-dice-roller** (vokimon)  
   AGPLv3 Godot UI control for 3D physics–based dice rolling, with configurable dice types, materials, and rolling methods.  
   [https://github.com/vokimon/godot-dice-roller](https://github.com/vokimon/godot-dice-roller) :contentReference\[oaicite:0\]{index=0}  
     
2. **Dice\_Roll** (Rebelion-Board-game)  
   MIT-licensed Godot 4 plugin using the Jolt physics engine to simulate interactive dice rolls in a configurable box.  
   [https://github.com/Rebelion-Board-game/Dice\_Roll](https://github.com/Rebelion-Board-game/Dice_Roll) :contentReference\[oaicite:1\]{index=1}  
     
3. **godot\_dice\_demo\_3d** (TommyUnreal)  
   GDScript demo showcasing 3D physics–based six-sided dice rolling, with seed based on mouse-drag vector.  
   [https://github.com/TommyUnreal/godot\_dice\_demo\_3d](https://github.com/TommyUnreal/godot_dice_demo_3d) :contentReference\[oaicite:2\]{index=2}  
     
4. **OptiDice** (A31Nesta)  
   Godot 4.3 project for 3D physics–driven dice rolling (Wear OS), leveraging accelerometer/gyroscope input.  
   [https://github.com/A31Nesta/OptiDice](https://github.com/A31Nesta/OptiDice) :contentReference\[oaicite:3\]{index=3}
