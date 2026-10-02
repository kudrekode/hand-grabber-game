import './style.css';
import { CONFIG, handScale, sizeName } from './game/config';
import { OBJECTS } from './game/objects';
import { applyGate, pickGate } from './game/gates';
import { UPGRADES, upgradeCost, getUpgradeEffects, upgradeEffectLabel, nextUpgrade, type UpgradeId } from './game/progression';
import { createPlayer, calculateScore, type Entity } from './game/gameState';
import { loadSave, writeSave } from './services/saveService';
import { RewardedAdService } from './services/adService';
import { trackEvent } from './services/analyticsService';
import { handBounds, objectBounds, objectContact, visualHandScale, impactStrength, crushDuration } from './game/collision';
import { soundService } from './services/soundService';
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
const handY=650,contactY=handY-35;
let previousSafeLanes=[1],impactAge=1,impactWeight=0,hitStop=0,nearPulse=0,nearCooldown=0;
let failedEntity:Entity|undefined,failedHandSize=0,newBest=false;
interface Ring {x:number;y:number;age:number;weight:number;color:string}
let rings:Ring[]=[];
interface Particle {x:number;y:number;vx:number;vy:number;life:number;max:number;color:string;r:number;shape:'chip'|'drop';rotation:number}
interface Popup {x:number;y:number;text:string;color:string;life:number}
let particles:Particle[]=[],popups:Popup[]=[];
document.querySelector('#sound')!.addEventListener('click',()=>{
  soundService.enabled=!soundService.enabled;soundService.unlock();
  document.querySelector('#sound')!.textContent=soundService.enabled?'SOUND ON':'SOUND OFF';soundService.coin();
});
function burst(x:number,y:number,color:string,count=12,shape:'chip'|'drop'='chip',weight=1) {
  for(let i=0;i<count;i++) {
    const angle=Math.random()*Math.PI*2,speed=(45+Math.random()*135)*weight,life=.3+Math.random()*.25;
    particles.push({x,y,vx:Math.cos(angle)*speed,vy:Math.sin(angle)*speed-40,life,max:life,color,r:2+Math.random()*5*weight,shape,rotation:angle});
  }
}
function popup(x:number,y:number,text:string,color='#253132'){popups.push({x,y,text,color,life:1});}
function panel(html:string){overlay.innerHTML=`<section class="panel">${html}</section>`;}
function bind(action:string,fn:()=>void){document.querySelector(`[data-action="${action}"]`)?.addEventListener('click',fn);}
function home(){mode='home';hud.innerHTML='';panel(`<p class="eyebrow">SMALL THINGS. BIG PROBLEMS.</p><h1>BIG<br>HAND<span style="color:#ff8768">.</span></h1><div class="badge">CRUSH. GROW. GO AGAIN.</div><p class="rule">Drag to crush things smaller than your hand.<br>Green gates make you bigger. Red means danger.</p><button class="action primary" data-action="play">LET’S CRUSH →</button><button class="action reward" data-action="boost">${boost?'✓ NEXT RUN: 50% BIGGER':'WATCH AD · START 50% BIGGER'}</button><button class="action" data-action="upgrades">UPGRADES · ${save.coins} COINS</button><p class="fine">Best ${save.bestScore.toLocaleString()} · Largest ${Math.floor(save.maxHandSize)} · ${Math.floor(save.longestDistance)} m<br>Drag anywhere · mouse / ← → / A D<br>Rewarded ads are simulated.</p>`);bind('play',start);bind('boost',()=>RewardedAdService.showRewardedAd(()=>{boost=true;home();}));bind('upgrades',()=>{upgradeReturn='home';upgrades();});}
function start(){mode='playing';runEffects=getUpgradeEffects(save.upgrades);player=createPlayer(runEffects.startingSize*(boost?CONFIG.boostMultiplier:1));boost=false;entities=[];particles=[];popups=[];row=0;spawnTimer=.35;world=0;pulse=0;flash=0;shake=0;displayedScale=visualHandScale(player.size);previousSafeLanes=[1];impactAge=1;hitStop=0;nearPulse=0;nearCooldown=0;rings=[];failedEntity=undefined;newBest=false;soundService.unlock();continued=false;doubled=false;banked=0;previousStage=-1;stageTimer=0;overlay.innerHTML='';trackEvent('game_started',{size:player.size});updateHud();}
function updateHud(){hud.innerHTML=`<div class="hud-item"><small>SCORE</small><strong>${player.score.toLocaleString()}</strong></div><div class="hud-item"><small>COINS ×${runEffects.coinMultiplier.toFixed(1)}</small><strong><span style="color:#b78020">●</span> ${player.coins}</strong><span class="hud-distance">${Math.floor(player.distance)} m</span></div>`;}
function saveRecords(){save.bestScore=Math.max(save.bestScore,player.score);save.maxHandSize=Math.max(save.maxHandSize,player.maxSize);save.longestDistance=Math.max(save.longestDistance,player.distance);writeSave(save);}
function bankRun(){save.coins+=(player.coins-banked)*(doubled?2:1);banked=player.coins;saveRecords();}
function die(entity:Entity) {
  mode='dead';player.health=0;player.score=calculateScore(player);
  entity.failed=true;entity.hit=true;entity.age=0;failedEntity=entity;failedHandSize=player.size;
  newBest=player.score>save.bestScore;shake=17;flash=.22;deathTimer=.72;impactAge=0;impactWeight=1.65;
  burst(entity.x,entity.y,'#fff5ba',20,'chip',1.25);rings.push({x:entity.x,y:entity.y,age:0,weight:1.8,color:'#e34f4f'});
  soundService.fail();if(newBest)soundService.highScore();bankRun();if(!continued)save.totalRuns++;writeSave(save);
  trackEvent('player_died',{object:entity.object?.id,size:player.size,distance:player.distance});
  trackEvent('run_completed',{score:player.score,coins:player.coins});
}
function deathPanel(){panel(`<p class="eyebrow">${newBest?'NEW BEST SCORE!':`${sizeName(player.maxSize)} HAND. BIG AMBITIONS.`}</p><h2>TOO SMALL<span style="color:#ed6658">!</span></h2><p class="loss-reason">${failedEntity?.object?.name ?? 'Object'} needed <strong>${failedEntity?.object?.size ?? 0}</strong> · Your hand <strong>${failedHandSize.toFixed(1)}</strong></p><div class="stats"><div><span>FINAL SCORE</span><strong>${player.score.toLocaleString()}</strong></div><div><span>DISTANCE</span><strong>${Math.floor(player.distance)} m</strong></div><div><span>LARGEST HAND</span><strong>${Math.floor(player.maxSize)}</strong></div><div><span>COINS EARNED${doubled?' · DOUBLED':''}</span><strong>${player.coins*(doubled?2:1)}</strong></div></div>${rewardSummary()}<button class="action primary" data-action="retry">RETRY →</button>${!continued?'<button class="action reward" data-action="continue">WATCH AD · CONTINUE WITH +25% SIZE</button>':''}<button class="action reward" data-action="double" ${doubled?'disabled':''}>${doubled?'✓ COINS DOUBLED':'WATCH AD · DOUBLE COINS'}</button><button class="action" data-action="upgrades">UPGRADES · ${save.coins} COINS</button><p class="fine">Best score ${save.bestScore.toLocaleString()} · Rewarded ads are simulated.</p>`);bind('retry',start);bind('continue',()=>RewardedAdService.showRewardedAd(()=>{continued=true;mode='playing';player.health=CONFIG.health;player.size*=CONFIG.continueMultiplier;player.maxSize=Math.max(player.maxSize,player.size);entities=entities.filter(e=>e.y<handY-230);overlay.innerHTML='';pulse=1;flash=.12;shake=0;failedEntity=undefined;impactAge=1;hitStop=0;deathTimer=0;stageNotice='SECOND CHANCE';stageTimer=2;trackEvent('rewarded_continue_used');}));bind('double',()=>RewardedAdService.showRewardedAd(()=>{if(doubled)return;doubled=true;save.coins+=player.coins;writeSave(save);trackEvent('rewarded_double_coins_used',{coins:player.coins});deathPanel();}));bind('upgrades',()=>{upgradeReturn='dead';upgrades();});}
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
  save.coins-=cost;save.upgrades[id]++;writeSave(save);soundService.purchase();
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
function pickRouteLane() {
  // Adjacent lane changes connect every safe choice in the previous row.
  const reachable=[0,1,2].filter(lane=>previousSafeLanes.every(previous=>Math.abs(lane-previous)<=1));
  const preferred=reachable.filter(lane=>!previousSafeLanes.includes(lane));
  const pool=preferred.length&&Math.random()<CONFIG.laneChangeChance?preferred:reachable;
  return pool[Math.floor(Math.random()*pool.length)];
}
function spawnRow() {
  row++;
  const route=pickRouteLane(),others=shuffledLanes().filter(x=>x!==lanes[route]);
  if(row%CONFIG.gateEvery===0) {
    const secondPositive=Math.random()<runEffects.positiveGateChance;
    // The positive gate and empty bypass are adjacent; negative gates never block the route.
    const bypass=[0,1,2].filter(lane=>lane!==route&&Math.abs(lane-route)<=1);
    const empty=bypass[Math.floor(Math.random()*bypass.length)];
    const other=[0,1,2].find(lane=>lane!==route&&lane!==empty)!;
    entities.push({id:id++,x:lanes[route],y:-90,kind:'gate',gate:pickGate(true),row});
    entities.push({id:id++,x:lanes[other],y:-90,kind:'gate',gate:pickGate(secondPositive),row});
    previousSafeLanes=secondPositive?[0,1,2]:[route,empty];
    return;
  }
  const elapsed=player.elapsed,phase=elapsed<CONFIG.openingSeconds?0:elapsed<CONFIG.middleSeconds?1:elapsed<CONFIG.lateSeconds?2:3;
  const maxSize=CONFIG.objectUnlocks.reduce((size,unlock)=>elapsed>=unlock.seconds?unlock.maxSize:size,15);
  const available=OBJECTS.filter(object=>object.size<=maxSize),edible=available.filter(object=>object.size<=player.size),threats=available.filter(object=>object.size>player.size);
  const chance=phase===0?CONFIG.earlyDangerChance:phase===1?CONFIG.middleDangerChance:phase===2?CONFIG.lateDangerChance:1;
  const dangerCount=threats.length&&Math.random()<chance?(Math.random()<CONFIG.doubleDangerChances[phase]?2:1):0;
  const choices=[...others,lanes[route]],count=phase===0?2:3;
  previousSafeLanes=[];
  for(let i=0;i<3;i++) {
    const dangerous=i<dangerCount,pool=dangerous?threats:edible;
    if(!dangerous)previousSafeLanes.push(lanes.indexOf(choices[i]));
    if(i>=count||!pool.length)continue;
    const object=pool[Math.floor(Math.random()*pool.length)];
    entities.push({id:id++,x:choices[i],y:-60,kind:'object',object,row});
  }
}
const keys=new Set<string>();window.addEventListener('keydown',e=>{if(['ArrowLeft','ArrowRight','a','d','A','D'].includes(e.key)){e.preventDefault();keys.add(e.key.toLowerCase());}});window.addEventListener('keyup',e=>keys.delete(e.key.toLowerCase()));window.addEventListener('blur',()=>{keys.clear();dragging=false;});
let dragging=false,lastPointerX=0;
canvas.addEventListener('pointerdown',e=>{if(mode!=='playing')return;dragging=true;lastPointerX=e.clientX;canvas.setPointerCapture(e.pointerId);});canvas.addEventListener('pointermove',e=>{if(!dragging||mode!=='playing')return;const rect=canvas.getBoundingClientRect();player.targetX=Math.max(48,Math.min(372,player.targetX+(e.clientX-lastPointerX)*420/rect.width));lastPointerX=e.clientX;});canvas.addEventListener('pointerup',()=>dragging=false);canvas.addEventListener('pointercancel',()=>dragging=false);
function update(dt:number) {
  pulse=Math.max(0,pulse-dt*3);shake=Math.max(0,shake-dt*75);flash=Math.max(0,flash-dt);
  stageTimer=Math.max(0,stageTimer-dt);impactAge+=dt;nearPulse=Math.max(0,nearPulse-dt*4);nearCooldown=Math.max(0,nearCooldown-dt);
  displayedScale+=(visualHandScale(player.size)-displayedScale)*(1-Math.exp(-dt*9));
  for(const particle of particles){particle.life-=dt;particle.x+=particle.vx*dt;particle.y+=particle.vy*dt;particle.vy+=420*dt;particle.rotation+=dt*6;}
  particles=particles.filter(particle=>particle.life>0);
  for(const popup of popups){popup.life-=dt;popup.y-=dt*38;}popups=popups.filter(popup=>popup.life>0);
  for(const ring of rings)ring.age+=dt;rings=rings.filter(ring=>ring.age<.3);
  for(const entity of entities)if(entity.hit)entity.age=(entity.age||0)+dt;
  if(mode==='dead'&&deathTimer>0){deathTimer-=dt;if(deathTimer<=0)deathPanel();}
  if(mode!=='playing')return;
  if(keys.has('arrowleft')||keys.has('a'))player.targetX-=dt*CONFIG.steeringSpeed*runEffects.handlingMultiplier;
  if(keys.has('arrowright')||keys.has('d'))player.targetX+=dt*CONFIG.steeringSpeed*runEffects.handlingMultiplier;
  player.targetX=Math.max(48,Math.min(372,player.targetX));
  player.x+=(player.targetX-player.x)*(1-Math.exp(-dt*CONFIG.steeringResponse*runEffects.handlingMultiplier));
  player.elapsed+=dt;
  player.speed=Math.min(CONFIG.maxSpeed,CONFIG.speed+Math.max(0,player.elapsed-CONFIG.speedRampDelay)*CONFIG.speedRamp);
  // Brief impact pauses leave steering responsive and make heavy objects feel weighty.
  if(hitStop>0){hitStop-=dt;updateHud();return;}
  const travel=player.speed*dt;world+=travel;player.distance+=travel*CONFIG.distanceScale;
  const phase=player.elapsed<CONFIG.openingSeconds?0:player.elapsed<CONFIG.middleSeconds?1:player.elapsed<CONFIG.lateSeconds?2:3;
  if(phase!==previousStage){previousStage=phase;stageNotice=['WARM UP · GET SQUISHING','KEEP MOVING','NO EASY LANES','HOLD ON!'][phase];stageTimer=1.8;}
  spawnTimer-=dt;
  if(spawnTimer<=0){spawnRow();spawnTimer+=Math.max(CONFIG.minRowInterval,CONFIG.rowInterval-Math.max(0,player.elapsed-CONFIG.rowRampDelay)*CONFIG.rowIntervalRamp);}
  for(const entity of entities) {
    if(entity.hit)continue;
    const oldY=entity.y;entity.y+=travel;
    if(entity.kind==='coin') {
      if(Math.hypot(entity.x-player.x,entity.y-(handY-20))<CONFIG.coinCollectionRadius) {
        const before=player.coins;player.baseCoins+=entity.value||1;player.coins=Math.floor(player.baseCoins*runEffects.coinMultiplier+1e-9);
        popup(entity.x,entity.y-18,`+${player.coins-before} COINS`,'#996500');
        entity.hit=true;entity.age=1;burst(entity.x,entity.y,'#ffcd52',4,'drop',.6);soundService.coin();
      }
      continue;
    }
    const dx=entity.x-player.x,dy=entity.y-contactY;
    const contact=entity.kind==='gate'?Math.abs(dx)<52+handBounds(player.size).x&&Math.abs(dy)<18+handBounds(player.size).y:objectContact(dx,dy,player.size,entity.object!);
    if(contact) {
      if(entity.kind==='gate') {
        entity.hit=true;entities.filter(other=>other.kind==='gate'&&other.row===entity.row).forEach(other=>other.hit=true);
        player.size=applyGate(player.size,entity.gate!);player.maxSize=Math.max(player.maxSize,player.size);pulse=1;
        popup(player.x,contactY-130,entity.gate!.label,entity.gate!.positive?'#237c55':'#c44849');
        burst(player.x,contactY,entity.gate!.positive?'#b9eb66':'#ff9a7c',12,'chip',.85);soundService.gate(entity.gate!.positive);
        trackEvent('gate_used',{label:entity.gate!.label,size:player.size});
      } else if(player.size>=entity.object!.size) {
        const object=entity.object!,weight=impactStrength(object.size);
        entity.hit=true;entity.age=0;player.objectScore+=object.scoreValue;
        const growth=object.size*CONFIG.sizeGain*runEffects.growthMultiplier;player.size+=growth;player.maxSize=Math.max(player.maxSize,player.size);
        popup(entity.x,entity.y-85,`+${growth.toFixed(2)} SIZE`,'#237c55');
        popup(entity.x,entity.y-55,`+${object.scoreValue} ${object.size<70?'SQUISH!':'CRUNCH!'}`);
        entities.push({id:id++,x:entity.x,y:handY-110,kind:'coin',value:object.coinValue,row:entity.row});
        impactAge=0;impactWeight=weight;hitStop=object.size<22?.012:object.size<70?.028:object.size<180?.045:.075;
        shake=Math.max(shake,object.size<22?0:object.size<70?1.4+weight*2:object.size<180?3+weight*3:9+Math.min(2,weight));
        const fruit=object.category==='fruit';
        burst(entity.x,entity.y,object.visual==='watermelon'?'#65bf82':object.color,Math.round(5+weight*13),fruit?'drop':'chip',weight);
        if(object.size>=22)rings.push({x:entity.x,y:entity.y,age:0,weight,color:fruit?'#71a774':'#546377'});
        soundService.crush(object.size);trackEvent('object_crushed',{object:object.id});
      } else {die(entity);break;}
    } else if(entity.kind==='object'&&!entity.nearMiss&&entity.object!.size>player.size) {
      const boundary=contactY+handBounds(player.size).y+objectBounds(entity.object!).y;
      if(oldY<=boundary&&entity.y>boundary) {
        entity.nearMiss=true;
        const separation=Math.abs(dx)-handBounds(player.size).x-objectBounds(entity.object!).x;
        if(separation>=0&&separation<20&&nearCooldown<=0){nearPulse=.7;nearCooldown=.5;soundService.whoosh();}
      }
    }
  }
  entities=entities.filter(entity=>entity.failed||entity.y<900&&(!entity.hit||entity.kind==='object'&&(entity.age||0)<crushDuration(entity.object!.size)));
  player.maxSize=Math.max(player.maxSize,player.size);player.score=calculateScore(player);updateHud();
}
function text(t:string,x:number,y:number,size:number,color='#253132',align:CanvasTextAlign='center'){ctx.fillStyle=color;ctx.font=`900 ${size}px system-ui`;ctx.textAlign=align;ctx.fillText(t,x,y);}
function render(t:number) {
  ctx.save();ctx.clearRect(0,0,420,800);
  if(shake)ctx.translate((Math.random()-.5)*shake,(Math.random()-.5)*shake);
  ctx.fillStyle='#ece5d2';ctx.fillRect(0,0,420,800);ctx.fillStyle='#42485b';ctx.fillRect(0,0,28,800);ctx.fillRect(392,0,28,800);
  ctx.fillStyle='#fff7e7';ctx.fillRect(34,0,352,800);
  ctx.strokeStyle='#ded7c4';ctx.lineWidth=3;ctx.setLineDash([18,25]);ctx.lineDashOffset=-world;
  for(const x of [143,277]){ctx.beginPath();ctx.moveTo(x,0);ctx.lineTo(x,800);ctx.stroke();}ctx.setLineDash([]);
  ctx.fillStyle='#f5bd58';for(let y=(world*.55)%90-90;y<800;y+=90){ctx.fillRect(8,y,12,35);ctx.fillRect(401,y,12,35);}
  if(mode==='home') {
    drawObject(ctx,OBJECTS[0],74,110);drawObject(ctx,OBJECTS[5],350,210);drawObject(ctx,OBJECTS[10],70,520,.8);
    drawHand(ctx,300,665,1.35,0,false,Math.sin(t*2)*3,Math.sin(t*1.5)*.04);
  } else {
    const press=Math.max(0,impactAge<.1?impactAge/.1:1-(impactAge-.1)/.22)*Math.min(1.2,impactWeight);
    const failed=mode==='dead'&&!!failedEntity;
    const recoil=failed?Math.sin(Math.min(1,impactAge/.16)*Math.PI/2)*28*Math.exp(-Math.max(0,impactAge-.12)*4):impactAge>.1&&impactAge<.4?-Math.sin((impactAge-.1)/.3*Math.PI)*impactWeight*6:0;
    if(nearPulse>0){ctx.strokeStyle=`rgba(100,181,205,${nearPulse})`;ctx.lineWidth=3;ctx.beginPath();ctx.ellipse(player.x,contactY,handBounds(player.size).x+8,handBounds(player.size).y+8,0,0,7);ctx.stroke();}
    // Incoming objects draw above the hand so even the largest silhouette cannot hide a threat.
    drawHand(ctx,player.x,contactY,displayedScale,failed?0:press+pulse*.12,flash>0,recoil,failed?-.16*Math.exp(-impactAge*3):Math.max(-.09,Math.min(.09,(player.targetX-player.x)*.003)));
    for(const entity of entities) {
      if(entity.failed)continue;
      if(entity.kind==='gate') {
        if(entity.hit)continue;
        const positive=entity.gate!.positive,background=positive?'#b9ed75':'#ff927d',dark=positive?'#245c43':'#8e333b';
        round(ctx,entity.x-57,entity.y-35,114,72,11,background,dark);
        round(ctx,entity.x-61,entity.y-38,7,85,3,dark);round(ctx,entity.x+54,entity.y-38,7,85,3,dark);
        if(!positive){ctx.save();ctx.beginPath();ctx.rect(entity.x-53,entity.y-31,106,64);ctx.clip();ctx.strokeStyle='#ba4a442c';ctx.lineWidth=5;for(let i=-80;i<90;i+=18){ctx.beginPath();ctx.moveTo(entity.x+i,entity.y-35);ctx.lineTo(entity.x+i+60,entity.y+37);ctx.stroke();}ctx.restore();}
        text(positive?'↑ GROW':'↓ SHRINK',entity.x,entity.y-16,10,dark);
        text(entity.gate!.label.replace(' SIZE',''),entity.x,entity.y+17,30,dark);
      } else if(entity.kind==='coin') {
        if(!entity.hit){circle(ctx,entity.x,entity.y,10,'#ffce59');text('●',entity.x,entity.y+4,11,'#a97320');}
      } else {
        const object=entity.object!,danger=object.size>player.size,age=entity.age||0,duration=crushDuration(object.size);
        if(entity.hit)ctx.globalAlpha=Math.min(1,Math.max(0,(duration-age)/.1));
        if(!entity.hit){ctx.fillStyle=danger?'#ed6e5524':'#83c27116';ctx.beginPath();ctx.ellipse(entity.x,entity.y+8,objectRadius(object)+7,objectRadius(object)+6,0,0,7);ctx.fill();}
        const squash=entity.hit?Math.min(.96,age/.13):0;
        drawObject(ctx,object,entity.x,entity.y+age*12,1,squash);ctx.globalAlpha=1;
        if(!entity.hit) {
          const label=`${danger?'! ':''}${object.size}`;ctx.font='900 16px system-ui';const width=ctx.measureText(label).width+20;
          round(ctx,entity.x-width/2,entity.y-objectRadius(object)-33,width,27,8,danger?'#f66d5c':'#d1eea9');
          text(label,entity.x,entity.y-objectRadius(object)-14,16,danger?'#fff9e8':'#253132');
          text(object.name.toUpperCase(),entity.x,entity.y+objectRadius(object)+20,9,danger?'#a6403e':'#697669');
        }
      }
    }
    if(failedEntity&&failed) {
      const object=failedEntity.object!;
      ctx.fillStyle='#e95e4b24';ctx.beginPath();ctx.ellipse(failedEntity.x,failedEntity.y,objectRadius(object)+15,objectRadius(object)+15,0,0,7);ctx.fill();
      drawObject(ctx,object,failedEntity.x,failedEntity.y,1.08);
      round(ctx,64,352,292,69,13,'#ed6b59');text('TOO SMALL!',210,381,26,'#fff9e9');
      text(`${object.name.toUpperCase()} ${object.size} > HAND ${failedHandSize.toFixed(1)}`,210,403,12,'#fff9e9');
    }
    const badgeX=Math.max(61,Math.min(359,player.x));
    round(ctx,badgeX-54,handY+103,108,47,12,'#28303b');text(`SIZE ${Math.floor(player.size)}`,badgeX,handY+122,16,'#fff9e9');text(sizeName(player.size),badgeX,handY+140,10,'#c6f45e');
    if(stageTimer>0&&mode==='playing'){ctx.globalAlpha=Math.min(1,stageTimer);round(ctx,68,111,284,33,11,'#28303b');text(stageNotice,210,133,13,'#fff8e8');ctx.globalAlpha=1;}
  }
  for(const ring of rings) {
    ctx.globalAlpha=(1-ring.age/.3)*.5;ctx.strokeStyle=ring.color;ctx.lineWidth=3*(1-ring.age/.3);
    ctx.beginPath();ctx.ellipse(ring.x,ring.y,12+ring.age*140*ring.weight,6+ring.age*70*ring.weight,0,0,7);ctx.stroke();
  }
  for(const particle of particles) {
    ctx.globalAlpha=particle.life/particle.max;ctx.save();ctx.translate(particle.x,particle.y);ctx.rotate(particle.rotation);ctx.fillStyle=particle.color;
    if(particle.shape==='drop'){ctx.beginPath();ctx.ellipse(0,0,particle.r*.7,particle.r,0,0,7);ctx.fill();}else ctx.fillRect(-particle.r/2,-particle.r/2,particle.r,particle.r*.6);
    ctx.restore();
  }
  ctx.globalAlpha=1;
  for(const popup of popups) {
    ctx.globalAlpha=Math.min(1,popup.life*2);ctx.font='900 15px system-ui';ctx.textAlign='center';ctx.lineWidth=4;ctx.strokeStyle='#fff9eb';
    const x=Math.max(ctx.measureText(popup.text).width/2+8,Math.min(412-ctx.measureText(popup.text).width/2,popup.x));
    ctx.strokeText(popup.text,x,popup.y);text(popup.text,x,popup.y,15,popup.color);
  }
  ctx.globalAlpha=1;
  if(flash>0&&mode==='dead'){ctx.fillStyle=`rgba(255,239,174,${Math.min(.27,flash*1.3)})`;ctx.fillRect(0,0,420,800);}
  ctx.restore();
}
function resize(){const dpr=Math.min(window.devicePixelRatio||1,2);canvas.width=420*dpr;canvas.height=800*dpr;ctx.setTransform(dpr,0,0,dpr,0,0);}
window.addEventListener('resize',resize);resize();home();let last=0;
function loop(ms:number){const dt=Math.min(.033,last?(ms-last)/1000:0);last=ms;update(dt);render(ms/1000);requestAnimationFrame(loop);}requestAnimationFrame(loop);
