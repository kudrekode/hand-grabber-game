import { CONFIG } from '../game/config';
import type { UpgradeId } from '../game/progression';
export interface SaveData { coins:number; upgrades:Record<UpgradeId,number>; bestScore:number; maxHandSize:number; longestDistance:number; totalRuns:number }
const initial = ():SaveData => ({coins:0,upgrades:{start:0,growth:0,handling:0,coins:0,luck:0},bestScore:0,maxHandSize:20,longestDistance:0,totalRuns:0});
export function loadSave():SaveData {
  const fallback=initial();
  try {
    const data=JSON.parse(localStorage.getItem('big-hand-save-v1')||'null');
    if (!data || typeof data!=='object') return fallback;
    for (const key of ['coins','bestScore','maxHandSize','longestDistance','totalRuns'] as const) {
      if(Number.isFinite(data[key]) && data[key]>=0) fallback[key]=key==='coins'||key==='bestScore'||key==='totalRuns'?Math.floor(data[key]):data[key];
    }
    for(const key of ['start','growth','handling','coins','luck'] as const) {
      // Preserve earlier Coin Magnet purchases as Handling levels.
      const level=data.upgrades?.[key] ?? (key==='handling'?data.upgrades?.magnet:undefined);
      if(Number.isFinite(level)) fallback.upgrades[key]=Math.max(0,Math.min(CONFIG.maxUpgradeLevel,Math.floor(level)));
    }
  } catch { /* Storage may be unavailable in private browser modes. */ }
  return fallback;
}
export function writeSave(save:SaveData) { try {localStorage.setItem('big-hand-save-v1',JSON.stringify(save));} catch { /* Keep playing with in-memory progress. */ } }
