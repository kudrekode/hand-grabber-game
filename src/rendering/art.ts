import { objectRadius } from '../game/collision';
export { objectRadius } from '../game/collision';
import type { ObjectDefinition } from '../game/objects';
const ink='#253132';
export function round(ctx:CanvasRenderingContext2D,x:number,y:number,w:number,h:number,r:number,fill:string,stroke=ink) {
  ctx.beginPath();ctx.roundRect(x,y,w,h,r);ctx.fillStyle=fill;ctx.fill();if(stroke){ctx.strokeStyle=stroke;ctx.lineWidth=3;ctx.stroke();}
}
export function circle(ctx:CanvasRenderingContext2D,x:number,y:number,r:number,fill:string) {
  ctx.beginPath();ctx.arc(x,y,r,0,Math.PI*2);ctx.fillStyle=fill;ctx.fill();ctx.strokeStyle=ink;ctx.lineWidth=2.5;ctx.stroke();
}
export function drawHand(ctx:CanvasRenderingContext2D,x:number,y:number,scale:number,press:number,flash:boolean,recoil=0,lean=0) {
  ctx.save();ctx.translate(x,y+press*8+recoil);ctx.rotate(lean);
  ctx.scale(scale*(1+press*.1),scale*(1-press*.14));
  ctx.fillStyle='#28313c24';ctx.beginPath();ctx.ellipse(0,23,34,16,0,0,Math.PI*2);ctx.fill();
  const skin=flash?'#fff9de':'#ffc477',shadow=flash?'#ffe9b5':'#f29a58';
  round(ctx,-15,28,30,41,9,skin);round(ctx,-22,47,44,20,6,'#8065d4');
  round(ctx,-20,47,40,7,3,'#bfa8ff','');
  // Four spaced, blunt fingers. They curl visibly toward the palm on contact.
  const fingers=[{x:-36,length:28},{x:-18,length:38},{x:0,length:45},{x:18,length:32}];
  for(const finger of fingers) {
    const length=finger.length*(1-press*.32),tip=-16-length;
    round(ctx,finger.x,tip,17,length+30,9,skin);
    round(ctx,finger.x+4,tip+5,9,10,4,'#ffe9be','');
    ctx.strokeStyle=shadow;ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(finger.x+4,-25);ctx.lineTo(finger.x+11,-25);ctx.stroke();
  }
  // Sideways thumb and a broad palm keep the silhouette unmistakably hand-shaped.
  ctx.save();ctx.translate(31,8);ctx.rotate(-.6+press*.25);round(ctx,-2,-22,24,38,12,skin);round(ctx,3,-18,10,12,4,'#ffe9be','');ctx.restore();
  round(ctx,-35,-15,72,57,23,skin);
  ctx.fillStyle=shadow;ctx.beginPath();ctx.ellipse(-24,12,5,12,-.25,0,7);ctx.fill();
  // A tiny face makes the hand a character, not a cursor.
  for(const eye of [-11,12]) {
    circle(ctx,eye,3,6,flash?'#ffd39a':'#fff8db');
    ctx.fillStyle=ink;ctx.beginPath();ctx.ellipse(eye+lean*10,4,2.6,press>0.65?1:3.1,0,0,7);ctx.fill();
  }
  ctx.strokeStyle=ink;ctx.lineWidth=2.5;ctx.beginPath();ctx.moveTo(-8,18);ctx.quadraticCurveTo(1,press>0.5?17:28,12,18);ctx.stroke();
  ctx.fillStyle='#eb806b';ctx.beginPath();ctx.ellipse(-23,14,4,2,0,0,7);ctx.ellipse(26,14,4,2,0,0,7);ctx.fill();
  ctx.restore();
}
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
