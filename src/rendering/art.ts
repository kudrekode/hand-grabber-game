import type { ObjectDefinition } from '../game/objects';
const ink='#253132';
export function round(ctx:CanvasRenderingContext2D,x:number,y:number,w:number,h:number,r:number,fill:string,stroke=ink) {
  ctx.beginPath();ctx.roundRect(x,y,w,h,r);ctx.fillStyle=fill;ctx.fill();if(stroke){ctx.strokeStyle=stroke;ctx.lineWidth=3;ctx.stroke();}
}
export function circle(ctx:CanvasRenderingContext2D,x:number,y:number,r:number,fill:string) {
  ctx.beginPath();ctx.arc(x,y,r,0,Math.PI*2);ctx.fillStyle=fill;ctx.fill();ctx.strokeStyle=ink;ctx.lineWidth=2.5;ctx.stroke();
}
export function drawHand(ctx:CanvasRenderingContext2D,x:number,y:number,scale:number,pulse:number,flash:boolean) {
  ctx.save();ctx.translate(x,y);ctx.scale(scale*(1+pulse*.13),scale*(1-pulse*.1));
  ctx.fillStyle='#20272a22';ctx.beginPath();ctx.ellipse(0,27,51,18,0,0,Math.PI*2);ctx.fill();
  const color=flash?'#fff5ec':'#ffbda3';
  round(ctx,-24,21,48,72,10,color);
  // Chunky fingers and palm form a single, intentionally silly silhouette.
  ctx.beginPath();ctx.moveTo(-35,25);ctx.quadraticCurveTo(-48,7,-43,-8);
  ctx.lineTo(-44,-53);ctx.quadraticCurveTo(-44,-69,-33,-69);ctx.quadraticCurveTo(-23,-69,-23,-55);
  ctx.lineTo(-23,-76);ctx.quadraticCurveTo(-23,-92,-12,-92);ctx.quadraticCurveTo(-1,-92,-1,-76);
  ctx.lineTo(-1,-85);ctx.quadraticCurveTo(-1,-102,11,-102);ctx.quadraticCurveTo(23,-102,23,-85);
  ctx.lineTo(23,-67);ctx.quadraticCurveTo(23,-81,34,-81);ctx.quadraticCurveTo(45,-81,45,-64);
  ctx.lineTo(45,-19);ctx.lineTo(54,-36);ctx.quadraticCurveTo(62,-49,73,-39);ctx.quadraticCurveTo(82,-33,72,-16);
  ctx.lineTo(53,20);ctx.quadraticCurveTo(43,39,21,42);ctx.lineTo(-14,42);ctx.quadraticCurveTo(-30,38,-35,25);
  ctx.closePath();ctx.fillStyle=color;ctx.fill();ctx.strokeStyle=ink;ctx.lineWidth=3;ctx.stroke();
  ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(-23,-53);ctx.lineTo(-23,-27);ctx.moveTo(-1,-66);ctx.lineTo(-1,-28);ctx.moveTo(23,-57);ctx.lineTo(23,-25);ctx.moveTo(-16,12);ctx.quadraticCurveTo(4,-4,29,4);ctx.stroke();
  for (const [nx,ny] of [[-39,-59],[-18,-81],[4,-91],[28,-70]]) round(ctx,nx,ny,11,13,5,'#ffe0cb','');
  round(ctx,-27,66,54,15,4,'#aa9cf0');ctx.restore();
}
export function objectRadius(o:ObjectDefinition) { return 18+Math.sqrt(o.size)*2.15; }
export function drawObject(ctx:CanvasRenderingContext2D,o:ObjectDefinition,x:number,y:number,scale=1,squash=0) {
  const r=objectRadius(o);ctx.save();ctx.translate(x,y);ctx.scale(scale*(1+squash*.65),scale*(1-squash*.8));
  ctx.fillStyle='#20272a18';ctx.beginPath();ctx.ellipse(0,r*.9,r*.95,8,0,0,Math.PI*2);ctx.fill();
  const leaf=()=>{ctx.strokeStyle=ink;ctx.lineWidth=3;ctx.beginPath();ctx.moveTo(0,-r*.55);ctx.lineTo(4,-r*1.1);ctx.stroke();ctx.fillStyle='#5cba7d';ctx.beginPath();ctx.ellipse(12,-r*.95,10,5,-.4,0,Math.PI*2);ctx.fill();ctx.stroke();};
  switch(o.visual){
    case 'cherry':
      ctx.strokeStyle='#527754';ctx.lineWidth=3;ctx.beginPath();ctx.moveTo(-10,0);ctx.lineTo(3,-30);ctx.lineTo(15,3);ctx.stroke();circle(ctx,-11,8,13,o.color);circle(ctx,13,11,14,o.color);break;
    case 'strawberry':
      ctx.beginPath();ctx.moveTo(-r,-r*.5);ctx.bezierCurveTo(-r*1.2,r*.1,-8,r,0,r);ctx.bezierCurveTo(8,r,r*1.2,0,r,-r*.5);ctx.quadraticCurveTo(0,-r*1.2,-r,-r*.5);ctx.fillStyle=o.color;ctx.fill();ctx.strokeStyle=ink;ctx.stroke();leaf();ctx.fillStyle='#ffecad';for(let i=0;i<7;i++){ctx.beginPath();ctx.ellipse((i%3-1)*11,Math.floor(i/3)*12-7,2,3,0,0,7);ctx.fill();}break;
    case 'apple':case 'orange':case 'coconut':case 'watermelon':case 'football':
      circle(ctx,0,0,r,o.color);
      if(o.visual==='apple'||o.visual==='orange')leaf();
      if(o.visual==='watermelon'){ctx.strokeStyle='#31975d';ctx.lineWidth=5;for(const a of [-.5,0,.5]){ctx.beginPath();ctx.ellipse(a*r,0,r*.22,r*.85,0,-1.5,1.5);ctx.stroke();}}
      if(o.visual==='coconut'){ctx.fillStyle='#513f32';for(const a of [-8,0,8]){ctx.beginPath();ctx.arc(a,-6+Math.abs(a),3,0,7);ctx.fill();}}
      if(o.visual==='football'){ctx.fillStyle=ink;ctx.beginPath();for(let i=0;i<5;i++){const a=i*Math.PI*2/5-Math.PI/2;ctx.lineTo(Math.cos(a)*r*.4,Math.sin(a)*r*.4);}ctx.closePath();ctx.fill();ctx.lineWidth=2;for(let i=0;i<5;i++){const a=i*Math.PI*2/5-Math.PI/2;ctx.beginPath();ctx.moveTo(Math.cos(a)*r*.4,Math.sin(a)*r*.4);ctx.lineTo(Math.cos(a)*r,Math.sin(a)*r);ctx.stroke();}}break;
    case 'cone':
      round(ctx,-r,-r*.1,r*2,r,5,o.color);ctx.beginPath();ctx.moveTo(-r*.8,r*.45);ctx.lineTo(-5,-r);ctx.quadraticCurveTo(0,-r-6,5,-r);ctx.lineTo(r*.8,r*.45);ctx.closePath();ctx.fillStyle=o.color;ctx.fill();ctx.stroke();ctx.fillStyle='#fff8e8';ctx.beginPath();ctx.moveTo(-r*.48,0);ctx.lineTo(-r*.28,-r*.4);ctx.lineTo(r*.28,-r*.4);ctx.lineTo(r*.48,0);ctx.fill();break;
    case 'bin':
      round(ctx,-r*.7,-r*.75,r*1.4,r*1.65,7,o.color);round(ctx,-r*.83,-r*.9,r*1.66,11,4,'#567e71');ctx.strokeStyle='#52786b';for(const a of [-.35,0,.35]){ctx.beginPath();ctx.moveTo(r*a,-r*.4);ctx.lineTo(r*a,r*.6);ctx.stroke();}circle(ctx,-r*.5,r*.9,5,ink);circle(ctx,r*.5,r*.9,5,ink);break;
    case 'trolley':
      round(ctx,-r*.85,-r*.6,r*1.55,r*1.15,4,o.color);ctx.strokeStyle=ink;ctx.lineWidth=2;for(let i=0;i<4;i++){ctx.beginPath();ctx.moveTo(-r*.6+i*r*.33,-r*.6);ctx.lineTo(-r*.6+i*r*.33,r*.5);ctx.stroke();}ctx.beginPath();ctx.moveTo(-r,-r*.95);ctx.lineTo(-r*.85,-r*.95);ctx.lineTo(-r*.7,r*.75);ctx.lineTo(r*.7,r*.75);ctx.stroke();circle(ctx,-r*.5,r*.85,7,ink);circle(ctx,r*.5,r*.85,7,ink);break;
    case 'car':case 'bus':{
      const h=o.visual==='bus'?r*2:r*1.55;round(ctx,-r*.82,-h/2,r*1.64,h,12,o.color);round(ctx,-r*.64,-h*.33,r*1.28,h*.32,6,'#456d7b');round(ctx,-r*.64,h*.18,r*1.28,h*.15,4,'#456d7b');for(const a of [-1,1]){round(ctx,a<0?-r*.96:r*.72,-h*.3,r*.24,h*.23,3,ink);round(ctx,a<0?-r*.96:r*.72,h*.24,r*.24,h*.23,3,ink);round(ctx,a<0?-r*.62:r*.32,-h*.48,r*.3,7,2,'#fff2b9','');}break;}
  }
  ctx.restore();
}
