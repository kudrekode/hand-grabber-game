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
ink=(37,49,50); paper=(255,247,231); skin=(255,196,119); purple=(55,91,85); lime=(198,244,94)
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
# Palm folds replace the prototype face and match the in-game hand.
for x,y in [(390,553),(420,567),(450,577),(480,581),(510,580),(540,576),(570,568),(600,559)]:
 ellipse(x,y,18,7,(220,138,86))
for x,y in [(614,588),(608,604),(601,620),(593,636),(584,649)]:
 ellipse(x,y,7,12,(220,138,86))
rounded(353,485,24,151,12,(255,225,174))
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
# Audio lives in its own generator so art / metadata are not rewritten for a sound pass.
import runpy
runpy.run_path(str(root / 'Scripts/generate-sounds.py'))
