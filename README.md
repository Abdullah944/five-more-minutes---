# Five More Minutes! ⏰💤 

**Protect your sleep at all costs.** A cozy-comedy roguelike survivor for **Android / iOS** (portrait, one-thumb play).

You drift in bed. Disturbances (snoring zombies, alarm clocks with legs, barking pups) try to wake you. Abilities are **auto-fire**; you move the bed with a **floating joystick** and try to last as long as you can. Earn **Dream Shards**, upgrade the **bedroom hub**, unlock beds and abilities, and climb the on-device **Dream Hall** leaderboard.

## Tech

| | |
| --- | --- |
| **Engine** | [Godot 4.6](https://godotengine.org/) (Mobile Renderer) |
| **Language** | GDScript |
| **Platforms** | Android & iOS (portrait) |

## Run from source

1. Install **Godot 4.6** (matching project feature tag `4.6` + `Mobile`).
2. **Import** this folder as a project (or `project.godot`).
3. **Run** the main scene: `res://scenes/main/main_menu.tscn` (set as default in Project Settings; already configured in `project.godot`).

For **export** to devices, configure Android/iOS in **Project → Export** (see `export_presets.cfg`). Do not commit keystore, Apple provisioning secrets, or `.env` (see [Secrets](#secrets)).

## Project docs in this repo

| File | Contents |
| --- | --- |
| [**GDD.md**](./GDD.md) | Full game design: mechanics, content, economy, feel |
| [**CONTEXT.md**](./CONTEXT.md) | What’s implemented: systems, scenes, autoloads, assets, milestones |

## Repository layout (short)

- `scenes/` — Main menu, hub, run `game.tscn`, player bed, UI, abilities
- `scripts/autoload/` — Save, meta progression, game loop, audio, settings, etc.
- `art/`, `audio/` — Art and audio (see `CONTEXT.md` for details)

## Secrets & tools

- Copy **`.env.example`** to **`.env`** for local dev tools (e.g. SpriteCook / Telegram bot). **Never commit `.env`.**
- **Telegram bot** autoload is **debug-only**; do not ship credentials in release builds.

## Credits

Game by **kw.hades** (in-game credit). For collaboration, use issues and PRs on the hosting remote you use for this repo.
