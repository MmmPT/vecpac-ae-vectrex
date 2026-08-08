# Jetpac — behaviour specification

Extracted from Michael R. Cook's annotated disassembly (`jetpac-disassembly/jetpac.skool`,
16K cartridge ROM, 1983, Ultimate Play the Game).

This document describes **what the game does**, in neutral language, to serve as the basis
for the Vectrex port. It contains no Z80 code. Every hexadecimal value comes from the ROM;
the decimals in parentheses are our own conversions.

The original's coordinate system: X from 0 to 255 left to right, Y from 0 to 191
**top to bottom** (Y=0 is the top of the screen). The play area runs from Y=$28 (40) to
Y=$B7 (183); above that sits the score bar.

---

## 1. The architecture we have to settle first

This constrains everything else, so it comes before the constants.

Jetpac **does not run at a fixed frame rate**. The object table is a uniform list of 8-byte
records from $5D00 to $5D87, and the main loop walks it dispatching each object to one of
18 routines according to the first byte of the record (the "type"):

| Type | Routine | Type | Routine |
|-----:|---------|-----:|---------|
| $00 | Speed limiter | $09 | Rocket on the pad |
| $01 | Jetman flying | $0A | Rocket lifting off |
| $02 | Jetman walking | $0B | Rocket landing |
| $03 | Meteor | $0C | Sound: enemy death |
| $04 | Pick up module/fuel | $0D | Sound: player death |
| $05 | Cross ship | $0E | Check collectible picked up |
| $06 | Sphere alien | $0F | UFO |
| $07 | Fighter | $10 | Animate laser beam |
| $08 | Animate explosion | $11 | Squidgy alien |

**Type $00 is a wait loop of 192 iterations.** That is: every *empty* object slot burns a
fixed delay. The game regulates itself — few aliens on screen means many empty slots and
therefore a lot of delay; a full screen means little delay and faster action. Jetpac's
noticeable speeding-up as the screen fills **is a consequence of this structure**, not a
difficulty rule.

**The decision we have to make for the Vectrex:** if we run everything at a fixed 50 Hz
with `Wait_Recal`, we lose that acceleration and the game ends up with a different rhythm
from the original. The options are to reproduce the effect (scale object speed with the
number of free slots) or to take constant pacing as a design decision. On the Vectrex there
is a strong argument for constant pacing: drawing time already varies with the number of
vectors on screen, so we will get *some* variation for free — but in the opposite direction
(more objects = slower frame). I suggest measuring first and deciding afterwards.

Layered on top of this loop there is a 50 Hz clock: when a new interrupt arrives, the loop
restarts from the jetman and walks jetman → 4 lasers → explosion sound → rocket, and only
then continues through the remaining objects (module, collectible, animation, 6 aliens). In
practice the jetman and the lasers are updated once per 50 Hz frame; the aliens are updated
in whatever time is left.

---

## 2. Scenery

Four platforms. Each has a **centre** position and a **half-width** in pixels:

| Platform | X centre | Y | Half-width | Extent in X |
|---|---:|---:|---:|---|
| Ground | 120 | 184 | 136 | −16 to 256 (the whole screen) |
| Middle | 128 | 96 | 27 | 101 to 155 |
| Left | 48 | 72 | 35 | 13 to 83 |
| Right | 208 | 48 | 35 | 173 to 243 |

Collision detection is **positional, not graphical**: even if a platform is not drawn, it
collides just the same. This makes life easier for us — on the Vectrex we can draw the
platforms however we like without affecting play.

Collision result, by bits:

- **top hit** → landed on it
- **bottom hit** → bumped his head
- **hit** → there was contact
- **redraw** / **left the platform** → used by the walking logic

The sprite width used in the horizontal comparison is 18 px; the height comes from byte 7
of the object record (jetman: $24 = 36; aliens: $1C = 28; items: $18 = 24).

---

## 3. Jetman

Starting position: X=$80 (128), Y=$B7 (183) — on top of the ground, at the centre.
Sprite height: 36 px.

### 3.1 Movement — representation

Position and speed use **8.8 fixed point**. The high byte is the position in pixels; the
low byte is a remainder accumulator (there is one accumulator for X and another for Y).
Each update:

```
accumulator_16bits = (position << 8) | remainder
accumulator_16bits ±= speed * 8
position = high byte,  remainder = low byte
```

That is, the actual displacement is **speed / 32 pixels per update**.

### 3.2 Physics constants

| Quantity | Value | In pixels/update |
|---|---:|---|
| Horizontal acceleration (thrust) | +8 | — |
| Horizontal braking (no input, or reversing) | −8 | — |
| Top horizontal speed while flying | $40 (64) | 2.00 |
| Horizontal speed while walking | $20 (32) | 1 px directly (see 3.4) |
| Vertical acceleration (thrust, rising) | +8 | — |
| **Gravity** (thrust released) | +8 | — |
| Top vertical speed | $3F (63) | 1.97 |

The most important detail: **gravity and thrust have exactly the same magnitude (8 units
per update).** The Jetman is not a rocket fighting a heavy planet — he is perfectly
symmetric. That is why the control feels so precise and why holding a hover is so easy.

When the speed crosses zero on reversing direction, it is pinned to zero and the direction
bit is flipped in that same update (there is no passing through negative speeds).

### 3.3 Vertical limits

- Y ≥ $C0 (192): starts moving upward.
- Y < $2A (42): reached the top — starts descending **and the vertical speed is halved**.
  It is not a hard wall; it is a soft brake.

### 3.4 Walking

Walking does not use fixed point: the X position is incremented or decremented **1 pixel
per update**, directly. The speed is written as $20 but has no observable effect (the
author of the disassembly notes himself that changing that value changes nothing).

- **Landing**: state becomes "walking", X and Y speeds set to zero.
- **Leaving the platform** (walking off the edge, or pressing thrust): state becomes
  "flying", Y −= 2, and the thruster smoke animation starts.

### 3.5 The undocumented hover key

Before reading the keyboard, the code pauses briefly to give gravity time to act. Side
effect: if any key in the top two rows is held, the vertical speed is **set to zero** — the
Jetman hangs still in the air. The author of the disassembly describes it as "an
undocumented hover key". Whether we replicate this is a decision: I would say no, but it is
part of the game's folklore and the Vectrex has buttons to spare.

### 3.6 Laser

- At most **4 beams** at once.
- Rate limited to **one shot every 4 frames** of 50 Hz (~12 per second).
- Leaves at the jetman's Y minus 13 (the middle of the sprite), aligned to 8 px boundaries.
- Beam length: random, between $84 and $BC.
- Colour: chosen at random between white, magenta (×2) and cyan — irrelevant for us, but it
  says the beam should **shimmer**, and that we can reproduce with vector brightness.
- Each beam is made of **4 travelling pulses**, not a continuous line.

---

## 4. Aliens

Six slots. An 8-byte record: type, X, Y, colour, direction/movement, X speed, Y speed,
height (28 px).

### 4.1 Which alien appears on which level

The type is chosen from a table indexed by `level MOD 8`:

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|
| Alien | Meteor | Squidgy | Sphere | Fighter | UFO | Cross ship | Meteor | UFO |

From level 9 on the cycle repeats.

### 4.2 Spawning rules

Checked on every pass of the object loop:

- The jetman has to be flying or walking (not during explosions nor in the initial delay).
- **Fewer than 3 aliens on screen** → one spawns immediately.
- **3 to 5 aliens** → one spawns with probability **1 in 32**.
- **6 aliens** → none spawns.

On spawning: random Y between 40 and 167, side (left/right) from bit 6 of the game timer,
initial X speed 4.

### 4.3 Behaviour of each type

**Meteor** — the simplest one and the first the player meets. Moves in a straight line
adding the X speed and the Y speed to the position. Dies on touching a platform. Does not
chase.

**Squidgy alien** — moves ±2 px in X and ±2 px in Y per step. On hitting the top or the
bottom of a platform it reverses vertically; on hitting the end of a platform it reverses
horizontally. On reaching Y=$24 (36) it starts descending. Predictable, ricocheting
movement.

**Sphere alien** — normally moves only horizontally (±2 px). But on every step, with
probability **1 in 16**, it enters vertical mode: it picks a random duration (game timer,
between 16 and 47 steps), picks up or down at random, and goes down or up ±2 px for that
duration before returning to horizontal. This gives a hopping movement.

**Cross ship** — like the squidgy, but with two differences: on hitting the end of a
platform the direction is **reversed with an XOR** rather than simply copied, which makes
the change of direction erratic; and the vertical speed **accelerates** while rising
(incremented every step) and **decelerates** while falling. On switching to upward, the
vertical speed is reset to a random value + 8. Result: an undulating, unpredictable
movement.

**UFO — this is the chaser.** It compares its X and Y with the jetman's and moves towards
him. The speed is accelerated up to a maximum of 15 while closing and decelerated once it
passes. The speed-to-displacement conversion is `speed × 16` in fixed point (so up to ~1 px
per step, but with smooth acceleration and braking). On hitting the end of a platform the
direction is reversed with an XOR, which stops it chasing in a straight line — it chases,
but with swerves. It is the alien that forces the player to move.

**Fighter** — alternates between two states. Idle (waiting), it checks each step with
probability **1 in 32** whether to attack; it attacks immediately if the jetman is exactly
12 px below it. On attacking, it picks a random "charge duration" between $20 and $9F steps
and crosses the screen horizontally at 4 px per step, adjusting Y ±2 px to chase the
jetman's height. It dies when the charge ends, on touching a platform, on passing the top
of the screen, or on being shot.

### 4.4 Scoring

| Target | Points |
|---|---:|
| Squidgy alien | 80 |
| Cross ship | 60 |
| Fighter | 55 |
| UFO | 50 |
| Sphere alien | 40 |
| Meteor | 25 |
| Picking up a rocket module or a fuel cell | 100 |
| Picking up a collectible (gold, diamond, etc.) | 250 |

**An alien killed by colliding with the jetman scores nothing at all** — only laser kills
count. The player loses a life just the same.

---

## 5. Rocket and items

### 5.1 Assembly

The rocket stands at X=$A8 (168) on the ground, Y=$B7 (183). At the start of each level
only the bottom module is assembled; the other two are scattered around the scenery:

- Top module: X=$30 (48), Y=$47 (71)
- Middle module: X=$80 (128), Y=$5F (95)

The player picks up a module by touching it (+100 points), carries it **hanging from his
feet** (the module's position now follows the jetman's), and drops it when he is within
6 px in X of the rocket — at which point the module lines up with the rocket and comes down
on its own until it docks. A carried module only docks once its Y has passed 183.

### 5.2 Fuel

Once the 3 modules are assembled, fuel cells appear.

- They are generated with probability **1 in 16** per step, and only if fewer than 6 have
  been collected and there is no cell already on screen.
- Each cell is worth 100 points when picked up.
- The cell is delivered on reaching Y=$B0 (176) beside the rocket.
- **Six cells are needed.** On the sixth, the rocket lifts off.

While the fuel is loaded, the rocket is painted magenta from the base upward in proportion
to the cells delivered — visual feedback of the progress. On the Vectrex this has to be
solved some other way: rising brightness, or segments of the rocket that fill in.

### 5.3 Lift-off, landing and lives

- On completing the 6 cells: **the player gains a life** and the rocket starts to climb.
- The rocket rises 1 px per step to Y=$28 (40), at which point the level ends, the level
  counter increments and everything is reset.
- On the next level the rocket **descends** 1 px per step to Y=$B7 (183) and lands.
- The player controls the jetman during the climb and the descent (the phase of flying with
  the rocket assembled is playable).
- The rocket's drawing changes **every 4 levels**, with 4 different models → a 16-level
  cycle.

### 5.4 Collectibles

- Generated with probability **1 in 128** per step, one at a time, in columns chosen from a
  table of 16 fixed positions: 8, 32, 40, 48, 56, 64, 88, 96, 120, 128, 136, 192, 224, 8,
  88, 96.
- The type changes every 2 levels, with 4 types → an 8-level cycle.
- They are worth 250 points and fall until picked up.

**Important note for the port:** on the Spectrum the four collectibles are told apart
mainly **by colour** — gold bar (golden), plutonium (green), chemical (cyan flashing
against black) and a fourth of random colour. The Vectrex has no colour. The four
collectibles will have to be told apart **by shape**, and that is design work the original
does not do for us. The flashing item can keep flashing — that translates well.

---

## 6. Game structure

- **Lives**: the player starts with 4 lives in reserve (5 in total, counting the one in
  play). One life is gained for every rocket launched, with no known limit.
- In a 2-player game, the second player is initialised with 5 in reserve instead of 4. It
  is an asymmetry that really is in the ROM; it is worth confirming in the emulator whether
  it translates into a visible extra life or is compensated somewhere else.
- **End of a turn**: all objects are deactivated, the module and the collectible in
  progress are released, and the level is reinitialised. Progress on assembling the rocket
  **carries over** between lives.
- **Game over** when the current player runs out of lives in reserve.
- Score in BCD, 4 digits per player, plus the high score.

---

## 7. Randomness

The original's random number generator reads bytes from the Spectrum ROM and adds the
memory refresh register — none of which exists on the Vectrex. We need a generator of our
own (an 8-bit LFSR does the job). What matters is preserving the **probabilities**, all
powers of 2, all easy to reproduce: 1/16, 1/32, 1/128.

There is also a 16-bit game timer that increments with every object drawn and is used as a
cheap source of pseudo-randomness in several places (the side aliens spawn from, charge
durations, item flashing). An equivalent counter does the job.

---

## 8. What this document does not cover

- **Graphics.** Every `gfx_*` in the ROM is an 8 px wide bitmap. They have to be redrawn
  from scratch as vector lists. That is design work, not translation.
- **Sound.** The original is a 1-bit speaker. The Vectrex has an AY-3-8912 with 3 channels
  — we can do better than the original instead of imitating it.
- **Menu screen, high score table, loading screen.** Simple structures, to be dealt with
  when we get there.
- Absolute timings in seconds. Everything here is in "steps" and "frames"; converting to
  real time depends on the decision in section 1.
