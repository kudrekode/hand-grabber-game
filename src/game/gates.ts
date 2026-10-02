export interface GateDefinition { type: 'ADD'|'MULTIPLY'|'SUBTRACT'; amount: number; label: string; positive: boolean; weight: number }
export const GATES: GateDefinition[] = [
  {type:'ADD',amount:10,label:'+10 SIZE',positive:true,weight:18},
  {type:'ADD',amount:25,label:'+25 SIZE',positive:true,weight:1},
  {type:'MULTIPLY',amount:1.5,label:'×1.5 SIZE',positive:true,weight:1},
  {type:'SUBTRACT',amount:10,label:'−10 SIZE',positive:false,weight:3},
  {type:'MULTIPLY',amount:0.5,label:'÷2 SIZE',positive:false,weight:1},
];
export function applyGate(size:number, gate:GateDefinition) {
  return Math.max(1, gate.type==='ADD' ? size+gate.amount : gate.type==='SUBTRACT' ? size-gate.amount : size*gate.amount);
}

export function pickGate(positive: boolean): GateDefinition {
  const pool=GATES.filter(gate=>gate.positive===positive);
  let roll=Math.random()*pool.reduce((total,gate)=>total+gate.weight,0);
  for (const gate of pool) { roll-=gate.weight; if (roll<0) return gate; }
  return pool[pool.length-1];
}
