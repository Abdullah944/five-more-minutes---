# Five More Minutes! - Game Design Document

> **Genre:** Cozy-Comedy Roguelike Survivor
> **Platform:** Android / iOS
> **Engine:** Godot 4.6 (Mobile Renderer)
> **Perspective:** 2D Top-Down
> **Core Fantasy:** *"Protect your sleep at all costs."*

---

## Table of Contents

1. [Design Pillars](#1-design-pillars)
2. [Core Gameplay Loop](#2-core-gameplay-loop)
3. [Sleep Meter — The Central Mechanic](#3-sleep-meter--the-central-mechanic)
4. [Abilities & Weapons](#4-abilities--weapons)
5. [Enemy Design](#5-enemy-design)
6. [Wave & Difficulty Curve](#6-wave--difficulty-curve)
7. [In-Run Upgrade System](#7-in-run-upgrade-system)
8. [Meta Progression System](#8-meta-progression-system)
9. [Retention & Live-Ops Mechanics](#9-retention--live-ops-mechanics)
10. [UI/UX Design](#10-uiux-design)
11. [Juice & Game Feel](#11-juice--game-feel)
12. [Monetization Philosophy](#12-monetization-philosophy)
13. [Competitive Differentiation](#13-competitive-differentiation)
14. [Technical Architecture (Godot 4.6)](#14-technical-architecture-godot-46)

---

## 1. Design Pillars

| Pillar | What It Means |
|---|---|
| **Cozy Aggression** | Combat is constant but never stressful. The world is soft, the violence is silly, and losing feels like a gentle nudge, not a punishment. |
| **One More Run** | Every run must teach the player something new or give them something to chase. The meta loop should make quitting feel wasteful. |
| **Thumb-Friendly** | The entire game must be playable with one thumb in portrait mode on a bus. Zero precision required. |
| **Visual Storytelling** | Upgrades, power, and progression must be *visible*. The bed gets bigger. The snore gets louder. The room fills with plushies. The player should *see* their power fantasy. |

---

## 2. Core Gameplay Loop

### Micro Loop (In-Run, ~5-second cycle)

```
Enemies approach → Auto-abilities fire → Enemies fall asleep
→ Drop Sleep Energy → Player levels up → Choose upgrade → Repeat
```

### Meso Loop (Single Run, 5–20 minutes)

```
Start in bed → Survive escalating waves → Level up 15-30 times
→ Face mini-bosses → Hit a wall → Game over → See results
```

### Macro Loop (Session-to-Session)

```
Complete run → Earn Dream Shards → Spend on permanent upgrades
→ Unlock new beds/pajamas/themes → Start stronger → Push further → Repeat
```

### Run Structure

A single run is divided into **Nights** (acts), each lasting ~3 minutes of real time.

| Night | Time | Theme | Event |
|---|---|---|---|
| 1: Light Sleep | 0:00–3:00 | Quiet bedroom, few enemies | Tutorial-safe ramp |
| 2: Deep Sleep | 3:00–6:00 | Dreamscape shifts, new enemy types | First mini-boss at 5:00 |
| 3: REM Phase | 6:00–10:00 | Surreal visuals, dense spawns | Ability synergies matter |
| 4: Lucid Dream | 10:00–15:00 | Player powers peak, elite enemies | Second mini-boss at 12:00 |
| 5: The Alarm | 15:00+ | Infinite escalation | Boss every 5 minutes, survival-only |

Reaching Night 3 on your first few runs should feel like an achievement. Night 5 is endgame territory for upgraded players.

---

## 3. Sleep Meter — The Central Mechanic

The **Sleep Meter** is the player's "health bar," but it works in reverse: it starts empty (deep sleep) and fills up as the player takes damage. Full meter = fully awake = game over.

### Sleep Depth Zones

The meter is divided into **4 zones** that fundamentally change gameplay:

| Zone | Meter Range | State | Effect |
|---|---|---|---|
| **Deep Sleep** | 0–25% | Strongest | +30% ability damage, +20% AoE radius, screen has a dreamy vignette |
| **Light Sleep** | 26–50% | Normal | Baseline stats, no modifiers |
| **Restless** | 51–75% | Weakened | -15% damage, enemies move 10% faster, screen edges flicker |
| **Almost Awake** | 76–100% | Critical | -30% damage, screen desaturates, heartbeat audio cue, but pickup radius doubles (comeback mechanic) |

### Key Design Decisions

- **Damage is the resource, not just a punishment.** Being at Deep Sleep makes you powerful, creating a risk/reward dynamic: do you play aggressively to stay in Deep Sleep, or do you play safe and accept weaker stats?
- **Natural regeneration is slow** (~1% per 5 seconds base), making regen upgrades highly valuable.
- **"Warm Milk" pickups** (rare drops) instantly reduce the meter by 15%.
- **The "Almost Awake" zone doubles pickup radius** — this is a deliberate comeback mechanic that lets struggling players vacuum up XP to trigger a level-up and pick a survival upgrade.

### Sleep Meter Interactions

- **Snooze Button (Active Ability):** Unlockable. Once per run, slam the snooze button to freeze the Sleep Meter for 8 seconds and release a massive shockwave. Cooldown: 180 seconds. Upgradeable to 2 charges.
- **Caffeine Enemies:** Special enemies that, on hit, temporarily *lock* the meter (it can't decrease for 5 seconds). Forces the player to reposition.

---

## 4. Abilities & Weapons

All abilities auto-fire. The player's only input is movement (dragging the bed around). Abilities are gained through level-up choices and stack with duplicates.

### Starting Abilities (Unlockable, pick 1 before run)

| Ability | Type | Behavior | Unlock |
|---|---|---|---|
| **Snore Wave** | AoE Pulse | Expanding ring of "ZZZ" from the bed every 2s. Damages all enemies in radius. | Default starter |
| **Pillow Toss** | Projectile | Fires a pillow at the nearest enemy every 1.5s. Bounces once. | 500 Dream Shards |
| **Dream Beam** | Beam | Continuous beam that sweeps in a slow arc. High single-target DPS. | 1,200 Dream Shards |

### Discoverable Abilities (Found during runs)

| Ability | Type | Behavior | Stack Bonus |
|---|---|---|---|
| **Lullaby Shockwave** | AoE Burst | On level-up, releases a massive lullaby pulse that puts all on-screen enemies to sleep for 3s. | +1s sleep duration per stack |
| **Orbiting Plushies** | Orbital | 1 plushie orbits the bed, damaging enemies on contact. | +1 plushie per stack (max 8) |
| **Counting Sheep** | Summon | Spawns a sheep that wanders and headbutts enemies. | +1 sheep per stack (max 5) |
| **Blanket Fort** | Zone | Creates a static damage zone around the bed. Enemies inside take ticking damage. | +25% radius per stack |
| **Sleep Talk** | Random | Fires random word bubbles in random directions. High damage, unpredictable. | +2 projectiles per stack |
| **Night Light** | Aura | Passive aura that slows enemies within range by 20%. | +10% slow per stack |
| **Dream Catcher** | Passive | Defeated enemies have a 15% chance to drop a Warm Milk pickup. | +5% chance per stack |
| **Midnight Snack** | Regen | Every 30 defeated enemies, reduce Sleep Meter by 5%. | +2% per stack |

### Ability Evolution System

When two specific abilities reach stack level 3+, they can **merge** into an evolved form at the next level-up (presented as a special 4th choice):

| Combo | Evolution | Effect |
|---|---|---|
| Snore Wave + Night Light | **Sleep Paralysis Field** | Permanent slowing aura that also pulses damage. Enemies at the edge are frozen for 1s. |
| Pillow Toss + Counting Sheep | **Pillow Cavalry** | Sheep carry pillows and throw them at enemies while charging. |
| Dream Beam + Sleep Talk | **Lucid Laser** | Controllable beam (auto-aims at densest cluster). Word bubbles orbit the beam. |
| Orbiting Plushies + Blanket Fort | **Fortress of Fluff** | Plushies orbit at blanket fort edge, fort pulses damage, plushies deal 3x on contact. |
| Lullaby Shockwave + Dream Catcher | **Sandman's Requiem** | Shockwave now triggers on every 25th kill. Sleeping enemies always drop Warm Milk. |

---

## 5. Enemy Design

Enemies don't "attack" in the traditional sense — they **make noise** or **cause disturbances** that fill the Sleep Meter. This keeps the tone cozy.

### Regular Enemies

| Enemy | Behavior | Disturbance | Visual |
|---|---|---|---|
| **Snoring Zombie** | Slow walk toward bed | Contact damage (ironic — their snoring wakes *you*) | Green, droopy-eyed, dragging one leg, "ZZZ" over head |
| **Alarm Clock** | Medium speed, beelines for bed | Rings loudly on contact (high meter damage) | Bouncing clock with angry eyebrows and little legs |
| **Barking Pup** | Fast, erratic zigzag pattern | Low damage but very fast, hard to hit | Tiny cartoon dog, tail wagging, tongue out |
| **Whispering Ghost** | Phases through other enemies, slow | Whispers fill meter gradually while in range (no contact needed) | Translucent blob with a "psst" speech bubble |
| **Mosquito Swarm** | Orbits the bed at medium range | Chip damage over time if not cleared | Cloud of tiny dots with cartoon eyes |
| **Noisy Neighbor** | Walks to a fixed spot, then stands still and makes noise | AoE meter fill in a radius around their position | Guy in bathrobe with a boombox |
| **Delivery Drone** | Flies in straight line, drops a package, leaves | Package becomes a stationary hazard (ringing doorbell) | Tiny quadcopter with a box |

### Elite Enemies (Spawn after Night 2)

| Elite | Behavior | Danger |
|---|---|---|
| **Espresso Golem** | Slow, tanky, leaves a caffeine trail that speeds up other enemies | Trail persists for 10s, area denial |
| **DJ Rooster** | Stands at screen edge, buffs all enemies with a "bass boost" (speed +25%) | Must be killed quickly or enemies overwhelm |
| **Thunder Cloud** | Floats overhead, periodically "strikes" a random spot near the bed | High burst meter damage, telegraphed with a shadow |

### Mini-Bosses (Scripted spawns)

| Boss | Night | Mechanic |
|---|---|---|
| **The Giant Alarm Clock** | 2 | Rings in pulses. Each ring spawns 4 mini alarm clocks. Must be damaged between rings. Sleep Meter fills 3% per ring. |
| **The Neighbor's Party** | 4 | A conga line of Noisy Neighbors that circles the bed, tightening the circle. Break the chain by killing any member. |
| **The Monday Morning** | 5+ | A massive sunrise creeping from one edge. Everything it touches gets +50% speed. Player must survive until it "sets" (90 seconds). |

### Boss Design Principles

- Bosses are **spectacles**, not skill checks. They should be visually impressive and narratively funny.
- Bosses always drop a **treasure chest** (guaranteed ability or evolution).
- Bosses have a **mercy timer** — if alive for 60s, they take 10% max HP/s.

---

## 6. Wave & Difficulty Curve

### Spawn System

Enemies spawn from offscreen in **waves** with brief breathing room between them. The system uses a **threat budget** that increases over time:

| Time | Threat Budget/s | Composition |
|---|---|---|
| 0:00–1:00 | 2 | Only Zombies (cost: 1 each) |
| 1:00–3:00 | 4 | Zombies + Alarm Clocks (cost: 2) |
| 3:00–5:00 | 7 | Add Pups (cost: 1.5) + Ghosts (cost: 3) |
| 5:00–8:00 | 12 | Add Mosquitoes + Neighbors, first Elites |
| 8:00–12:00 | 20 | Full enemy pool, Elite every 45s |
| 12:00–15:00 | 30 | Dense spawns, Elite every 30s |
| 15:00+ | 30 + 2/min | Infinite scaling, multiple Elites, periodic bosses |

### Breathing Room

Every 90 seconds, spawns pause for 4 seconds and a "lullaby chime" plays. This gives the player a moment to:
- Process the current state of their build
- Appreciate their power growth
- Take a real-world breath (important for mobile sessions)

### Difficulty Modifiers (Keep It Fresh)

Each run randomly selects 1–2 **Night Modifiers** after Night 2:

| Modifier | Effect |
|---|---|
| **Thunderstorm** | Screen periodically flashes (cosmetic), but enemies spawn from fewer directions (easier to manage) |
| **Sleepwalking** | The bed drifts slightly on its own; player must compensate |
| **Nightmare Bleed** | Enemies are 20% tougher but drop 30% more XP |
| **Counting Sheep** | A sheep runs across the screen every 10s; catching it reduces Sleep Meter by 5% |
| **Full Moon** | Ghost spawn rate triples, but all ghosts drop guaranteed pickups |

---

## 7. In-Run Upgrade System

### Level-Up Flow

1. Player collects enough Sleep Energy (XP) to level up.
2. **Time freezes.** Three cards slide up from the bottom.
3. Player picks one. Satisfying "tuck in" animation plays.
4. Time resumes with a brief 1-second slow-mo (the player sees their new power in action).

### Upgrade Categories

Every upgrade belongs to one of three categories, color-coded:

| Category | Color | Icon | Focus |
|---|---|---|---|
| **Sleep Strength** | Purple | Crescent Moon | Damage, projectile count, AoE size, crit chance |
| **Calmness** | Blue | Cloud | Sleep Meter regen, damage reduction, slow effects, shields |
| **Comfort** | Yellow | Star | Pickup radius, XP gain, movement speed, cooldown reduction |

### Upgrade Rarity

| Rarity | Border | Drop Weight | Power Level |
|---|---|---|---|
| **Common** | White | 60% | Small incremental boost |
| **Uncommon** | Green | 25% | Meaningful improvement |
| **Rare** | Purple | 12% | Build-defining upgrade |
| **Legendary** | Gold + shimmer | 3% | Dramatically changes playstyle |

### Example Upgrades (Per Category)

**Sleep Strength (Purple)**

| Name | Rarity | Effect | Stack |
|---|---|---|---|
| Heavy Sleeper | Common | +10% damage to all abilities | Additive, uncapped |
| Bigger Pillow | Common | +15% AoE radius | Additive, uncapped |
| R.E.M. Burst | Uncommon | Crit chance +8%. Crits emit a mini shockwave | Crit chance stacks |
| Nightmare Fuel | Rare | Abilities deal 2x damage to enemies below 50% HP | Threshold becomes 75% at stack 2 |
| Oversleep | Legendary | Every 5th attack deals 500% damage | 4th attack at stack 2 |

**Calmness (Blue)**

| Name | Rarity | Effect | Stack |
|---|---|---|---|
| Thick Blanket | Common | -5% incoming Sleep Meter damage | Additive to -30% cap |
| Slow Breathing | Common | +20% Sleep Meter regen rate | Additive, uncapped |
| Sleep Shield | Uncommon | Gain a shield that blocks the next hit, recharges every 20s | -3s recharge per stack |
| Memory Foam | Rare | When hit, release a knockback pulse that pushes enemies to screen edge | +30% force per stack |
| Hibernation | Legendary | Below 25% Sleep Meter, become immune to damage for 0.5s every 5s | +0.3s duration per stack |

**Comfort (Yellow)**

| Name | Rarity | Effect | Stack |
|---|---|---|---|
| Long Arms | Common | +20% pickup radius | Additive, uncapped |
| Speed Nap | Common | +8% bed movement speed | Additive to +50% cap |
| Restful Sleep | Uncommon | +15% XP from all sources | Additive, uncapped |
| Magnet Pillow | Rare | All pickups on screen slowly drift toward the player | Drift speed increases per stack |
| Lucid Dreamer | Legendary | See 4 upgrade choices instead of 3 | 5 choices at stack 2 (max) |

### Upgrade Selection UX

- Cards **tilt slightly** when hovered (touch-held).
- Holding a card for 0.5s shows a **tooltip** with detailed stats.
- Selecting a card plays a **"fluffing pillow"** animation.
- The category color **pulses on the bed** briefly after selection.
- If the player has been offered the same upgrade before, a small **stack counter** shows (e.g., "x3").

---

## 8. Meta Progression System

### Currency: Dream Shards

Earned at the end of every run based on:

| Source | Amount |
|---|---|
| Base (just for playing) | 10 |
| Per minute survived | 8 |
| Per 50 enemies defeated | 5 |
| Per mini-boss defeated | 25 |
| Reaching Night 3 | 20 |
| Reaching Night 5 | 50 |
| First run of the day | 2x multiplier |

Average run yields: **50–200 Dream Shards** (casual) up to **300–500** (skilled + upgraded).

### Permanent Upgrade Tree: The Bedroom

The meta progression is presented as a **bedroom** the player decorates and upgrades. Each piece of furniture represents a stat category.

**Furniture → Stat Mapping**

| Furniture | Stat | Levels | Cost Curve |
|---|---|---|---|
| **Mattress** | Max Sleep Meter buffer (+5% per level, enemies need to do more to wake you) | 10 | 50 → 500 |
| **Pillow** | Base damage (+3% per level) | 15 | 30 → 750 |
| **Blanket** | Damage reduction (+2% per level) | 10 | 40 → 400 |
| **Nightstand Lamp** | Pickup radius (+10% per level) | 8 | 30 → 300 |
| **Alarm Clock** (ironic) | XP gain (+5% per level) | 10 | 40 → 500 |
| **White Noise Machine** | Sleep Meter regen (+10% per level) | 10 | 60 → 600 |
| **Slippers** | Movement speed (+4% per level) | 8 | 30 → 250 |
| **Dream Journal** | Unlock an extra reroll per run (+1 per level) | 3 | 200 / 500 / 1000 |

The bedroom **visually upgrades** as the player invests. Level 1 mattress is a thin pad on the floor. Level 10 is a king-size cloud bed with floating pillows.

### Unlockable Beds

Beds are the "character select" of the game. Each bed changes the starting ability loadout and grants a unique passive.

| Bed | Unlock Condition | Starting Ability | Passive |
|---|---|---|---|
| **Standard Bed** | Default | Snore Wave | None |
| **Bunk Bed** | Survive 10 minutes | Pillow Toss | Pillows bounce +1 extra time |
| **Hammock** | Defeat 1,000 enemies total | Dream Beam | +15% movement speed, -10% HP |
| **Cloud Bed** | Reach Night 4 | Snore Wave | AoE abilities are 25% larger |
| **Race Car Bed** | Defeat 3 mini-bosses in one run | Pillow Toss | +30% movement speed, enemies drop XP on hit (not just on defeat) |
| **Royal Canopy** | Collect 5,000 Dream Shards total | Dream Beam | Start with a Sleep Shield |
| **Futon of Fury** | Survive 20 minutes | Random | Start with 2 abilities instead of 1 |
| **Waterbed** | Complete all daily missions for 7 days | Snore Wave | Leaving a position creates a ripple that damages enemies |

### Pajama Skins

Cosmetic with minor perks. Pajamas are visible on the character sprite tucked into bed.

| Pajama | Unlock | Perk |
|---|---|---|
| **Classic Stripes** | Default | None |
| **Onesie Bear** | 300 Shards | +5% Calmness upgrades appear more often |
| **Space Jammies** | 500 Shards | Dream Beam +10% range |
| **Fluffy Robe** | 800 Shards | +10% Sleep Meter regen |
| **Formal Suit PJs** | 1,200 Shards | +10% Dream Shards earned |
| **Invisible (just boxers)** | Survive Night 5 | -20% HP, +30% damage |

### Dream Themes (Visual Environments)

Each theme changes the tilemap, color palette, enemy skins, and ambient audio — but NOT gameplay balance.

| Theme | Unlock | Vibe |
|---|---|---|
| **Cozy Bedroom** | Default | Warm, lamplight, wood floor |
| **Cloud Dream** | Night 3 reached | Floating on clouds, pastel sky |
| **Nightmare Lite** | Night 5 reached | Purple/dark blue, silly "spooky" enemies, cobwebs made of yarn |
| **Candy Sleep** | 2,000 Shards | Candy-colored everything, enemies are gummy bears and licorice |
| **Underwater Nap** | Defeat "The Monday Morning" boss | Bubbles, kelp, fish enemies replace dogs |
| **Space Snooze** | 5,000 Shards total earned | Floating in zero-g, star field background, asteroid alarm clocks |

### Room Customization

Between runs, the player visits their **Bedroom Hub** — a small, scrollable room they can decorate.

- **Decorations** are earned from milestones, daily rewards, and the shard shop.
- Decorations are **purely cosmetic** but create emotional attachment.
- Categories: Wall Art, Rugs, Lamps, Plushies (shelf display), Window Views, Pet Companions.
- **Pet Companions** sit in the bedroom and have idle animations. They also appear in the run as tiny cheerleaders on the screen edge (cosmetic).

---

## 9. Retention & Live-Ops Mechanics

### Daily Reward Calendar (7-Day Cycle, Repeating)

| Day | Reward |
|---|---|
| 1 | 50 Dream Shards |
| 2 | Random Common Decoration |
| 3 | 75 Dream Shards |
| 4 | 1 Free Reroll Token |
| 5 | 100 Dream Shards |
| 6 | Random Uncommon Decoration |
| 7 | 200 Dream Shards + Pajama Crate (random unlock) |

Missing a day resets the streak. **But:** the player can "catch up" by watching an optional ad or spending 50 shards.

### Mission System

**Daily Missions** (3 per day, refresh at midnight local time):

| Example | Reward |
|---|---|
| Survive for 5 minutes | 30 Shards |
| Defeat 200 enemies | 25 Shards |
| Reach Night 2 without taking damage for 30s | 40 Shards |
| Use a Snooze Button ability | 20 Shards |
| Pick 3 Calmness upgrades in one run | 35 Shards |

**Weekly Missions** (3 per week):

| Example | Reward |
|---|---|
| Survive a total of 30 minutes | 150 Shards |
| Defeat 5 mini-bosses | 200 Shards |
| Evolve an ability | 100 Shards |
| Try 3 different beds | 120 Shards |

### Achievement Milestones

Long-term goals that reward unique unlocks:

| Achievement | Goal | Reward |
|---|---|---|
| Light Sleeper | Survive 5 minutes | Bunk Bed unlock |
| Dream Warrior | Defeat 10,000 enemies lifetime | "Hero Plushie" decoration |
| Insomniac | Play 50 total runs | Formal Suit PJs |
| Architect of Dreams | Buy 20 decorations | Expanded bedroom (more decoration slots) |
| Sheep Counter | Let 100 Counting Sheep cross the screen | Golden Sheep pet companion |
| Monday Survivor | Beat "The Monday Morning" 3 times | "Motivational Poster" wall art |

### Seasonal Content (Quarterly)

- **Limited-time Dream Themes** (e.g., "Holiday Nap" in December, "Spooky Sleep" in October).
- **Seasonal enemies** with unique drops.
- **Limited pajama skins** and decorations.
- Creates urgency without FOMO pressure (items return the following year).

---

## 10. UI/UX Design

### Screen Layout (Portrait Mode)

```
┌─────────────────────────────┐
│  [Sleep Meter — full width] │  ← Top: thin horizontal bar, fills left-to-right
│  [Wave: 12]    [Time: 4:32] │  ← Small, semi-transparent text
│                             │
│                             │
│                             │
│         ┌───────┐           │
│         │  BED  │           │  ← Center: the player, always visible
│         │ (hero)│           │
│         └───────┘           │
│                             │
│                             │
│                             │
│   [XP Bar — bottom third]   │  ← Thin bar, shows progress to next level
│                             │
│    ◉ Joystick zone          │  ← Invisible until touched. Appears where
│    (anywhere in             │    the player's thumb lands.
│     bottom half)            │
└─────────────────────────────┘
```

### Control Scheme: Floating Joystick

- **No fixed joystick position.** The joystick spawns wherever the player touches in the bottom 60% of the screen.
- This means left-handed and right-handed players are equally comfortable.
- Joystick has a **dead zone** of 15px to prevent jittery movement.
- Lifting the thumb stops all movement (the bed stays put).
- **Auto-aim is always on.** Abilities target enemies automatically.
- Optional: "Lazy Mode" in settings — bed auto-dodges the nearest enemy slowly. Pure idle play.

### HUD Elements

| Element | Position | Style |
|---|---|---|
| Sleep Meter | Top, full width | Gradient bar: blue (deep sleep) → red (almost awake). Pulses red when above 75%. |
| Wave Counter | Top-left | Small pill badge, updates with a pop animation |
| Timer | Top-right | Small text, counts up |
| XP Bar | Below gameplay area | Thin bar with a glowing fill. "Level X" text centered |
| Ability Icons | Left edge, vertical stack | Small circular icons of current abilities with cooldown sweeps |
| Snooze Button | Bottom-right | Large, satisfying button. Only visible when available. Bounces gently. |

### Level-Up Screen

```
┌─────────────────────────────┐
│                             │
│   ✨ LEVEL UP! ✨            │  ← Text with particle burst
│                             │
│  ┌────┐  ┌────┐  ┌────┐    │
│  │    │  │    │  │    │    │  ← Three cards, category-colored borders
│  │ Up │  │ Up │  │ Up │    │
│  │ 1  │  │ 2  │  │ 3  │    │
│  │    │  │    │  │    │    │
│  └────┘  └────┘  └────┘    │
│                             │
│  [🔄 Reroll (1 left)]      │  ← Small button, if rerolls available
│                             │
└─────────────────────────────┘
```

- Cards slide up from bottom with a stagger (left, center, right: 0ms, 80ms, 160ms).
- Tapping a card **zooms it to center**, the other two fade out, and a "pillow fluff" particle effect plays.
- If the player has a **reroll** available (from Dream Journal meta upgrade), a small button below the cards lets them redraw all three.

### Game Over Screen

```
┌─────────────────────────────┐
│                             │
│     😴 You Woke Up!         │
│     Time: 12:34             │
│     Enemies Defeated: 847   │
│     Night Reached: 4        │
│                             │
│  ┌──────────────────────┐   │
│  │ Dream Shards: +187   │   │  ← Shards count up with coin sounds
│  └──────────────────────┘   │
│                             │
│  ┌────────┐  ┌────────┐    │
│  │  Retry │  │  Home  │    │
│  └────────┘  └────────┘    │
│                             │
│  [▶ Watch ad for 2x shards] │  ← Optional, non-intrusive
│                             │
└─────────────────────────────┘
```

- The character sprite yawns and stretches in bed.
- Stats count up one-by-one with satisfying ticks.
- "New Best!" badge animates if any personal record is broken.

### Accessibility

- **Colorblind mode:** Upgrade categories use distinct shapes in addition to colors (moon, cloud, star).
- **Screen reader hints** on all interactive elements.
- **Haptic feedback** can be toggled off.
- **Text scaling** option (small/medium/large).
- **Reduced motion** option replaces particle effects with static indicators.

---

## 11. Juice & Game Feel

### Visual Juice

| Event | Effect |
|---|---|
| Enemy defeated | Enemy yawns, closes eyes, falls over with a soft "poof" of ZZZ particles. No blood, no explosions. |
| Snore Wave fires | Expanding translucent ring with "Z" letters riding the wave. Screen gently pulses outward. |
| Pillow hits enemy | Pillow squishes flat on impact with a bounce. Feathers fly out. |
| Level up | Screen flash (white, 100ms). All enemies freeze for 0.3s. Confetti of tiny moons and stars. |
| Upgrade selected | Bed briefly glows the category color. A "tucking in" sound plays. |
| Mini-boss appears | Brief zoom-out to show the boss entering. Comedic "dun dun DUN" jingle. |
| Sleep Meter critical | Edges of screen pulse red softly. Heartbeat audio (muffled, not scary). Clock ticking faintly. |
| Warm Milk pickup | Soothing "ahhh" sound. Screen edges briefly tint warm yellow. Meter smoothly decreases. |
| Game Over | Alarm clock ring (comedic). Character bolts upright, hair messy, eyes wide. Freeze frame. |

### Audio Design

| Layer | Description |
|---|---|
| **Ambient** | Soft lo-fi beats that dynamically layer based on intensity. Deep Sleep = minimal piano. Almost Awake = faster tempo, more instruments. |
| **SFX** | All muffled/dreamy. Pillow impacts sound like "fwump." Snore waves are a soft bass rumble. Enemy defeat is a tiny "zzz" chime. |
| **UI** | Tactile clicks, soft chimes. Upgrade selection = pillow fluff. Level up = music box sting. |
| **Boss Music** | Same lo-fi base but with a comedic dramatic overlay (kazoo horns, xylophone). |

### Screen Effects

- **Parallax background:** The bedroom has 3 layers (floor, walls, window). Subtle parallax on bed movement.
- **Vignette:** Increases as Sleep Meter fills (you're "opening your eyes").
- **Dream particles:** Floating, slow-moving translucent shapes (stars, moons, sheep) drift across the screen. More when in Deep Sleep, fewer when Almost Awake.
- **Ability stacking visuals:** The bed *physically changes* as you stack upgrades. Pillow Toss stacks add visible pillows. Orbiting Plushies are literally visible. Blanket Fort is a visible ring. The player should look at their bed at minute 12 and think "look at my ridiculous fortress."

### Haptics (Mobile)

| Event | Pattern |
|---|---|
| Enemy defeated | Soft single tap |
| Level up | Medium double tap |
| Upgrade selected | Satisfying thunk |
| Boss incoming | Long low rumble |
| Damage taken | Quick sharp buzz |
| Game over | Rising buzz pattern |

---

## 12. Monetization Philosophy

**Principle: The game must be fun and complete without spending money.** Monetization accelerates progression and adds cosmetic expression. No pay-to-win mechanics.

### Revenue Streams

| Stream | Implementation |
|---|---|
| **Rewarded Ads** | 2x Dream Shards after a run (optional). One free revive per day (watch ad to continue a run). Extra daily mission slot. |
| **Remove Ads IAP** | One-time purchase ($3.99). Removes all interstitial ads. Rewarded ads remain available (player's choice). Grants a permanent +10% Dream Shard bonus. |
| **Cosmetic Bundles** | Themed bundles (e.g., "Space Pack" = Space Snooze theme + Space Jammies + Rocket Plushie) for $1.99–$4.99. |
| **Season Pass** | Optional seasonal pass ($2.99/season). Free track gives shards and common items. Paid track gives exclusive pajamas, decorations, and a unique bed. No gameplay advantages over free track beyond cosmetics. |
| **Starter Pack** | One-time offer after first run: 500 Shards + Onesie Bear pajama + 3 Reroll Tokens for $0.99. High-value, low-friction. |

### What You Can NOT Buy

- Permanent stat upgrades (must be earned with Dream Shards from gameplay).
- Ability unlocks.
- Gameplay advantages of any kind that aren't available through normal play.

---

## 13. Competitive Differentiation

### Why "Five More Minutes!" Stands Out

| Differentiator | vs. Vampire Survivors | vs. Other Mobile Roguelikes |
|---|---|---|
| **Tone** | VS is gothic-horror. FMM is cozy-comedy. Untapped audience: casual/cozy gamers who find VS too intense. | Most mobile roguelikes use dark fantasy. Cozy + combat is a rare combination. |
| **Sleep Meter Depth System** | VS has no "inverse health = power" mechanic. FMM's system creates a unique risk/reward dynamic. | Most games punish low health. FMM rewards it. This creates memorable moments. |
| **Visual Progression** | VS abilities are mostly particle effects. FMM abilities *physically change the bed*. The visual comedy of a bed covered in 8 orbiting plushies, a blanket fort, and 5 sheep is inherently shareable. | Mobile games often have abstract UI for power. FMM makes power tangible and funny. |
| **Portrait Mode** | VS is landscape-only. FMM is portrait-first, designed for one-thumb play. | Many mobile ports are awkward in portrait. FMM is built for it from day one. |
| **Emotional Hook** | "Killing monsters" is power fantasy. "Protecting your sleep" is *relatable*. Everyone has fought their alarm clock. The memes write themselves. | Relatability drives organic sharing. "I just survived Monday Morning in bed" is a tweet that writes itself. |
| **Idle-Friendly** | VS requires constant movement. FMM has "Lazy Mode" for truly passive play. | Captures the idle-game audience that wants progression without stress. |

### Shareability Features

- **Screenshot mode:** Pause the game and take a screenshot of your ridiculous bed setup. Auto-watermarks with game logo.
- **Run summary cards:** Shareable card at game over showing stats, bed visual, and "I survived X minutes" — designed for social media.
- **Weekly challenge leaderboard:** Same modifiers for all players that week. Compare survival times with friends.

---

## 14. Technical Architecture (Godot 4.6)

### Project Structure

```
res://
├── scenes/
│   ├── main/
│   │   ├── game.tscn              # Main game scene
│   │   ├── bedroom_hub.tscn       # Meta progression hub
│   │   └── main_menu.tscn
│   ├── player/
│   │   ├── bed.tscn               # Player (bed + character)
│   │   └── bed.gd
│   ├── enemies/
│   │   ├── base_enemy.tscn        # Base enemy with shared logic
│   │   ├── base_enemy.gd
│   │   ├── zombie.tscn            # Inherits base_enemy
│   │   ├── alarm_clock.tscn
│   │   ├── barking_pup.tscn
│   │   ├── ghost.tscn
│   │   └── bosses/
│   │       ├── giant_alarm.tscn
│   │       ├── neighbor_party.tscn
│   │       └── monday_morning.tscn
│   ├── abilities/
│   │   ├── base_ability.tscn
│   │   ├── base_ability.gd
│   │   ├── snore_wave.tscn
│   │   ├── pillow_toss.tscn
│   │   ├── dream_beam.tscn
│   │   ├── lullaby_shockwave.tscn
│   │   ├── orbiting_plushies.tscn
│   │   ├── counting_sheep.tscn
│   │   ├── blanket_fort.tscn
│   │   ├── sleep_talk.tscn
│   │   ├── night_light.tscn
│   │   ├── dream_catcher.tscn
│   │   └── midnight_snack.tscn
│   ├── pickups/
│   │   ├── sleep_energy.tscn       # XP gem
│   │   └── warm_milk.tscn          # Health pickup
│   ├── ui/
│   │   ├── hud.tscn
│   │   ├── sleep_meter.tscn
│   │   ├── xp_bar.tscn
│   │   ├── upgrade_screen.tscn
│   │   ├── upgrade_card.tscn
│   │   ├── game_over_screen.tscn
│   │   └── floating_joystick.tscn
│   └── effects/
│       ├── zzz_particles.tscn
│       ├── pillow_feathers.tscn
│       ├── snore_ring.tscn
│       └── enemy_sleep_poof.tscn
├── scripts/
│   ├── autoload/
│   │   ├── game_manager.gd         # Run state, wave logic, difficulty scaling
│   │   ├── upgrade_manager.gd      # Upgrade pool, rarity rolls, evolution checks
│   │   ├── meta_progression.gd     # Persistent save data, shard economy
│   │   ├── audio_manager.gd        # Dynamic music layers, SFX pooling
│   │   └── save_manager.gd         # Save/load with encryption
│   ├── data/
│   │   ├── enemy_data.gd           # Resource-based enemy definitions
│   │   ├── upgrade_data.gd         # All upgrade definitions as Resources
│   │   ├── ability_data.gd         # Ability stats and evolution recipes
│   │   └── wave_data.gd            # Wave composition tables
│   └── components/
│       ├── health_component.gd      # Reusable HP for enemies
│       ├── hitbox_component.gd
│       ├── hurtbox_component.gd
│       └── pickup_magnet.gd         # Attracts pickups within radius
├── resources/
│   ├── upgrades/                    # .tres files for each upgrade
│   ├── enemies/                     # .tres files for enemy configs
│   ├── abilities/                   # .tres files for ability configs
│   └── beds/                        # .tres files for bed definitions
├── art/
│   ├── sprites/
│   ├── tilesets/
│   └── ui/
├── audio/
│   ├── music/
│   └── sfx/
└── shaders/
    ├── dream_vignette.gdshader
    ├── sleep_meter_gradient.gdshader
    └── enemy_sleep_dissolve.gdshader
```

### Performance Considerations (Mobile)

| Concern | Solution |
|---|---|
| **Hundreds of enemies on screen** | Use Godot's `MultiMeshInstance2D` for rendering. Enemies share meshes. Logic runs on a staggered frame basis (not every enemy updates every frame). |
| **Projectile count** | Object pooling for all projectiles and particles. Pre-instantiate pools of 50+ for each ability. |
| **Particle effects** | Use `GPUParticles2D` with conservative particle counts (max 50 per emitter). Fallback to `CPUParticles2D` on low-end devices. |
| **Save data** | Use Godot's `ConfigFile` or `ResourceSaver` with AES-256 encryption for save integrity. Auto-save after each run. |
| **Memory** | Lazy-load Dream Themes. Only one theme's assets are in memory at a time. Use `ResourceLoader.load_threaded_request()` for async loading. |
| **Battery** | Cap framerate to 60fps. Offer a 30fps battery-saver mode. Reduce particle density in battery-saver mode. |

### Key Systems in Detail

**Enemy Spawning (ECS-lite Pattern)**

```
GameManager keeps a "threat_budget" that accumulates per second.
Each enemy type has a "threat_cost."
Every spawn tick (0.5s), the spawner:
  1. Checks budget
  2. Selects enemy types weighted by current Night
  3. Spawns at random edge position with offset jitter
  4. Deducts cost from budget
Enemies use NavigationAgent2D for basic pathfinding toward bed.
Elites and bosses use scripted spawn events (not budget-based).
```

**Upgrade Roll System**

```
UpgradeManager maintains the full pool of upgrades.
On level-up:
  1. Filter pool: remove maxed-out upgrades, add evolution options if eligible
  2. Roll rarity for each of 3 slots independently
  3. For each slot, pick a random upgrade of that rarity
  4. Ensure no duplicates in the 3 options (reroll if needed)
  5. Present to player
  6. On selection: apply upgrade, update ability stats, trigger visual feedback
```

**Sleep Meter System**

```
SleepMeter is an AutoLoad singleton.
- current_value: float (0.0 = deep sleep, 1.0 = awake)
- regen_rate: float (per second, modified by upgrades)
- damage_reduction: float (from Calmness upgrades)
- depth_zone: enum (DEEP, LIGHT, RESTLESS, CRITICAL)

Every physics frame:
  1. Apply regen (reduced if recently hit — 2s regen delay)
  2. Clamp to 0.0–1.0
  3. Update depth_zone
  4. Emit signal if zone changed (abilities listen to adjust multipliers)
  5. If >= 1.0: emit game_over signal
```

### Export Configuration

In `project.godot` and export presets:

- **Android:** Min SDK 24 (Android 7.0), target SDK 34. ARMv7 + ARM64. Vulkan mobile renderer with GLES3 fallback.
- **iOS:** Min iOS 15. Metal renderer.
- **Orientation:** Portrait locked.
- **Window size:** 720x1280 base, stretch mode = `canvas_items`, aspect = `expand`.

---

## Appendix: First 10 Minutes — New Player Experience

| Time | What Happens | Purpose |
|---|---|---|
| 0:00 | Title screen. "Tap to Sleep." | Tone-setting. No menu clutter. |
| 0:05 | Character tucks into bed. Gentle zoom to gameplay. | Establish the cozy vibe. |
| 0:10 | First zombie appears. Snore Wave auto-fires. "Your snoring defeated it!" tooltip. | Teach auto-attack without a tutorial wall. |
| 0:30 | 3–4 enemies at once. Player discovers they can drag to move. | Teach movement organically. |
| 1:00 | First level-up. Upgrade screen appears with 3 obvious choices. | Teach the upgrade system. First choice is always 3 strong options (no trap picks). |
| 2:00 | Alarm Clock enemy appears. Noticeably tougher. | Introduce enemy variety. |
| 3:00 | Night 2 begins. "Deep Sleep" text fades in. New enemy type. | Teach the Night system. |
| 5:00 | First mini-boss (Giant Alarm Clock). Brief camera zoom-out. | Memorable first boss moment. Guaranteed ability drop on defeat. |
| 7:00 | Player likely dies (by design). | First death should feel like "I almost had it!" not "this is unfair." |
| 7:05 | Game Over screen. Dream Shards earned. "Spend them in your bedroom!" | Introduce meta loop. Player immediately wants to upgrade and try again. |

---

*This document is a living design. Playtest early, playtest often. The numbers are starting points — balance through iteration, not theory.*
