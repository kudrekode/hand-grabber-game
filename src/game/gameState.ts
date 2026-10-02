import { CONFIG } from './config';
import type { ObjectDefinition } from './objects';
import type { GateDefinition } from './gates';
export interface Entity { id:number; x:number; y:number; kind:'object'|'gate'|'coin'; object?:ObjectDefinition; gate?:GateDefinition; value?:number; row:number; hit?:boolean; age?:number }
export interface Player { x:number; targetX:number; size:number; health:number; score:number; coins:number; baseCoins:number; speed:number; distance:number; elapsed:number; maxSize:number; objectScore:number }
export const createPlayer = (size:number):Player => ({x:210,targetX:210,size,health:CONFIG.health,score:0,coins:0,baseCoins:0,speed:CONFIG.speed,distance:0,elapsed:0,maxSize:size,objectScore:0});
export const calculateScore = (p:Player) => Math.floor(p.objectScore + p.distance * CONFIG.distanceScore + p.maxSize * CONFIG.sizeScore);
