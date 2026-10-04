# Economy and upgrade model

Stage 3 adds a persistent, offline economy stored in `user://progress.json`.

## Run rewards

A completed launch awards coins from the best horizontal distance reached in that run:

`coins = max(5, floor(distance_m * 1.15)) * income_multiplier`

The reward is granted exactly once when the run transitions to the finished state.

## Upgrades

Each path has 20 levels. Costs grow by `1.48^level` and are rounded to the nearest 5 coins.

- **Slingshot / Proca** — +7.5% launch impulse per level.
- **Sled / Sanki** — reduces gravity by 2.2% per level (floor: 56% of normal gravity), lowers linear damping slightly and adds a capped glide force while descending.
- **Income / Dochód** — +25% run coins per level.

Starting balance: 150 coins. Base level-0 prices are 90 / 120 / 140 coins respectively so a new player can immediately try one progression choice.

## Persistence

Saved fields:

- save version,
- current coin balance,
- levels for all three upgrade paths.

Invalid/missing values fall back to defaults and upgrade levels are clamped to the supported range.
