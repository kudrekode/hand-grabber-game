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
- `src/game/collision.ts`: palm/object contact bounds and impact strength.
- `src/services/soundService.ts`: generated arcade sound cues.
- `src/main.ts`: connected procedural rows, impact animations and UI.

Progress is stored locally under `big-hand-save-v1`. Rewarded actions immediately succeed through the placeholder ad service. Analytics only log to the browser console; no data is sent externally.

The between-run shop shows current and next effects. Each upgrade has five levels costing 250, 500, 1,500, 4,500, and 13,500 coins. Purchases apply to the next new run. Earlier Coin Magnet purchases carry over as Handling levels.

## Native iPhone version

The SwiftUI/SpriteKit implementation is in [`ios/BigHand`](ios/BigHand/README.md). Open `ios/BigHand/BigHand.xcodeproj` in **Xcode 26.3**, choose an iOS 26 iPhone, and press **⌘R**. Native device and simulator builds succeeded, all **11 XCTest tests passed**, and the app launched on an iPhone 17 Pro simulator running iOS 26.2. Tap **LET’S CRUSH** and drag horizontally to play. See the native README for setup, architecture, preserved balance and remaining device playtesting.
