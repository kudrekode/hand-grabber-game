import { handScale } from './config';
import type { ObjectDefinition } from './objects';
// Compress visual growth into a phone-readable silhouette, aligned with the palm hit area.
export const visualHandScale = (size:number) => 0.7+(handScale(size)-0.65)*0.63;
export const handBounds = (size:number) => ({x:Math.min(55,33*visualHandScale(size)),y:Math.min(34,23*visualHandScale(size))});
export const objectRadius = (object:ObjectDefinition) => 18+Math.sqrt(object.size)*2.15;
export const objectBounds = (object:ObjectDefinition) => {
  const radius=objectRadius(object);
  return {x:Math.min(48,radius*.78),y:radius*.72};
};
export function objectContact(dx:number,dy:number,size:number,object:ObjectDefinition) {
  const hand=handBounds(size),bounds=objectBounds(object);
  return (dx/(hand.x+bounds.x))**2+(dy/(hand.y+bounds.y))**2<=1;
}
export const impactStrength = (size:number) => Math.min(1.65,0.22+Math.sqrt(size/180));
export const crushDuration = (size:number) => 0.2+Math.min(0.2,size/900);
