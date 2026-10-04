# Big Hand

Portrait arcade MVP implemented from `spec.md` (the specification supplied in this repository).

## Run

```sh
npm install
npm run dev
```

Open the local URL printed by Vite. Drag horizontally anywhere on the track. Desktop controls also support mouse dragging, arrow keys, and A/D. The sound button enables optional synthesized effects.

```sh
npm test
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

The between-run shop shows current and next effects. Each of the five upgrade types now has eight levels costing 75, 180, 450, 1,200, 3,000, 7,000, 16,000, and 36,000 coins. Existing purchased levels and their effects are preserved. Purchases apply to the next new run. Earlier Coin Magnet purchases carry over as Handling levels.

## Native iPhone version

The SwiftUI/SpriteKit implementation is in [`ios/BigHand`](ios/BigHand/README.md). Open `ios/BigHand/BigHand.xcodeproj` in **Xcode 26.3**, choose an iOS 26 iPhone, and press **⌘R**. The native presentation pass adds an articulated cartoon hand, weighted crush feedback, polished gates/HUD and six locally saved hand cosmetics. The current optimized device build succeeded; **20 tests passed on iPhone SE** and **18 on iPhone 17 Pro** portrait simulators running iOS 26.2, including real touch and shop interactions. Tap **LET’S CRUSH** and drag horizontally to play. See the native README for setup, architecture, preserved balance and remaining device playtesting.

## Smoothness and balance · 4 October 2026

Both versions keep the world moving throughout crush animations, keep the camera steady during crushes, and show the same neutral gate and item number styling regardless of whether a choice helps or harms. Browser HUD values update in place.

Speed starts at 280 and ramps by 14 per second after three seconds, up to 760. Rows tighten from 1.25 to 0.72 seconds; phases start at 0/6/18/35 seconds. After 18 seconds, item requirements grow continuously on a power curve with no gameplay ceiling and also scale with the hand. Crushable items and rewards scale with the hand, additive gates stay useful, and oversized items remain available even above size 360. Artwork and collision bounds stay limited to preserve clear lanes.

`npm test` checks browser scaling, collision bounds, gates, progression, and save compatibility. `python3 ios/BigHand/Scripts/check-core.py` checks the native core, including 4,800 generated safe routes. Native XCTest compares visible track and crushed object motion with uninterrupted scrolling at 60 and 120 Hz, while confirming the hand still animates. A live renderer check exercises repeated crushes with sound enabled; delayed frames preserve scrolling time, and native audio playback runs off the render thread. Sound voices and pickup artwork are prepared before impact; browser noise buffers are reused.
