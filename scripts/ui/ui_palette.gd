extends Node

## Shared UI colors for menus, HUD overrides, and dynamic panels.
## Autoload singleton — access via UIPalette anywhere.

# --- Core palette (3 calm colors) ---
const NIGHT_NAVY: Color = Color("15172B")   # main background
const DREAM_VIOLET: Color = Color("4A4F8F") # cards/buttons
const MOON_GOLD: Color = Color("F3C969")    # highlights/currency

# --- Reusable semantic colors ---
const SURFACE: Color = Color("333867")
const SURFACE_HOVER: Color = Color("41478A")
const TEXT_PRIMARY: Color = Color("F2F3FF")
const TEXT_MUTED: Color = Color("A7A9C7")
const SUCCESS: Color = Color("6FD28A")
const DANGER: Color = Color("E85A6A")
const WARNING: Color = Color("F3C969")
