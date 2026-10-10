#!/usr/bin/env python3
"""Reproduce the original v0.6 woodland effects without external assets."""
from pathlib import Path
import math,random,struct,wave
root=Path(__file__).resolve().parents[1]/'assets'/'audio';root.mkdir(parents=True,exist_ok=True);rng=random.Random(66);rate=22050
spec={'grass':(.14,[170],.18),'wood':(.17,[190,370],.10),'stone':(.18,[740,1180],.04),'glow':(.7,[523,659,784,1047],.005),'pickup':(.55,[659,784,1047],.005),'reveal':(.8,[392,587,784],.007),'repair':(.65,[150,300],.12),'web':(.35,[870,1220],.02),'startle':(.28,[300,210],.02),'victory':(1.25,[523,659,784,1047,1319],.003),'musicbox':(1.8,[523,659,784,659,587,523],.002),'rune-0':(.65,[392,784],.002),'rune-1':(.65,[523,1046],.002),'rune-2':(.65,[659,1318],.002),'voice-ara':(.14,[420,500],.003),'voice-ira':(.19,[640,800],.003),'voice-pip':(.21,[370,450],.003),'voice-bramble':(.14,[270,390],.008),'voice-moss':(.19,[310,440],.003)}
for name,(duration,freqs,noise) in spec.items():
 samples=[]
 for i in range(int(rate*duration)):
  t=i/rate;v=0
  for j,f in enumerate(freqs):
   delay=j*duration*.65/len(freqs) if name not in ['grass','wood','stone','repair'] else 0
   age=t-delay
   if age>=0:
    env=(1-math.exp(-age*160))*math.exp(-age*(8 if duration<.3 else 5))
    v+=math.sin(2*math.pi*f*age+(.2*math.sin(age*22) if 'voice' in name else 0))*env*.19/len(freqs)
  v+=rng.uniform(-1,1)*noise*math.exp(-t*30)
  v*=min(1,(duration-t)*90)
  samples.append(max(-32767,min(32767,int(v*32767))))
 with wave.open(str(root/(name+'.wav')),'wb') as w:w.setparams((1,2,rate,0,'NONE','not compressed'));w.writeframes(struct.pack('<'+'h'*len(samples),*samples))
# Continuous gentle water with a seamless crossfade, layered filtered noise.
samples=[];slow=0;fast=0
for i in range(rate*3):
 n=rng.uniform(-1,1);slow=slow*.985+n*.015;fast=fast*.63+n*.37
 samples.append((fast*.13+slow*.65)*(0.8+math.sin(i/rate*2.7)*.12))
fade=rate//5
for i in range(fade):
 a=i/fade;samples[i]=samples[i]*a+samples[-fade+i]*(1-a)
with wave.open(str(root/'water.wav'),'wb') as w:w.setparams((1,2,rate,0,'NONE','not compressed'));w.writeframes(struct.pack('<'+'h'*len(samples),*[int(v*32767) for v in samples]))
# A quiet woodland bed: filtered leaf air and two distant bird phrases.
samples=[];air=0.0;duration=5.0
for i in range(int(rate*duration)):
 t=i/rate;air=air*.96+rng.uniform(-1,1)*.04
 v=air*.13
 for onset in [1.1,3.2]:
  age=t-onset
  if 0<age<.3:
   v+=math.sin(2*math.pi*(1450*age+380*age*age))*math.sin(age/.3*math.pi)**2*.018
 envelope=min(1,t/.1,(duration-t)/.1)
 samples.append(int(max(-1,min(1,v*envelope))*32767))
with wave.open(str(root/'woodland.wav'),'wb') as w:
 w.setparams((1,2,rate,0,'NONE','not compressed'))
 w.writeframes(struct.pack('<'+'h'*len(samples),*samples))
print('Created',len(list(root.glob('*.wav'))),'original sound effects')
