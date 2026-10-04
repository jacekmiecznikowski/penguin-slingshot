# Penguin Slingshot

A small 3D mobile launcher game prototype made with Godot 4, targeting Android in portrait orientation.

## Current checkpoint: Stage 4 — course gameplay, pickups and juice

Implemented:

- portrait mobile layout,
- touch/mouse drag-to-launch slingshot gesture,
- physics-driven penguin flight,
- smooth follow camera,
- live distance counter,
- end-of-run detection and restart,
- snowy 3D environment using a lightweight subset of CC0 Kenney assets,
- CC0 OpenGameArt penguin source model with a primitive fallback,
- coins awarded after every completed launch,
- three persistent upgrade paths: **Proca**, **Sanki**, **Dochód**,
- upgrade prices that scale with level,
- upgrade effects wired into launch force, glide physics and coin payout,
- local save file at `user://progress.json`,
- mobile-style three-card upgrade UI and run reward panel,
- 24 collectible coin pickups and three boost pickups,
- six physical ice/snow obstacles across five named course sections,
- speed-sensitive camera FOV,
- one-shot particle bursts and procedural in-memory sound effects,
- asset/license documentation in `ASSETS.md`,
- economy/balance notes in `ECONOMY.md`.

## Run

1. Install Godot 4.7.2 Standard (GDScript; the .NET build is not needed).
2. Open `project.godot`.
3. For direct `.blend` import, install Blender 3.0+ before opening the project. If Blender is missing, the game can still use its primitive penguin fallback.
4. Press F6/F5.
5. Drag on screen down-and-left and release to launch.
6. After landing, spend coins on upgrades or tap outside the cards to launch again.
7. Press `R` to restart a run on desktop.

## Upgrade loop

- **Proca**: stronger initial impulse.
- **Sanki**: lower effective gravity + a capped glide assist while descending.
- **Dochód**: larger coin payout per meter and larger course-coin value.

A fresh save starts with 150 coins, enough to buy one first-level upgrade. Progress is saved after every run reward, every upgrade purchase and every collected course coin.

## Android export

The renderer is set to `gl_compatibility` for broad device support. Android export preset/build automation are planned for Stage 5.

## Performance notes

Imported GLB scenery is visual-only. Ground/course collision uses simple primitive boxes. Pickups are reused between runs; VFX are short one-shot particle systems; SFX are tiny generated mono PCM buffers.

## Asset policy

See `ASSETS.md`. All included third-party art is selected as CC0/public-domain. The game keeps primitive fallbacks so external imports do not block development.

## Testing

See `TESTING.md` for step-by-step desktop instructions and save-reset locations. See `STAGE4.md` for the current course feature list.

## Planned next stage

- Stage 5: Android export preset, CI/build automation, performance pass and release checklist.
