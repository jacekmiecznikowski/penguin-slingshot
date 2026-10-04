# Penguin Slingshot

A small 3D mobile launcher game prototype made with Godot 4, targeting Android in portrait orientation.

## Current checkpoint: Stage 3 — economy and upgrades

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
- asset/license documentation in `ASSETS.md`,
- economy/balance notes in `ECONOMY.md`.

## Run

1. Install a stable Godot 4.x release (the project is intentionally simple and uses the compatibility renderer).
2. Open `project.godot`.
3. For direct `.blend` import, install Blender and configure its path in Godot. Alternatively export `assets/penguin/penguin.blend` once to `assets/penguin/penguin.glb`.
4. Press F6/F5.
5. Drag on screen down-and-left and release to launch.
6. After landing, spend coins on upgrades or tap outside the cards to launch again.
7. Press `R` to restart a run on desktop.

## Upgrade loop

- **Proca**: stronger initial impulse.
- **Sanki**: lower effective gravity + a capped glide assist while descending.
- **Dochód**: larger coin payout per meter.

A fresh save starts with 150 coins, enough to buy one first-level upgrade. Progress is saved after every run reward and every upgrade purchase.

## Android export

Install Godot's Android build template plus Android SDK/JDK, configure Editor Settings > Export > Android, then add an Android export preset. The renderer is set to `gl_compatibility` for broad device support.

## Performance notes

Imported GLB scenery is visual-only. Ground collision stays procedural, which avoids many static collision objects and keeps the prototype lightweight for mobile. Only a small subset of the supplied CC0 packs is included in the project.

## Asset policy

See `ASSETS.md`. All included third-party art is selected as CC0/public-domain. The game keeps primitive fallbacks so external imports do not block development.

## Planned next stages

- Stage 4: obstacles, pickups, level progression, impact/launch juice, particles and audio.
- Stage 5: Android export preset, CI/build automation, performance pass and release checklist.
