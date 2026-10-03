# Big Hand for iPhone

Native SwiftUI menus and SpriteKit gameplay, targeting **Xcode 26.3, iOS 26, iPhone, portrait**. Open `BigHand.xcodeproj`; the shared `BigHand` scheme includes the app and XCTest target. There are no third-party packages, web views, accounts, backend services, or ad SDKs.

## Verification status

Verified on 3 October 2026 with **Xcode 26.3**, the **iOS 26.2 SDK**, and an **iPhone 17 Pro simulator running iOS 26.2**. The deployment target remains iOS 26.

- Native iOS device build succeeded with signing disabled.
- All **11 XCTest tests passed**, with no failures or skipped tests. These include core gameplay, persistence, rewards, pause/continue, and deterministic SpriteKit scene stepping.
- The simulator app installed and launched successfully; the home screen was visually inspected.
- Eight platform-independent Swift logic checks also passed, including 4,800 generated rows, using `python3 Scripts/check-core.py`.
- Xcode project/plist structure, resource membership, scheme references, icon metadata and bundled audio validation passed.

Physical-device touch response, haptics, performance and human run lengths still need playtesting.

## Run in Xcode 26.3

1. Open `BigHand.xcodeproj` in Xcode 26.3.
2. Install an iOS 26 iPhone simulator runtime under Xcode Settings → Components if needed.
3. Choose the **BigHand** scheme and an iPhone running iOS 26.
4. Use **Product → Run** (⌘R) and **Product → Test** (⌘U).
5. For a physical iPhone, choose your development team in Signing & Capabilities and use a unique bundle identifier if required.

The command-line verification helper refuses Xcode older than 26.3, runs the tests (which builds the app), installs it, and launches its process on an iOS 26 iPhone simulator:

```sh
cd ios/BigHand
# If xcode-select still points to the previous installation, choose the new Xcode:
# export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
bash Scripts/verify-ios.sh
# Optional: bash Scripts/verify-ios.sh SIMULATOR_UUID
```

A successful simulator process launch still requires manual visual and interaction checks. No script automatically changes `xcode-select` or installs Xcode.

## Architecture

- `App/GameSession.swift`: SwiftUI navigation, upgrade purchases, immutable effects for each run, reward requests and settlement. The scene publishes HUD snapshots at 10 Hz; rendering and input remain in SpriteKit.
- `Models/`: configurable balance, twelve objects, upgrades, run state and sanitized versioned save model.
- `Game/BigHandScene.swift`: frame updates, relative one-thumb dragging, world scrolling, contact, animation and native node hierarchy. The track adapts to the gameplay viewport.
- `Game/SpawnSystem.swift`: three lanes, connected safe routes, gate pairs and an empty gate bypass. Seeded randomness makes route properties repeatable in tests.
- `Game/CollisionSystem.swift`: bounded palm contact and swept collision detection. Object sizes determine eligibility; visual scale never makes adjacent lanes unreachable.
- `Game/DifficultySystem.swift`, `GateSystem.swift`, `Economy.swift`: elapsed-time difficulty, weighted modifiers, growth, cumulative coin rounding and idempotent payouts.
- `Services/`: UserDefaults, simulated rewarded-ad protocol, synthesized bundled audio and native UIKit haptics.
- `Views/` and `Design/`: home, shop, gameplay HUD/pause and results, with one outlined button style, one panel style and a coherent arcade palette. Art is authored from native paths; no emoji assets.
- `Resources/`: app icon, launch color, privacy manifest and eight original WAV cues. `Scripts/generate-resources.py` reproduces resources using only Python's standard library.
- `Tests/`: eight shared core checks and native session integration tests. `Scripts/check-core.py` runs only platform-independent checks on the host.

## Reference gameplay and balance

The repository's current source takes precedence over the older `spec.md`. In particular, cars are size **180**, buses **360**, and crush growth is **object size × 0.015 × growth upgrade**.

- Start size 20; equal-sized objects can be crushed; an oversized palm contact ends the run.
- The hand follows relative finger motion across the track, clamped to x 48–372. Response is 24 × Handling per second, smoothed independently of frame rate.
- World speed starts at 210, increases by 4.5 per second after 10 seconds, and caps at 570. Distance uses 0.045 metres per world point.
- Rows start 1.6 seconds apart and ramp after 10 seconds to a minimum of 1.08 seconds.
- Difficulty phases begin at 0, 10, 30 and 60 seconds. Object size unlocks occur at 0/8/12/16/24 seconds, up to 15/35/70/180/360.
- Danger probabilities are 18%/85%/96%/100%; two-danger-row probabilities are 0%/30%/70%/90%. Each row has a safe route connected to every safe choice in the previous row by at most one lane change.
- Every sixth row contains two gates and a bypass. At least one is positive. The second is positive with probability 10% + 5% per Lucky Gates level. Positive gates favor +10 (weight 18) over +25 and ×1.5 (weight 1 each). Negative gates favor −10 (weight 3) over ÷2 (weight 1). Size clamps at 1.
- Score is object score + floor(distance × 2 + largest size × 3).
- Coins from crushed objects become collectible pickups. Round the cumulative base total after applying Coin Multiplier so fractional rewards are retained.
- Five levels each: Starting Hand Size +5; Crush Growth +30%; Handling +15%; Coin Multiplier +0.2; Lucky Gates +5 percentage points. Costs: **250 / 500 / 1,500 / 4,500 / 13,500**. Purchases affect the next new run, including when buying between a failure and a continue.
- Stage labels are Tiny / Normal / Large / Huge / Absurd at 30 / 80 / 160 / 500. Smooth visual scaling saturates to protect visibility; incoming objects render above the hand.
- Continue grants +25% size, once per run, and clears the approach. Double coins can be used once and also applies to further coins earned after a continue. Start boost grants +50% size for one new run. All are clearly labeled simulated rewards.

Crushing animates the fingers separately, flattens the object, recoils the palm, emits juice or fragments, and shows score, growth and coin feedback. Weight, hit stop, shake and haptics scale with size. Failure leaves the obstacle visible and states both required and actual size before results. Reduce Motion suppresses shake and limits movement/particles. Sound is off initially and optional; haptics have a separate toggle. Backgrounding requires an explicit resume and does not advance elapsed time.

## Persistence

`big-hand-native-save-v1` in UserDefaults stores coins, upgrade levels, best score, largest hand, longest distance and total runs. Each failure banks only unpaid rewards and counts the run once, even after continuing. Purchases and doubling save immediately. Records never decrease. Corrupt data falls back to defaults, and partially valid saves clamp invalid totals/levels. An older `magnet` upgrade field can migrate to Handling if explicitly imported.

Browser localStorage is separate and is **not automatically imported** into the native app. No reset, network or account system is added. Settings are also local to the device. The privacy manifest declares UserDefaults access for app-local data using Apple's [required-reason API guidance](https://developer.apple.com/documentation/technotes/tn3183-adding-required-reason-api-entries-to-your-privacy-manifest).

## Remaining verification and known limitations

Native build, XCTest and simulator launch verification are complete. For manual playtesting, tap **LET’S CRUSH** and drag horizontally anywhere on the gameplay track. Test compact and tall iPhone screens, pause/resume after interruptions, upgrade purchases, continue/double combinations, high scores, and persisted progress after relaunch. Check haptic intensity and audio on hardware; physical-device installation requires your development team for signing.

The source preserves the stronger prototype balance and intended weak **15–30s**, average **35–70s**, strong **70–120s** run targets. Those timings have not been measured in this native implementation; steering, fairness under real touch input, performance and game feel need device playtesting. Generated route checks establish layout properties, not achievable human run times.
