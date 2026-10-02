import './style.css';
import { CONFIG, handScale, sizeName } from './game/config';
import { OBJECTS } from './game/objects';
import { applyGate, pickGate } from './game/gates';
import { UPGRADES, upgradeCost, getUpgradeEffects, upgradeEffectLabel, nextUpgrade, type UpgradeId } from './game/progression';
import { createPlayer, calculateScore, type Entity } from './game/gameState';
import { loadSave, writeSave } from './services/saveService';
import { RewardedAdService } from './services/adService';
import { trackEvent } from './services/analyticsService';
import { drawHand, drawObject, objectRadius, round, circle } from './rendering/art';

const canvas=document.querySelector<HTMLCanvasElement>('#game')!;
const ctx=canvas.getContext('2d')!;
const overlay=document.querySelector<HTMLDivElement>('#overlay')!;
const hud=document.querySelector<HTMLDivElement>('#hud')!;
const save=loadSave();
// Purchases apply to the next new run, including when the current run is continued.
let runEffects=getUpgradeEffects(save.upgrades);
let mode:'home'|'playing'|'dead'|'upgrades'='home';
let player=createPlayer(CONFIG.startSize), entities:Entity[]=[], id=0, row=0, spawnTimer=.5;
let pulse=0, shake=0, flash=0, world=0, displayedScale=1, deathTimer=0, boost=false, continued=false, doubled=false, banked=0;
let upgradeReturn:'home'|'dead'='home';
let stageNotice='', stageTimer=0, previousStage=-1;
const lanes=[77,210,343];
const handY=650;
interface Particle {x:number;y:number;vx:number;vy:number;life:number;max:number;color:string;r:number}
interface Popup {x:number;y:number;text:string;color:string;life:number}
let particles:Particle[]=[],popups:Popup[]=[];
let audio:AudioContext|undefined, sound=false;
function tone(f:number,d=.08,type:OscillatorType='sine',volume=.04){if(!sound)return;try{audio??=new AudioContext();void audio.resume();const o=audio.createOscillator(),g=audio.createGain();o.type=type;o.frequency.setValueAtTime(f,audio.currentTime);o.frequency.exponentialRampToValueAtTime(f*.5,audio.currentTime+d);g.gain.setValueAtTime(volume,audio.currentTime);g.gain.exponentialRampToValueAtTime(.001,audio.currentTime+d);o.connect(g);g.connect(audio.destination);o.start();o.stop(audio.currentTime+d);}catch{}}
document.querySelector('#sound')!.addEventListener('click',()=>{sound=!sound;document.querySelector('#sound')!.textContent=sound?'SOUND ON':'SOUND OFF';tone(500);});
function burst(x:number,y:number,color:string,count=12){for(let i=0;i<count;i++){const a=Math.random()*Math.PI*2,s=50+Math.random()*160;particles.push({x,y,vx:Math.cos(a)*s,vy:Math.sin(a)*s,life:.55,max:.55,color,r:3+Math.random()*5});}}
function popup(x:number,y:number,text:string,color='#253132'){popups.push({x,y,text,color,life:1});}
function panel(html:string){overlay.innerHTML=`<section class="panel">${html}</section>`;}
function bind(action:string,fn:()=>void){document.querySelector(`[data-action="${action}"]`)?.addEventListener('click',fn);}
function home(){mode='home';hud.innerHTML='';panel(`<p class="eyebrow">SMALL THINGS. BIG PROBLEMS.</p><h1>BIG<br>HAND<span style="color:#ff8768">.</span></h1><div class="badge">CRUSH. GROW. GO AGAIN.</div><p class="rule">Drag to crush things smaller than your hand.<br>Green gates make you bigger. Red means danger.</p><button class="action primary" data-action="play">LET’S CRUSH →</button><button class="action reward" data-action="boost">${boost?'✓ NEXT RUN: 50% BIGGER':'WATCH AD · START 50% BIGGER'}</button><button class="action" data-action="upgrades">UPGRADES · ${save.coins} COINS</button><p class="fine">Best ${save.bestScore.toLocaleString()} · Largest ${Math.floor(save.maxHandSize)} · ${Math.floor(save.longestDistance)} m<br>Drag anywhere · mouse / ← → / A D<br>Rewarded ads are simulated.</p>`);bind('play',start);bind('boost',()=>RewardedAdService.showRewardedAd(()=>{boost=true;home();}));bind('upgrades',()=>{upgradeReturn='home';upgrades();});}
function start(){mode='playing';runEffects=getUpgradeEffects(save.upgrades);player=createPlayer(runEffects.startingSize*(boost?CONFIG.boostMultiplier:1));boost=false;entities=[];particles=[];popups=[];row=0;spawnTimer=.35;world=0;pulse=0;flash=0;shake=0;displayedScale=handScale(player.size);continued=false;doubled=false;banked=0;previousStage=-1;stageTimer=0;overlay.innerHTML='';trackEvent('game_started',{size:player.size});updateHud();}
function updateHud(){hud.innerHTML=`<div class="hud-item"><small>SCORE</small><strong>${player.score.toLocaleString()}</strong></div><div class="hud-item"><small>COINS ×${runEffects.coinMultiplier.toFixed(1)} · ${Math.floor(player.distance)} m</small><strong><span style="color:#b78020">●</span> ${player.coins}</strong></div>`;}
function saveRecords(){save.bestScore=Math.max(save.bestScore,player.score);save.maxHandSize=Math.max(save.maxHandSize,player.maxSize);save.longestDistance=Math.max(save.longestDistance,player.distance);writeSave(save);}
function bankRun(){save.coins+=(player.coins-banked)*(doubled?2:1);banked=player.coins;saveRecords();}
function die(e:Entity){mode='dead';player.health=0;player.score=calculateScore(player);shake=18;flash=.65;deathTimer=.65;burst(player.x,handY-40,'#ff6459',22);popup(player.x,handY-150,'TOO SMALL!','#d84545');tone(95,.35,'sawtooth');bankRun();if(!continued)save.totalRuns++;writeSave(save);trackEvent('player_died',{object:e.object?.id,size:player.size,distance:player.distance});trackEvent('run_completed',{score:player.score,coins:player.coins});}
function deathPanel(){panel(`<p class="eyebrow">${sizeName(player.maxSize)} HAND. BIG AMBITIONS.</p><h2>TOO SMALL<span style="color:#ed6658">!</span></h2><div class="stats"><div><span>FINAL SCORE</span><strong>${player.score.toLocaleString()}</strong></div><div><span>DISTANCE</span><strong>${Math.floor(player.distance)} m</strong></div><div><span>LARGEST HAND</span><strong>${Math.floor(player.maxSize)}</strong></div><div><span>COINS EARNED${doubled?' · DOUBLED':''}</span><strong>${player.coins*(doubled?2:1)}</strong></div></div>${rewardSummary()}<button class="action primary" data-action="retry">RETRY →</button>${!continued?'<button class="action reward" data-action="continue">WATCH AD · CONTINUE WITH +25% SIZE</button>':''}<button class="action reward" data-action="double" ${doubled?'disabled':''}>${doubled?'✓ COINS DOUBLED':'WATCH AD · DOUBLE COINS'}</button><button class="action" data-action="upgrades">UPGRADES · ${save.coins} COINS</button><p class="fine">Best score ${save.bestScore.toLocaleString()} · Rewarded ads are simulated.</p>`);bind('retry',start);bind('continue',()=>RewardedAdService.showRewardedAd(()=>{continued=true;mode='playing';player.health=CONFIG.health;player.size*=CONFIG.continueMultiplier;player.maxSize=Math.max(player.maxSize,player.size);entities=entities.filter(e=>e.y<handY-230);overlay.innerHTML='';pulse=1;flash=.25;stageNotice='SECOND CHANCE';stageTimer=2;trackEvent('rewarded_continue_used');}));bind('double',()=>RewardedAdService.showRewardedAd(()=>{if(doubled)return;doubled=true;save.coins+=player.coins;writeSave(save);trackEvent('rewarded_double_coins_used',{coins:player.coins});deathPanel();}));bind('upgrades',()=>{upgradeReturn='dead';upgrades();});}
function rewardSummary() {
  const next=nextUpgrade(save.upgrades,save.coins);
  const detail=!next?'ALL UPGRADES MAXED':next.cost<=save.coins
    ? `AFFORDABLE NOW · ${next.upgrade.name} L${save.upgrades[next.upgrade.id]+1} · ${next.cost} ●`
    : `NEXT · ${next.upgrade.name} · ${next.cost-save.coins} more coins needed`;
  return `<div class="reward-summary"><span>TOTAL COINS</span><strong>● ${save.coins.toLocaleString()}</strong><p>${detail}</p></div>`;
}
function upgrades() {
  mode='upgrades';
  panel(`<p class="eyebrow">MAKE EVERY RUN COUNT.</p><h2>UPGRADE SHOP</h2><p><strong>● ${save.coins.toLocaleString()} total coins</strong><br><small>Permanent · Apply to your next new run</small></p>${UPGRADES.map(upgrade=>{
    const level=save.upgrades[upgrade.id],cost=upgradeCost(upgrade.id,level),maxed=level>=CONFIG.maxUpgradeLevel;
    const effect=upgradeEffectLabel(upgrade.id,level);
    const next=maxed?'MAX LEVEL':upgradeEffectLabel(upgrade.id,level+1);
    return `<div class="upgrade"><div><strong>${upgrade.name}</strong><small>${upgrade.description}</small><small class="effect">${effect}${maxed?'':` → ${next}`}</small><small>${'●'.repeat(level)}${'○'.repeat(CONFIG.maxUpgradeLevel-level)} · Level ${level}/5</small></div><button data-action="${upgrade.id}" aria-label="${maxed?`${upgrade.name} maxed`:`Buy ${upgrade.name} level ${level+1} for ${cost} coins`}" ${maxed||save.coins<cost?'disabled':''}>${maxed?'MAX':`BUY<br>${cost.toLocaleString()} ●`}</button></div>`;
  }).join('')}<button class="action primary" data-action="back">BACK →</button>`);
  for(const upgrade of UPGRADES)bind(upgrade.id,()=>buy(upgrade.id));
  bind('back',()=>{if(upgradeReturn==='home')home();else{mode='dead';deathPanel();}});
}
function buy(id:UpgradeId) {
  const level=save.upgrades[id],cost=upgradeCost(id,level);
  if(level>=CONFIG.maxUpgradeLevel||save.coins<cost)return;
  save.coins-=cost;save.upgrades[id]++;writeSave(save);tone(650,.16);
  trackEvent('upgrade_bought',{id,level:level+1,cost});upgrades();
}
// Fisher–Yates keeps lane choices uniform; the last lane is always a safe route.
function shuffledLanes() {
  const result=[...lanes];
  for (let i=result.length-1;i>0;i--) {
    const j=Math.floor(Math.random()*(i+1));
    [result[i],result[j]]=[result[j],result[i]];
  }
  return result;
}
function spawnRow() {
  row++;
  const choices=shuffledLanes();
  if (row%CONFIG.gateEvery===0) {
    // One positive gate, usually one negative, and always one empty bypass lane.
    for (let i=0;i<2;i++) {
      const positive=i===0 || Math.random()<runEffects.positiveGateChance;
      entities.push({id:id++,x:choices[i],y:-90,kind:'gate',gate:pickGate(positive),row});
    }
    return;
  }
  const elapsed=player.elapsed;
  const maxSize=CONFIG.objectUnlocks.reduce((size,unlock)=>elapsed>=unlock.seconds?unlock.maxSize:size,15);
  const available=OBJECTS.filter(object=>object.size<=maxSize);
  const edible=available.filter(object=>object.size<=player.size);
  const threats=available.filter(object=>object.size>player.size);
  const dangerChance=elapsed<CONFIG.openingSeconds?CONFIG.earlyDangerChance:
    elapsed<CONFIG.middleSeconds?CONFIG.middleDangerChance:CONFIG.lateDangerChance;
  // Two occupied lanes early. Late rows usually contain two dangers and a small reward.
  const dangerCount=threats.length && Math.random()<dangerChance
    ? (elapsed>=CONFIG.lateSeconds && Math.random()<CONFIG.secondDangerChance?2:1) : 0;
  const count=elapsed>=CONFIG.middleSeconds?3:2;
  for(let i=0;i<count;i++) {
    const pool=i<dangerCount?threats:edible;
    // If a downgrade leaves no crushable fruit, leave the remaining lanes empty.
    if(!pool.length)continue;
    const object=pool[Math.floor(Math.random()*pool.length)];
    entities.push({id:id++,x:choices[i],y:-60,kind:'object',object,row});
  }
}
const keys=new Set<string>();window.addEventListener('keydown',e=>{if(['ArrowLeft','ArrowRight','a','d','A','D'].includes(e.key)){e.preventDefault();keys.add(e.key.toLowerCase());}});window.addEventListener('keyup',e=>keys.delete(e.key.toLowerCase()));window.addEventListener('blur',()=>{keys.clear();dragging=false;});
let dragging=false,lastPointerX=0;
canvas.addEventListener('pointerdown',e=>{if(mode!=='playing')return;dragging=true;lastPointerX=e.clientX;canvas.setPointerCapture(e.pointerId);});canvas.addEventListener('pointermove',e=>{if(!dragging||mode!=='playing')return;const rect=canvas.getBoundingClientRect();player.targetX=Math.max(48,Math.min(372,player.targetX+(e.clientX-lastPointerX)*420/rect.width));lastPointerX=e.clientX;});canvas.addEventListener('pointerup',()=>dragging=false);canvas.addEventListener('pointercancel',()=>dragging=false);
function update(dt:number){pulse=Math.max(0,pulse-dt*3);shake=Math.max(0,shake-dt*32);flash=Math.max(0,flash-dt);stageTimer=Math.max(0,stageTimer-dt);displayedScale+=(handScale(player.size)-displayedScale)*(1-Math.exp(-dt*9));for(const p of particles){p.life-=dt;p.x+=p.vx*dt;p.y+=p.vy*dt;p.vy+=400*dt;}particles=particles.filter(p=>p.life>0);for(const p of popups){p.life-=dt;p.y-=dt*45;}popups=popups.filter(p=>p.life>0);
  if(mode==='dead'&&deathTimer>0){deathTimer-=dt;if(deathTimer<=0)deathPanel();}
  if(mode!=='playing')return;
  if(keys.has('arrowleft')||keys.has('a'))player.targetX-=dt*CONFIG.steeringSpeed*runEffects.handlingMultiplier;if(keys.has('arrowright')||keys.has('d'))player.targetX+=dt*CONFIG.steeringSpeed*runEffects.handlingMultiplier;player.targetX=Math.max(48,Math.min(372,player.targetX));player.x+=(player.targetX-player.x)*(1-Math.exp(-dt*CONFIG.steeringResponse*runEffects.handlingMultiplier));
  player.elapsed+=dt;player.speed=Math.min(CONFIG.maxSpeed,CONFIG.speed+Math.max(0,player.elapsed-CONFIG.speedRampDelay)*CONFIG.speedRamp);const travel=player.speed*dt;world+=travel;player.distance+=travel*CONFIG.distanceScale;
  const stage=player.elapsed<CONFIG.openingSeconds?0:player.elapsed<CONFIG.middleSeconds?1:player.elapsed<CONFIG.lateSeconds?2:3;if(stage!==previousStage){previousStage=stage;stageNotice=['FRUIT SQUISHING','LET’S PLAY BIG','STREET CRUSHER','ABSOLUTELY ABSURD'][stage];stageTimer=2.3;}
  spawnTimer-=dt;if(spawnTimer<=0){spawnRow();spawnTimer+=Math.max(CONFIG.minRowInterval,CONFIG.rowInterval-Math.max(0,player.elapsed-CONFIG.rowRampDelay)*CONFIG.rowIntervalRamp);}
  for(const e of entities){if(e.hit){e.age=(e.age||0)+dt;continue;}e.y+=travel;
    if(e.kind==='coin'){if(Math.hypot(e.x-player.x,e.y-(handY-20))<CONFIG.coinCollectionRadius){const before=player.coins;player.baseCoins+=e.value||1;player.coins=Math.floor(player.baseCoins*runEffects.coinMultiplier+1e-9);popup(Math.max(50,Math.min(370,e.x)),e.y-20,`+${player.coins-before} COINS`,'#9c6b10');e.hit=true;e.age=1;burst(e.x,e.y,'#ffcd52',6);tone(800,.04);}continue;}
    const rx=e.kind==='gate'?52:Math.min(43,objectRadius(e.object!)*.75);const ry=e.kind==='gate'?18:objectRadius(e.object!)*.7;
    if(Math.abs(e.x-player.x)<rx+20 && Math.abs(e.y-(handY-35))<ry+25){
      if(e.kind==='gate'){e.hit=true;entities.filter(other=>other.kind==='gate'&&other.row===e.row).forEach(other=>other.hit=true);player.size=applyGate(player.size,e.gate!);pulse=1;popup(player.x,handY-170,e.gate!.label,e.gate!.positive?'#237c55':'#c44849');burst(player.x,handY-60,e.gate!.positive?'#b9eb66':'#f2827d',18);tone(e.gate!.positive?640:180,.16);trackEvent('gate_used',{label:e.gate!.label,size:player.size});}
      else if(player.size>=e.object!.size){e.hit=true;e.age=0;player.objectScore+=e.object!.scoreValue;const growth=e.object!.size*CONFIG.sizeGain*runEffects.growthMultiplier;player.size+=growth;popup(Math.max(65,Math.min(355,e.x)),e.y-90,`+${growth.toFixed(2)} SIZE`,'#237c55');entities.push({id:id++,x:e.x,y:handY-110,kind:'coin',value:e.object!.coinValue,row:e.row});pulse=.65;shake=2;popup(e.x,e.y-65,`+${e.object!.scoreValue}  SQUISH!`);burst(e.x,e.y,e.object!.color);tone(150+e.object!.size*2,.07,'triangle',.07);trackEvent('object_crushed',{object:e.object!.id});}
      else{e.hit=true;die(e);break;}
    }
  }
  entities=entities.filter(e=>e.y<900 && (!e.hit||(e.kind==='object'&&(e.age||0)<.25)));player.maxSize=Math.max(player.maxSize,player.size);player.score=calculateScore(player);updateHud();
}
function text(t:string,x:number,y:number,size:number,color='#253132',align:CanvasTextAlign='center'){ctx.fillStyle=color;ctx.font=`900 ${size}px system-ui`;ctx.textAlign=align;ctx.fillText(t,x,y);}
function render(t:number){ctx.save();ctx.clearRect(0,0,420,800);if(shake)ctx.translate((Math.random()-.5)*shake,(Math.random()-.5)*shake);ctx.fillStyle='#eee9d9';ctx.fillRect(0,0,420,800);ctx.fillStyle='#d6ddc9';ctx.fillRect(0,0,28,800);ctx.fillRect(392,0,28,800);ctx.fillStyle='#fff7e7';ctx.fillRect(34,0,352,800);
  ctx.strokeStyle='#dfdbc9';ctx.lineWidth=3;ctx.setLineDash([18,25]);ctx.lineDashOffset=-world;for(const x of [143,277]){ctx.beginPath();ctx.moveTo(x,0);ctx.lineTo(x,800);ctx.stroke();}ctx.setLineDash([]);
  ctx.fillStyle='#9cae92';for(let y=(world*.55)%90-90;y<800;y+=90){ctx.fillRect(8,y,12,35);ctx.fillRect(401,y,12,35);}
  if(mode==='home'){drawObject(ctx,OBJECTS[0],74,110);drawObject(ctx,OBJECTS[5],350,210);drawObject(ctx,OBJECTS[10],70,520,.8);drawHand(ctx,300,700,1.5,Math.sin(t*2)*.1,false);}
  else {
    for(const e of entities){if(e.kind==='gate'){if(e.hit)continue;const positive=e.gate!.positive,c=positive?'#ccf58a':'#ffafa0';round(ctx,e.x-56,e.y-25,112,56,9,c);round(ctx,e.x-59,e.y-29,7,70,3,positive?'#578759':'#b95f5a');round(ctx,e.x+52,e.y-29,7,70,3,positive?'#578759':'#b95f5a');text(e.gate!.label,e.x,e.y+8,15);}
      else if(e.kind==='coin'){if(!e.hit){circle(ctx,e.x,e.y,11,'#ffce59');text('●',e.x,e.y+4,12,'#a97320');}}
      else{const o=e.object!,danger=o.size>player.size;if(!e.hit){ctx.fillStyle=danger?'#ee6d5920':'#83c27116';ctx.beginPath();ctx.ellipse(e.x,e.y+9,objectRadius(o)+9,objectRadius(o)+7,0,0,7);ctx.fill();}drawObject(ctx,o,e.x,e.y,1,e.hit?Math.min(1,(e.age||0)/.15):0);if(!e.hit){ctx.font='900 13px system-ui';const label=`${danger?'! ':''}${o.size}`,w=ctx.measureText(label).width+20;round(ctx,e.x-w/2,e.y-objectRadius(o)-30,w,23,8,danger?'#f07463':'#d1eea9');text(label,e.x,e.y-objectRadius(o)-13,13);text(o.name.toUpperCase(),e.x,e.y+objectRadius(o)+21,9,danger?'#b74b43':'#697669');}}
    }
    drawHand(ctx,player.x,handY,displayedScale,pulse,flash>0&&Math.floor(flash*18)%2===0);
    round(ctx,player.x-52,handY+107,104,45,12,'#253132');text(`SIZE ${Math.floor(player.size)}`,player.x,handY+126,16,'#fff9e9');text(sizeName(player.size),player.x,handY+143,10,'#c6f45e');
    if(stageTimer>0){ctx.globalAlpha=Math.min(1,stageTimer);round(ctx,68,115,284,36,12,'#253132');text(stageNotice,210,139,14,'#fff8e8');ctx.globalAlpha=1;}
  }
  for(const p of particles){ctx.globalAlpha=p.life/p.max;ctx.fillStyle=p.color;ctx.fillRect(p.x-p.r/2,p.y-p.r/2,p.r,p.r);}ctx.globalAlpha=1;
  for(const p of popups){ctx.globalAlpha=Math.min(1,p.life*2);text(p.text,p.x,p.y,17,p.color);}ctx.globalAlpha=1;ctx.restore();
}
function resize(){const dpr=Math.min(window.devicePixelRatio||1,2);canvas.width=420*dpr;canvas.height=800*dpr;ctx.setTransform(dpr,0,0,dpr,0,0);}
window.addEventListener('resize',resize);resize();home();let last=0;
function loop(ms:number){const dt=Math.min(.033,last?(ms-last)/1000:0);last=ms;update(dt);render(ms/1000);requestAnimationFrame(loop);}requestAnimationFrame(loop);
