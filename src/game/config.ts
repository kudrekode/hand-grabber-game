// All game balance values live here. Distances are metres, time is seconds.
export const CONFIG = {
  width: 420, height: 800, startSize: 20, health: 1,
  speed: 280, speedRamp: 14, speedRampDelay: 3, maxSpeed: 760, distanceScale: 0.045,
  sizeGain: 0.015, steeringSpeed: 380, steeringResponse: 24, coinCollectionRadius: 64,
  distanceScore: 2, sizeScore: 3,
  gateEvery: 6, rowInterval: 1.25, minRowInterval: 0.72, rowRampDelay: 3, rowIntervalRamp: 0.02,
  positiveGateChance: 0.1,
  // Opening objects unlock by run time; late values also follow hand growth.
  openingSeconds: 6, middleSeconds: 18, lateSeconds: 35,
  earlyDangerChance: 0.3, middleDangerChance: 0.9, lateDangerChance: 0.98,
  doubleDangerChances: [0, 0.5, 0.85, 0.95],
  laneChangeChance: 0.85,
  objectUnlocks: [
    {seconds:0, maxSize:15}, {seconds:4, maxSize:35},
    {seconds:7, maxSize:70}, {seconds:11, maxSize:180}, {seconds:18, maxSize:360},
  ],
  handStages: [30, 80, 160, 500], handScales: [0.65, 1, 1.35, 1.75, 2.4],
  continueMultiplier: 1.25, boostMultiplier: 1.5,
  maxUpgradeLevel: 8,
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
