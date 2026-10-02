import { CONFIG } from './config';
// Costs are per purchased level; the final three levels deliberately take much longer.
export const UPGRADE_COSTS = [250, 500, 1500, 4500, 13500] as const;
export const UPGRADES = [
  {id:'start',name:'Starting Hand Size',description:'A bigger hand from the first second.',perLevel:5,costs:UPGRADE_COSTS},
  {id:'growth',name:'Crush Growth',description:'More size from every crushed object.',perLevel:0.3,costs:UPGRADE_COSTS},
  {id:'handling',name:'Handling',description:'Faster steering with touch, mouse and keys.',perLevel:0.15,costs:UPGRADE_COSTS},
  {id:'coins',name:'Coin Multiplier',description:'More coins from every collected reward.',perLevel:0.2,costs:UPGRADE_COSTS},
  {id:'luck',name:'Lucky Gates',description:'Fewer negative gates in each gate pair.',perLevel:0.05,costs:UPGRADE_COSTS},
] as const;
export type UpgradeId = typeof UPGRADES[number]['id'];
export type UpgradeLevels = Record<UpgradeId,number>;
export const upgradeCost = (id:UpgradeId, level:number) => UPGRADES.find(upgrade=>upgrade.id===id)!.costs[level] ?? Infinity;
const perLevel = (id:UpgradeId) => UPGRADES.find(upgrade=>upgrade.id===id)!.perLevel;
export function getUpgradeEffects(levels:UpgradeLevels) {
  return {
    startingSize: CONFIG.startSize+levels.start*perLevel('start'),
    growthMultiplier: 1+levels.growth*perLevel('growth'),
    handlingMultiplier: 1+levels.handling*perLevel('handling'),
    coinMultiplier: 1+levels.coins*perLevel('coins'),
    positiveGateChance: CONFIG.positiveGateChance+levels.luck*perLevel('luck'),
  };
}
export function upgradeEffectLabel(id:UpgradeId,level:number) {
  const amount=level*perLevel(id);
  switch(id) {
    case 'start':return `Start size ${CONFIG.startSize+amount}`;
    case 'growth':return `Crush growth ${Math.round((1+amount)*100)}%`;
    case 'handling':return `Steering ${Math.round((1+amount)*100)}%`;
    case 'coins':return `Coins ×${(1+amount).toFixed(1)}`;
    case 'luck':return `Second green gate ${Math.round((CONFIG.positiveGateChance+amount)*1000)/10}%`;
  }
}
export function nextUpgrade(levels:UpgradeLevels,coins:number) {
  const candidates=UPGRADES.filter(upgrade=>levels[upgrade.id]<CONFIG.maxUpgradeLevel)
    .map(upgrade=>({upgrade,cost:upgradeCost(upgrade.id,levels[upgrade.id])})).sort((a,b)=>a.cost-b.cost);
  return candidates.find(candidate=>candidate.cost<=coins) ?? candidates[0];
}
