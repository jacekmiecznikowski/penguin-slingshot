# Penguin Slingshot

A small 3D mobile launcher game prototype made with Godot 4, targeting Android in portrait orientation.

## Current checkpoint: Stage 2 + CC0 asset integration

Implemented:

- portrait mobile layout,
- touch/mouse drag-to-launch slingshot gesture,
- physics-driven penguin flight,
- smooth follow camera,
- live distance counter,
- end-of-run detection and restart,
- snowy 3D environment,
- CC0 Kenney Holiday/Nature GLB scenery integrated into the runtime,
- CC0 OpenGameArt penguin source model added,
- automatic preference for `assets/penguin/penguin.glb`, then `penguin.blend`, then a primitive fallback,
- local asset/license documentation in `ASSETS.md`.

## Run

1. Install Godot 4.3+.
2. Open `project.godot`.
3. For direct `.blend` import, install Blender and configure its path in Godot. Alternatively export `assets/penguin/penguin.blend` once to `assets/penguin/penguin.glb`.
4. Press F6/F5.
5. Drag on screen down-and-left and release to launch.
6. Press `R` to restart on desktop.

## Android export

Install Godot's Android build template plus Android SDK/JDK, configure Editor Settings > Export > Android, then add an Android export preset. The renderer is set to `gl_compatibility` for broad device support.

## Performance notes

The imported GLB scenery is visual-only. Ground collision stays procedural, which avoids many static collision objects and keeps the prototype lightweight for mobile. Only a small subset of the supplied CC0 packs is included in the project.

## Asset policy

See `ASSETS.md`. All included third-party art is selected as CC0/public-domain. The game keeps primitive fallbacks so external imports do not block development.

## Planned next stages

- Stage 3: coins, economy, three upgrade paths (slingshot / glide or sled / income), persistence.
- Stage 4: obstacles, pickups, level progression, juice/VFX/audio, richer environment.
- Stage 5: Android export preset, build automation, performance pass and release checklist.
