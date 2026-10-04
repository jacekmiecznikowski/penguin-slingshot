# Stage 4 — course gameplay and juice

Checkpoint adds a lightweight mobile-friendly course layer on top of the Stage 3 economy.

## Added

- 24 reusable coin pickups placed in arcs at several flight heights,
- three reusable boost pickups that add forward/upward impulse,
- six low physical ice/snow obstacles,
- five named 80 m course sections,
- live per-run pickup counter,
- distance reward + pickup reward breakdown on the results screen,
- speed-sensitive camera FOV,
- GPU burst particles for launch, pickups and impacts,
- procedural PCM sound effects generated in GDScript (no external audio license/dependency),
- collision feedback and a small velocity penalty when hitting obstacles,
- all course pickups reset between attempts.

## Mobile performance choices

- Course geometry uses primitive meshes and simple collision boxes.
- Kenney scenery remains visual-only.
- Pickups are reused instead of recreated each run.
- VFX are short one-shot particle systems that free themselves.
- Audio clips are tiny in-memory mono PCM buffers generated once on startup.
