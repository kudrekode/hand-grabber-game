# Big Hand for iPhone

Native SwiftUI menus and SpriteKit gameplay, targeting **Xcode 26.3, iOS 26, iPhone, portrait**. Open `BigHand.xcodeproj`; the shared `BigHand` scheme includes the app and XCTest target. There are no third-party packages, web views, accounts, backend services, or ad SDKs.

## Presentation pass · 3 October 2026

The hand is assembled from authored, cached vector artwork rasterized into small SpriteKit textures: palm, four independently articulated fingers, thumb, wrist and cuff. Skin changes reuse the same rig and collision geometry. Warm ivory, forest ink, lime and coral form the shared palette; Avenir Next is used in both SpriteKit and SwiftUI. Buttons have one outline, radius and pressed depth. Menus, the icon, gate signs and the HUD follow the same treatment.

Crushes contract and curl the digits, compress the palm, squash the target, land the impact, hold a flattened object, recoil and recover. Four material weights control timing, recoil, debris, sound and shake. Sound and haptics land at contact compression rather than firing twice. Failed obstacles briefly resist the hand. Relative dragging retains the original response and precision, with a separate visual lean; camera motion cannot enter the touch delta.

The camera adds a maximum 1.2% speed zoom and short, decaying impacts. Track edges move at a different rate from lane marks. SpriteKit emitters handle juice, debris, coins, gates and size milestones. Reduce Motion removes camera shake, limits movement and reduces bursts.

The workshop separates permanent upgrades from the hand collection. Classic is free; Red Glove, Gold Hand, Robot Hand, Zombie Hand and Foam Finger have local coin unlocks. Their stable IDs and saved entitlements can be granted by a future StoreKit adapter; no purchase framework is integrated. Cosmetics never change run effects. Existing upgrade prices, growth, spawns, collisions, rewards and scoring remain intact.

Performance bounds: hand parts are rasterized once per material at 3x (largest texture 270 × 282); twelve object textures are warmed per process; two tiny particle textures are shared. Bursts emit at most 24 particles with at most eight concurrent emitters. Audio reuses two players per cue and allows at most six concurrent voices, with throttled pickups. Hand and object artwork are not rebuilt per frame. The existing capped visual hand scale and above-hand obstacle ordering keep neighboring lanes readable.

## Verification status

- **Release iPhone device build succeeded** using Xcode 26.3 / iOS 26.2 SDK, with signing disabled.
- **19 tests passed on an isolated iPhone SE (3rd generation), iOS 26.2**, including 15 unit/integration checks and four UI tests. The normal home Play button remains fully visible on the compact first screen. Small and bus crushes, positive/negative gates, failure, size 50,000, actual relative touch dragging, pause/resume, upgrades and cosmetic unlock/equip were exercised.
- **18 tests passed on an isolated iPhone 17 Pro, iOS 26.2**: 15 unit/integration checks and three UI tests. All ten WAV cues decode, all six hand rigs stay bounded at absurd size, and the complete collision/gate/touch/shop suite passes.
- Eight platform-independent core checks passed, including 4,800 connected safe spawn rows.
- Compact screenshots were inspected; preview letterboxing and first-frame HUD positioning were corrected.

Physical-device haptic quality, audio feel and sustained frame rate still need playtesting. The largest remaining art opportunity is the simple geometric object artwork: the hand now has richer material definition than the vehicles and trolley.

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
- `Views/` and `Design/`: home, shop, gameplay HUD/pause and results, with one outlined button style, one panel style and a coherent arcade palette. Hand parts use cached authored textures, object art is rasterized from native paths, and gates remain sharp vector signs; no emoji assets.
- `Resources/`: app icon, launch color, privacy manifest and ten original WAV cues. `Scripts/generate-resources.py` reproduces resources using only Python's standard library.
- `Tests/` and `UITests/`: eight shared core checks, native session/presentation checks and actual simulator touch/shop tests. `Scripts/check-core.py` runs only platform-independent checks on the host.

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

`big-hand-native-save-v1` in UserDefaults stores coins, upgrade levels, best score, largest hand, longest distance, total runs, unlocked hand IDs and the equipped hand. Schema version 2 reads existing version-1 saves without losing progress; unknown cosmetic IDs are ignored, Classic stays unlocked, and an invalid equipped ID falls back to Classic. Each failure banks only unpaid rewards and counts the run once, even after continuing. Purchases and doubling save immediately. Records never decrease. Corrupt data falls back to defaults, and partially valid saves clamp invalid totals/levels. An older `magnet` upgrade field can migrate to Handling if explicitly imported.

Browser localStorage is separate and is **not automatically imported** into the native app. No reset, network or account system is added. Settings are also local to the device. The privacy manifest declares UserDefaults access for app-local data using Apple's [required-reason API guidance](https://developer.apple.com/documentation/technotes/tn3183-adding-required-reason-api-entries-to-your-privacy-manifest).

## Deterministic portrait QA

The shared scheme includes `BigHandTests` and `BigHandUITests`. UI tests launch with `-ui-testing`, which uses a separate UserDefaults suite and a fixture wallet; real player saves are untouched. Debug-only `-presentation-scenario small|large|gate|negativeGate|giant|fail|movement` fixtures wait for the first track touch. `-shop` opens the workshop. None of these launch paths exist in Release builds.

UI tests retain approach, post-impact, failure, touch and collection screenshots in the `.xcresult` bundle. Use a dedicated simulator rather than one running another app's automation. For example:

```sh
xcodebuild -project BigHand.xcodeproj -scheme BigHand \
  -destination 'platform=iOS Simulator,id=YOUR_SIMULATOR_UUID' \
  -derivedDataPath /tmp/BigHandQA CODE_SIGNING_ALLOWED=NO \
  -parallel-testing-enabled NO -resultBundlePath /tmp/BigHandQA.xcresult test
```

## Remaining verification and known limitations

Native build, XCTest and simulator launch verification are complete. For manual playtesting, tap **LET’S CRUSH** and drag horizontally anywhere on the gameplay track. Test compact and tall iPhone screens, pause/resume after interruptions, upgrade purchases, continue/double combinations, high scores, and persisted progress after relaunch. Check haptic intensity and audio on hardware; physical-device installation requires your development team for signing.

The source preserves the stronger prototype balance and intended weak **15–30s**, average **35–70s**, strong **70–120s** run targets. Those timings have not been measured in this native implementation; steering, fairness under real touch input, performance and game feel need device playtesting. Generated route checks establish layout properties, not achievable human run times.
