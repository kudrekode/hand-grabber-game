# Big Hand — MVP Game Spec

## 1. Goal

Build a small portrait mobile arcade game called **Big Hand**.

The player controls a giant hand moving forward through a simple obstacle course.

The hand must crush or grab objects smaller than itself while avoiding objects that are too large.

The core loop should feel:
- instantly understandable
- stupid/funny
- satisfying
- fast
- visually exaggerated
- playable one-handed
- suitable for 30-second to 2-minute runs

This is an MVP/prototype.

Do NOT overengineer.

Prioritise the core mechanic and game feel.

---

# 2. Technical Target

For the first version:

- Browser game
- TypeScript
- Vite
- HTML/CSS/Canvas
- No backend
- No login
- No database
- No external APIs
- No real ads
- No payments
- Minimal dependencies

It must run with:

npm install
npm run dev

The game should be designed for a portrait phone viewport.

Keep gameplay data/config separate from rendering where practical so it can later be ported to native iOS.

---

# 3. Core Concept

The player has a hand with a numeric SIZE value.

Example:

Hand Size: 25

Objects approach the player.

Each object also has a size.

Example:

Cherry: size 5
Apple: size 12
Watermelon: size 30
Traffic cone: size 40
Car: size 80

If:

handSize >= objectSize

the player can crush/grab the object.

If:

handSize < objectSize

the hand takes damage or the run ends.

The immediate player fantasy is:

"Make the hand ridiculously huge."

---

# 4. Core Loop

Start run
↓
Hand automatically moves forward
↓
Objects and gates appear
↓
Player moves left/right
↓
Collect small objects
↓
Avoid objects that are too large
↓
Pass through upgrade/downgrade gates
↓
Hand grows or shrinks
↓
Difficulty increases
↓
Reach finish or die
↓
Receive score/coins
↓
Restart

---

# 5. Controls

Portrait mobile controls.

Preferred control:

- drag finger horizontally anywhere on screen
- hand follows left/right
- forward movement is automatic

Desktop prototype:
- mouse drag
- arrow keys or A/D as fallback

Do not require tapping tiny controls during gameplay.

---

# 6. Player Hand

Player properties:

- size
- health
- score
- coins
- speed

Initial values:

size = 20
health = 1
score = 0
coins = 0

For MVP, one collision with an oversized object ends the run.

Keep health in the data model so multiple-hit mechanics could be added later.

---

# 7. Visual Hand Growth

The hand should visibly scale as size increases.

Suggested ranges:

1–19:
Tiny

20–39:
Normal

40–69:
Large

70–109:
Huge

110+:
Absurd

The visual hand should become noticeably larger during a run.

Avoid realistic anatomy.

Style should be:
- cartoon
- chunky
- exaggerated
- slightly ridiculous

For MVP use simple vector/CSS/canvas art if necessary.

No complex character art required.

---

# 8. Object System

Objects should be data-driven.

Each object contains:

- id
- name
- size
- scoreValue
- coinValue
- visual
- category

Initial objects:

## Cherry
size: 5
score: 5
coins: 1

## Strawberry
size: 8
score: 8
coins: 1

## Apple
size: 12
score: 12
coins: 2

## Orange
size: 15
score: 15
coins: 2

## Coconut
size: 22
score: 20
coins: 3

## Watermelon
size: 35
score: 30
coins: 4

## Football
size: 45
score: 40
coins: 5

## Traffic Cone
size: 55
score: 50
coins: 6

## Bin
size: 70
score: 70
coins: 8

## Shopping Trolley
size: 90
score: 90
coins: 10

## Car
size: 120
score: 150
coins: 20

## Bus
size: 180
score: 250
coins: 30

These values must be configurable.

---

# 9. Crushing Objects

When the hand collides with an object that is smaller than or equal to the hand:

1. object compresses/squashes
2. short impact animation
3. score appears
4. coins may appear
5. object disappears
6. hand gets a very small size increase

Suggested:

sizeGain = objectSize * 0.05

Example:

crushing a size 20 object gives +1 hand size

This should be configurable.

---

# 10. Oversized Collision

If hand size is smaller than the object:

- briefly shake screen
- hand flashes
- run ends

Show:

"TOO SMALL"

Then:

Final score
Distance
Largest hand size
Coins earned

Buttons:

RETRY

Fake rewarded option:

WATCH AD — CONTINUE WITH +25% HAND SIZE

For prototype this should immediately continue.

No real ad SDK.

---

# 11. Gates

Add simple gates that the player can steer through.

Examples:

+10 SIZE
+25 SIZE
×1.5 SIZE
−10 SIZE
÷2 SIZE

Positive gates should feel exciting.

Negative gates should be avoidable where possible.

Gate data:

- type
- amount
- label
- visual style

Initial gate types:

ADD
MULTIPLY
SUBTRACT

No complicated formulas yet.

---

# 12. Level Structure

For MVP use an endless procedural track.

Objects and gates spawn ahead of the player.

Difficulty increases gradually with distance.

Early:
small fruit

Middle:
larger objects

Later:
ridiculous objects such as bins, trolleys, cars, buses

Object spawn difficulty should roughly track expected player hand size.

Do not create handcrafted levels yet.

---

# 13. Track

Visual structure:

- simple forward lane
- three approximate horizontal lanes
- endless scrolling background
- perspective illusion optional

Do NOT build full 3D.

A 2D top-down / pseudo-3D perspective is enough.

The player should feel like they are moving forward even if technically objects move downward toward the player.

---

# 14. Progression

At the end of a run, coins are retained.

Coins can purchase simple permanent upgrades.

Initial upgrades:

## Bigger Start
Start each run with +5 size per level.

## Faster Growth
Increase size gained from crushed objects.

## Coin Magnet
Increase coin collection radius.

## Lucky Gates
Increase chance of positive gates.

Maximum 5 levels each.

Use configurable cost scaling.

Suggested:

cost = baseCost * (1.8 ^ currentLevel)

---

# 15. Score

Score should come from:

- objects crushed
- distance travelled
- size reached

Suggested:

score =
objectScore
+ distanceScore
+ finalSizeBonus

Keep formula simple and configurable.

Track:

- current score
- best score
- maximum hand size
- longest distance

---

# 16. Rewarded Ad Hooks

Do NOT integrate real ads.

Create:

RewardedAdService.showRewardedAd(callback)

For prototype it immediately succeeds.

Rewarded placements:

## Continue Run
After dying:

"Watch Ad — Continue with +25% size"

## Double Coins
After run:

"Watch Ad — Double Coins"

## Giant Hand Boost
Before run:

"Watch Ad — Start 50% Bigger"

Only placeholder/simulated behaviour.

---

# 17. UI

Portrait layout.

During run show:

Top left:
Score

Top right:
Coins

Near hand:
Hand Size

Optional:
distance

Keep HUD minimal.

Start screen:

BIG HAND

PLAY
UPGRADES

Run over screen:

TOO SMALL

Score
Distance
Max Hand Size
Coins

RETRY
DOUBLE COINS
UPGRADES

---

# 18. Visual Style

Visual target:

- bright
- simple
- chunky
- arcade-like
- slightly absurd
- very readable
- satisfying squash/stretch

Avoid:
- realistic hand anatomy
- detailed environments
- complex lighting
- lots of visual clutter

The player should always immediately understand:
- their hand
- dangerous objects
- growth gates

---

# 19. Animation Priorities

Spend effort on:

1. hand growth
2. object squash/crush
3. collision feedback
4. gate effects
5. score popups

Do not spend significant time on background animation.

Use simple tweening.

---

# 20. Sound

Optional placeholders only.

Events:

- crush
- hand growth
- gate
- oversized collision
- coins
- high score

Do not spend significant development time sourcing audio.

---

# 21. Saving

Use localStorage.

Persist:

- coins
- upgrades
- best score
- max hand size
- longest distance
- total runs

No cloud save.

---

# 22. Analytics

No external analytics.

Create:

trackEvent(name, properties)

For now console.log.

Track:

game_started
object_crushed
player_died
gate_used
run_completed
upgrade_bought
rewarded_continue_used
rewarded_double_coins_used

---

# 23. Suggested Structure

src/
  game/
    gameState.ts
    config.ts
    objects.ts
    gates.ts
    progression.ts
    collision.ts
  services/
    saveService.ts
    adService.ts
    analyticsService.ts
  rendering/
  ui/
  assets/

Avoid:

- Redux
- ECS frameworks
- physics engines unless genuinely necessary
- backend
- unnecessary dependencies
- elaborate abstractions

---

# 24. Important Product Principle

The player should understand the game within 3 seconds:

"Big hand crushes small things. Bigger hand crushes bigger things."

The entertainment should come from escalating absurdity.

Example progression:

Cherry
↓
Apple
↓
Watermelon
↓
Football
↓
Bin
↓
Shopping trolley
↓
Car
↓
Bus

The hand growing into something stupidly huge is the reward.

---

# 25. Definition of MVP Complete

MVP is complete when:

- game launches
- hand moves left/right
- world scrolls toward player
- objects spawn
- smaller objects can be crushed
- oversized objects end the run
- hand visibly grows
- gates modify size
- score works
- coins work
- upgrades work
- progress saves
- simulated rewarded ads work
- game is comfortable at portrait phone dimensions
- no major build/runtime errors

Stop once these requirements are met.

Do not add additional gameplay systems without asking.