import test from 'node:test';
import assert from 'node:assert/strict';
import { CONFIG } from '../src/game/config';
import { availableObjects } from '../src/game/objects';
import { objectRadius, objectContact } from '../src/game/collision';
import { GATES, applyGate, scaleGate } from '../src/game/gates';
import { getUpgradeEffects, upgradeCost } from '../src/game/progression';
import { loadSave, writeSave } from '../src/services/saveService';

test('late numbers keep growing and giant hands retain useful rewards and threats', () => {
  const peak = (seconds:number) => Math.max(...availableObjects(seconds, 500).map(object => object.size));
  assert.ok(peak(120) > peak(60));
  assert.ok(peak(300) > peak(120));
  assert.ok(peak(43_200) > peak(300));
  assert.ok(availableObjects(43_200, 50_000).every(object => Number.isSafeInteger(object.scoreValue)));
  for (const hand of [500, 50_000, 1_000_000]) {
    const pool = availableObjects(120, hand);
    assert.ok(pool.some(object => object.size > hand));
    assert.ok(pool.some(object => object.size <= hand && object.size >= hand * .35));
    for (const object of pool) {
      assert.ok(objectRadius(object) <= 60);
      assert.equal(objectContact(133, 0, hand, object), false);
      assert.ok(Number.isSafeInteger(object.scoreValue) && object.coinValue > 0);
    }
  }
});

test('opening unlocks remain gentle and gates stay useful at large hand sizes', () => {
  assert.equal(Math.max(...availableObjects(0, 20).map(object => object.size)), 15);
  assert.equal(Math.max(...availableObjects(4, 20).map(object => object.size)), 35);
  const gate = scaleGate(GATES[0], 50_000);
  assert.equal(gate.amount, 6_250);
  assert.equal(applyGate(50_000, gate), 56_250);
  assert.equal(applyGate(1, GATES[3]), 1);
  assert.equal(scaleGate(GATES[2], 50_000), GATES[2]);
});

test('existing purchases keep their effects and have three more levels available', () => {
  const effects = getUpgradeEffects({start:5,growth:5,handling:5,coins:5,luck:5});
  assert.equal(effects.startingSize, 45);
  assert.equal(effects.growthMultiplier, 2.5);
  assert.equal(upgradeCost('start', 0), 75);
  assert.equal(upgradeCost('start', 5), 7_000);
  assert.equal(upgradeCost('start', CONFIG.maxUpgradeLevel), Infinity);
});

test('old saves retain their wallet, records, and levels; new level eight persists', () => {
  let raw = JSON.stringify({coins:1250,bestScore:900,upgrades:{start:5,magnet:2}});
  Object.defineProperty(globalThis, 'localStorage', {value:{getItem:()=>raw,setItem:(_key:string,value:string)=>{raw=value;}}});
  const save = loadSave();
  assert.equal(save.coins, 1250);
  assert.equal(save.bestScore, 900);
  assert.equal(save.upgrades.start, 5);
  assert.equal(save.upgrades.handling, 2);
  save.upgrades.start = 8;
  writeSave(save);
  assert.deepEqual(loadSave(), save);
});
