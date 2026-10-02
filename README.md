# Big Hand

Portrait arcade MVP implemented from `spec.md` (the specification supplied in this repository).

## Run

```sh
npm install
npm run dev
```

Open the local URL printed by Vite. Drag horizontally anywhere on the track. Desktop controls also support mouse dragging, arrow keys, and A/D. The sound button enables optional synthesized effects.

```sh
npm run build
npm run preview
```

## Tuning

- `src/game/config.ts`: movement, growth, scoring, rewards, upgrade cost scaling.
- `src/game/objects.ts`: all twelve crushable object definitions.
- `src/game/gates.ts`: positive and negative gate definitions.
- `src/game/progression.ts`: five permanent upgrade definitions, per-level costs, and effects.
- `src/main.ts`: procedural rows, collision loop and UI.

Progress is stored locally under `big-hand-save-v1`. Rewarded actions immediately succeed through the placeholder ad service. Analytics only log to the browser console; no data is sent externally.

The between-run shop shows current and next effects. Each upgrade has five levels costing 250, 500, 1,500, 4,500, and 13,500 coins. Purchases apply to the next new run. Earlier Coin Magnet purchases carry over as Handling levels.
