#!/usr/bin/env python3
"""Regenerate authored icon, bundled synthesized audio, and native metadata; standard library only."""
from pathlib import Path
import hashlib, json, math, struct, wave, zlib, plistlib
root=Path(__file__).resolve().parent.parent
info={ 'CFBundleDisplayName':'Big Hand', 'CFBundleExecutable':'$(EXECUTABLE_NAME)', 'CFBundleIdentifier':'$(PRODUCT_BUNDLE_IDENTIFIER)', 'CFBundleName':'$(PRODUCT_NAME)', 'CFBundlePackageType':'APPL', 'CFBundleShortVersionString':'$(MARKETING_VERSION)', 'CFBundleVersion':'$(CURRENT_PROJECT_VERSION)', 'LSRequiresIPhoneOS':True, 'UILaunchScreen':{'UIColorName':'LaunchBackground'}, 'UISupportedInterfaceOrientations':['UIInterfaceOrientationPortrait'], 'UIApplicationSceneManifest':{'UIApplicationSupportsMultipleScenes':False,'UISceneConfigurations':{}}, 'UIApplicationSupportsIndirectInputEvents':True, 'UIRequiredDeviceCapabilities':['arm64'] }
(root/'Resources/Info.plist').write_bytes(plistlib.dumps(info))
privacy={'NSPrivacyTracking':False, 'NSPrivacyCollectedDataTypes':[], 'NSPrivacyAccessedAPITypes':[{'NSPrivacyAccessedAPIType':'NSPrivacyAccessedAPICategoryUserDefaults', 'NSPrivacyAccessedAPITypeReasons':['CA92.1']}]}
(root/'Resources/PrivacyInfo.xcprivacy').write_bytes(plistlib.dumps(privacy))
assets=root/'Resources/Assets.xcassets'
(assets/'Contents.json').write_text(json.dumps({'info':{'author':'xcode','version':1}},indent=2))
(assets/'LaunchBackground.colorset').mkdir(exist_ok=True)
(assets/'LaunchBackground.colorset/Contents.json').write_text(json.dumps({'colors':[{'idiom':'universal','color':{'color-space':'srgb','components':{'red':'0.925','green':'0.898','blue':'0.824','alpha':'1.000'}}}], 'info':{'author':'xcode','version':1}},indent=2))
# Original icon: a chunky cartoon hand, drawn with analytic shapes. No external image assets.
N=1024
ink=(37,49,50); paper=(255,247,231); skin=(255,196,119); purple=(128,101,212); lime=(198,244,94)
shapes=[]
def rounded(x,y,w,h,r,c):shapes.append(('rect',x,y,w,h,r,c))
def ellipse(x,y,rx,ry,c):shapes.append(('ellipse',x,y,rx,ry,0,c))
rounded(0,0,N,N,0,lime)
rounded(436,661,152,222,42,ink);rounded(446,671,132,202,34,skin)
rounded(397,793,230,105,24,ink);rounded(407,803,210,85,17,purple)
for x,y,w,h in [(315,337,91,291),(410,253,91,352),(505,210,91,395),(600,300,91,315)]:
 rounded(x,y,w,h,44,ink);rounded(x+9,y+9,w-18,h-18,35,skin)
 rounded(x+22,y+24,w-44,55,16,paper)
ellipse(701,577,79,126,ink);ellipse(701,577,69,116,skin)
rounded(312,465,390,284,104,ink);rounded(322,475,370,264,95,skin)
for x in (439,566):
 ellipse(x,557,31,34,ink);ellipse(x,554,25,28,paper);ellipse(x+1,560,12,16,ink)
ellipse(505,633,42,27,ink);ellipse(505,620,45,25,skin)
ellipse(378,624,21,11,(235,128,107));ellipse(645,624,21,11,(235,128,107))
def contains(s,x,y):
 kind,a,b,w,h,r,c=s
 if kind=='ellipse':return ((x-a)/w)**2+((y-b)/h)**2<=1
 if x<a or x>a+w or y<b or y>b+h:return False
 cx=max(a+r,min(a+w-r,x));cy=max(b+r,min(b+h-r,y))
 return (x-cx)**2+(y-cy)**2 <= r*r if r else True
rows=[]
for y in range(N):
 row=bytearray([0])
 for x in range(N):
  color=lime
  for s in reversed(shapes):
   if contains(s,x+.5,y+.5):color=s[-1];break
  row.extend(color)
 rows.append(row)
def chunk(t,data):return struct.pack('>I',len(data))+t+data+struct.pack('>I',zlib.crc32(t+data)&0xffffffff)
png=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',N,N,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(b''.join(rows),9))+chunk(b'IEND',b'')
(assets/'AppIcon.appiconset/AppIcon.png').write_bytes(png)
(assets/'AppIcon.appiconset/Contents.json').write_text(json.dumps({'images':[{'filename':'AppIcon.png','idiom':'universal','platform':'ios','size':'1024x1024'}], 'info':{'author':'xcode','version':1}},indent=2))
sounds=root/'Resources/Sounds';sounds.mkdir(exist_ok=True)
cues={'crush':(620,210,.09),'largeCrush':(100,28,.28),'gate':(480,960,.24),'shrink':(330,110,.22),'coin':(1100,1850,.10),'fail':(130,28,.36),'upgrade':(650,980,.16),'highScore':(520,1040,.48)}
for name,(start,end,duration) in cues.items():
 rate=22050;count=int(rate*duration);phase=0;samples=[]
 for i in range(count):
  t=i/count;phase+=2*math.pi*(start+(end-start)*t)/rate
  envelope=min(1,t*40)*(1-t)**2
  value=(math.sin(phase)*.55+math.sin(phase*2)*.12)*envelope
  samples.append(struct.pack('<h',int(value*20000)))
 with wave.open(str(sounds/(name+'.wav')),'wb') as out:
  out.setnchannels(1);out.setsampwidth(2);out.setframerate(rate);out.writeframes(b''.join(samples))
