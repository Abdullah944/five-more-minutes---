# Five More Minutes! — Project Context

## What This Game Is

**Five More Minutes!** is a cozy-comedy roguelike survivor for Android/iOS, built in Godot 4.6 with the Mobile Renderer. The player is a character sleeping in a bed, defending their sleep from increasingly absurd disturbances (zombie snorers, alarm clocks with legs, barking pups). All combat is auto-fire; the player's only input is dragging the bed around with a floating joystick in portrait mode.

**Core fantasy:** "Protect your sleep at all costs."

## Recent systems (milestone)

- **Bed loadout:** `MetaProgression.BED_STARTING_ABILITY_KEYS` + `get_bed_starting_ability_keys()` drive starting weapons after intro; `Game._apply_bed_starting_loadout()` replaces a fixed level 2/4 ability schedule. Meta furniture bonuses re-apply after `GameManager.start_run()` so saves are not wiped by `_reset_stats()`.
- **Discoverable abilities:** Night Light (unlock card), Dream Catcher (warm milk drop stat). Level-up uses `UpgradeManager.roll_level_up_choices()` (stats + possible Night Light + optional 4th evolution: Sleep Paralysis Field).
- **Caffeine / alarm:** `base_enemy.locks_sleep_meter` (alarm clocks) locks meter on contact and ranged; bed hurtbox also checks parent.
- **Shard packs (placeholder):** free grants only in **debug** or if `fmm/allow_dev_shard_grants` is true in Project Settings; release builds show disabled “IAP” until wired.
- **Polish:** `SettingsManager.play_haptic_ms`, reduced-motion skips upgrade panel tween, long-press tooltip on level-up cards.

## What Is Already Built

### Autoload Singletons (8 registered + 1 new)

| Singleton | File | Purpose |
|---|---|---|
| SaveManager | `scripts/autoload/save_manager.gd` | Encrypted save/load via ConfigFile |
| MetaProgression | `scripts/autoload/meta_progression.gd` | Dream Shards, furniture upgrades, unlocks, achievements, daily tracking |
| GameManager | `scripts/autoload/game_manager.gd` | Run state, wave/threat budget spawning, Night progression, breathing room |
| UpgradeManager | `scripts/autoload/upgrade_manager.gd` | Upgrade pool, rarity rolls, evolution checks |
| AudioManager | `scripts/autoload/audio_manager.gd` | Dynamic music layers by sleep depth zone, SFX pool, UI sounds |
| SleepMeter | `scripts/autoload/sleep_meter.gd` | Central mechanic: 0.0–1.0 meter with 4 depth zones, regen, lock, snooze |
| MissionManager | `scripts/autoload/mission_manager.gd` | Daily/weekly mission tracking |
| SettingsManager | `scripts/autoload/settings_manager.gd` | Battery saver, haptics, accessibility, text scale |
| TelegramBot | `scripts/autoload/telegram_bot.gd` | Dev-only remote control via Telegram (debug builds only) |

### Scenes (implemented)

- `scenes/main/` — game.gd, bedroom_hub.gd, main_menu.gd, enemy_spawner.gd
- `scenes/player/` — bed.gd (the player)
- `scenes/enemies/` — base_enemy.gd
- `scenes/abilities/` — snore_wave.gd, pillow_toss.gd, pillow_projectile.gd, dream_beam.gd, **night_light.gd**, base_ability.gd
- `scenes/pickups/` — sleep_energy.gd, warm_milk.gd
- `scenes/ui/` — hud.gd, floating_joystick.gd, upgrade_selection.gd, game_over_screen.gd, pause_menu.gd, settings_panel.gd, missions_panel.gd, store_screen.gd

### Data Scripts

- `scripts/data/` — enemy_data.gd, upgrade_data.gd, upgrade_definitions.gd, ability_data.gd, wave_data.gd

### Components

- `scripts/components/` — health_component.gd, hitbox_component.gd, hurtbox_component.gd, pickup_magnet.gd

### Systems

- `scripts/systems/object_pool.gd` — Object pooling for projectiles/particles

### Art Assets

- Sprites, backgrounds, hub furniture art, store frames, and icons are in `art/` (not only the hero; see GDD for remaining gaps)
- `art/tilesets/` — still empty (tile layers optional vs full-screen dream PNGs)
- `art/ui/` — HUD icons, upgrade card frames, shard icon, etc.

### Shaders

- `shaders/` — dream_vignette.gdshader, sleep_meter_gradient.gdshader, enemy_sleep_dissolve.gdshader (placeholder files)

### Audio

- `audio/music/` and `audio/sfx/` — Directory structure exists

## Game Feel Requirements (from GDD)

- Enemies yawn and fall asleep with "poof" of ZZZ particles on defeat
- Snore Wave: expanding translucent ring with Z letters
- Pillow hits: squish + feather particles
- Level up: screen flash, enemy freeze, confetti of moons/stars
- Sleep Meter critical: red pulsing edges, muffled heartbeat
- All SFX should sound "muffled/dreamy"
- Music: lo-fi beats that layer dynamically based on sleep depth zone
- Haptic feedback patterns defined per event type

## SpriteCook AI (Asset Generation)

- MCP server configured in `.cursor/mcp.json` and `.vscode/mcp.json`
- Server: SpriteCook v2.14.5, endpoint `https://api.spritecook.ai/mcp/`
- Tools available: `generate_game_art`, `animate_game_art`, `get_credit_balance`, `check_job_status`
- Default style: pixel art, transparent backgrounds, `smart_crop_mode="tightest"`
- Recommended model: `gemini-3.1-flash-image-preview`
- **`spritecook-assets.json`** at project root stores SpriteCook `asset_id` values for the pipeline

### Assets pipeline (SpriteCook)

- Batch prompts and output paths live in **`tools/spritecook_batch_manifest.json`**. Run **`python3 tools/spritecook_batch.py --from-dotenv`** after putting `SPRITECOOK_API_KEY` in `.env` (see `.env.example`). The script updates **`spritecook-assets.json`** per generated file.
- Covered by that manifest: new regular enemies (mosquito, neighbor, delivery drone), rotating **boss** sprites (espresso golem, DJ rooster, thunder cloud), **seven** alternate bed skins under `art/sprites/beds/`, optional **underwater** dream background, and **category frame** art for the level-up card picker.
- **In-game:** `EnemySpawner` unlocks the new enemy types and applies boss textures when those PNGs exist; `MetaProgression.BED_TEXTURE_PATHS` drives equipped bed art during runs; upgrade cards use SpriteCook frames if the files are present.

### Assets still nice-to-have

- **Pajamas:** in-run hero overlays per pajama (store still uses text icons).
- **Abilities:** extra VFX for abilities not yet represented as dedicated sprites.
- **Tilesets:** full tile layer assets (background PNGs already cover many dream moods).
- **HUD / joystick:** optional bespoke art beyond current UI icons.

## Telegram Bot Setup

- `TelegramBot.gd` registered as AutoLoad singleton
- Reads `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` from `res://.env` at runtime
- Only active in debug builds (`OS.is_debug_build()`)
- Polls Telegram getUpdates every 3 seconds
- Silently ignores messages from any chat ID other than the configured one
- Commands: `/status`, `/spawn <name>`, `/pause`, `/screenshot`, `/build`

## iOS export and Xcode

Godot’s iOS export writes an Xcode project plus native libraries (for example `fiveminGame.xcframework` and `libgodot.a`) into the **same output folder**. Treat that folder as a single bundle: do not copy only the `.xcodeproj` elsewhere without the matching frameworks.

**If Xcode shows many lines like “Ignoring file … built for x86_64 … required architecture arm64” and then `Undefined symbol: _main`:** Xcode is linking for **arm64** (typical for **Apple Silicon iOS Simulator**) but the slice it is using does not contain arm64. In a current export (for example `~/Desktop/1`), `lipo -info` on `fiveminGame.xcframework/ios-arm64/libgodot.a` reports **arm64** (physical device), while `…/ios-arm64_x86_64-simulator/libgodot.a` can still be **x86_64-only** despite the folder name—so the Simulator run destination gets no usable `libgodot.a`. A mixed or partial copy of the export folder can cause the same symptom.

1. **Prefer a physical iPhone** first: that uses the `ios-arm64` slice and avoids the Simulator-only mismatch.
2. In Xcode: **Product → Clean Build Folder**, then quit Xcode and delete **DerivedData** for that project (Xcode Settings → Locations → Derived Data → delete the `fiveminGame-*` folder, or remove `~/Library/Developer/Xcode/DerivedData/fiveminGame-*`).
3. In Godot: export again into a **fresh empty directory** (or delete the old export output completely first) so every native library matches the same export.
4. For **Simulator on Apple Silicon**, you need an **arm64** Simulator slice in the engine export template (check your Godot version / iOS export template release notes), or use legacy options (for example opening Xcode under Rosetta) only if your toolchain still supports them—device builds remain the reliable path.

Android and iOS bundle identifiers in `export_presets.cfg` are aligned on `com.kwhades.fivemoreminutes`.

## Security Rules

- `.env` contains real secrets — never committed to git
- `.gitignore` excludes: `.env`, `*.env`, `export_credentials.cfg`, `android/`
- `.env.example` has empty placeholders for collaborators
- Tokens are never baked into exported APKs (TelegramBot is debug-only)
- SpriteCook API key lives in MCP config (handled by Cursor, not in game code)

## Decisions Made

1. **Portrait-only, 720x1280 base** with canvas_items stretch mode and expand aspect
2. **Mobile renderer** with ETC2/ASTC texture compression
3. **AES-256 encrypted saves** via ConfigFile
4. **8 autoload singletons** covering all major systems
5. **Component architecture** for enemy behaviors (health, hitbox, hurtbox)
6. **Object pooling** for projectile/particle performance
7. **Bed-driven starting loadout** (`BED_STARTING_ABILITY_KEYS`) plus discoverable Night Light + evolution; core kit remains Snore / Pillow / Dream Beam scenes
8. **Sleep Meter with 4 depth zones** — each zone modifies damage, AoE, enemy speed, and pickup radius
9. **Threat budget spawner** with time-based curve and breathing room every 90s
10. **Full meta progression economy** — Dream Shards, 8 furniture tiers, beds, pajamas, themes
11. **Daily/weekly mission system** with streak tracking
12. **Dynamic music layering** — 4 audio layers that crossfade based on sleep depth zone

## Needs Clarification

- **Ability evolution UI:** A 4th evolution card is appended when eligible (same card chrome, slightly narrower layout). Optional later: unique frame art.
- **Lazy Mode:** The GDD describes auto-dodge idle play. Is this a priority feature or backlog?
- **Seasonal content system:** Is there any infrastructure needed now, or is this post-launch?
- **Screenshot sharing:** The GDD mentions auto-watermarking and social share cards. Should the `/screenshot` bot command produce the watermarked version?
- **Noisy Neighbor "fixed spot" behavior:** Does the Neighbor pick a random position on spawn, or does it always go to the same anchor points?
- **Delivery Drone doorbell hazard:** How long does the stationary doorbell package last before despawning?
- **Export presets:** `export_presets.cfg` is in-repo (Android + iOS). Telegram remains debug-only and must not ship credentials in release builds.
