// All game balance values live here. Distances are metres, time is seconds.
export const CONFIG = {
  width: 420, height: 800, startSize: 20, health: 1,
  speed: 210, speedRamp: 4.5, speedRampDelay: 10, maxSpeed: 570, distanceScale: 0.045,
  sizeGain: 0.015, steeringSpeed: 380, steeringResponse: 24, coinCollectionRadius: 64,
  distanceScore: 2, sizeScore: 3,
  gateEvery: 6, rowInterval: 1.6, minRowInterval: 1.08, rowRampDelay: 10, rowIntervalRamp: 0.008,
  positiveGateChance: 0.1,
  // Objects unlock by run time, independent of speed and hand growth.
  openingSeconds: 10, middleSeconds: 30, lateSeconds: 60,
  earlyDangerChance: 0.18, middleDangerChance: 0.85, lateDangerChance: 0.96,
  doubleDangerChances: [0, 0.3, 0.7, 0.9],
  laneChangeChance: 0.85,
  objectUnlocks: [
    {seconds:0, maxSize:15}, {seconds:8, maxSize:35},
    {seconds:12, maxSize:70}, {seconds:16, maxSize:180}, {seconds:24, maxSize:360},
  ],
  handStages: [30, 80, 160, 500], handScales: [0.65, 1, 1.35, 1.75, 2.4],
  continueMultiplier: 1.25, boostMultiplier: 1.5,
  maxUpgradeLevel: 5,
};
export const sizeName = (size: number) => {
  const stage = CONFIG.handStages.findIndex(threshold => size < threshold);
  return ['TINY', 'NORMAL', 'LARGE', 'HUGE', 'ABSURD'][stage < 0 ? 4 : stage];
};
// Smooth visual growth, with each named stage aligned to its scale landmark.
export const handScale = (size: number) => {
  const sizes = [1, ...CONFIG.handStages];
  for (let i=1; i<sizes.length; i++) {
    if (size<sizes[i]) {
      const fraction=Math.max(0,(size-sizes[i-1])/(sizes[i]-sizes[i-1]));
      return CONFIG.handScales[i-1]+fraction*(CONFIG.handScales[i]-CONFIG.handScales[i-1]);
    }
  }
  return CONFIG.handScales[4];
};
