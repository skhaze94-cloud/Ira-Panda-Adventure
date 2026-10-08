'use strict';
const $=s=>document.querySelector(s),canvas=$('#world'),ctx=canvas.getContext('2d');
const imgs={};for(const n of ['forest','ara','ira','atlas','decor','level-2','level-3','level-4','level-5','ground-v2','trees-v2','lamps-v2','npc-pip','npc-bramble','npc-moss','woodland-door','woodland-key','key-birches','ara-rig-22','npc-rig-22','support-rig-22']){imgs[n]=new Image();imgs[n].src='assets/'+n+'.webp'}
let state='menu',page=0,W=innerWidth,H=innerHeight,DPR=Math.min(devicePixelRatio||1,2),last=0,time=0,pausedFrom='menu',heart=3,invuln=0,cooldown=0,pulse=0,toastTime=0,target=null,walk=false,face=1;
let levelIndex=0,marks=[],decorations=[],sparkles=[],stageFinished=false;
let sound=false,reduced=false,musicEnabled=true;try{const s=JSON.parse(localStorage.getItem('ara-options')||'{}');sound=!!s.sound;reduced=!!s.reduced;if(typeof s.music==='boolean')musicEnabled=s.music}catch{}document.body.classList.toggle('reduced',reduced);
// Persistent music players preserve playback position across all chapter transitions.
const musicTracks={menu:new Audio('assets/menu-music.mp3'),gameplay:new Audio('assets/gameplay-music.mp3')};
for(const track of Object.values(musicTracks)){track.loop=true;track.preload='auto';track.volume=.45;}
let musicScene='menu',musicUnlocked=false;const musicPending=new Set();
function syncMusic(){
 const wanted=musicTracks[musicScene],allowed=musicEnabled&&musicUnlocked&&!document.hidden;
 for(const track of Object.values(musicTracks))if(track!==wanted||!allowed)track.pause();
 // No load(), source reassignment, or seek: an ongoing gameplay loop stays uninterrupted.
 if(!allowed||!wanted.paused||musicPending.has(wanted))return;
 try{const p=wanted.play();if(p&&typeof p.then==='function'){musicPending.add(wanted);p.catch(()=>{}).finally(()=>musicPending.delete(wanted));}}catch{}
}
function setMusicScene(scene){musicScene=scene;syncMusic()}
function unlockMusic(){musicUnlocked=true;syncMusic()}
addEventListener('pointerdown',unlockMusic,{capture:true});
addEventListener('keydown',unlockMusic,{capture:true});
document.addEventListener('visibilitychange',syncMusic);
const player={x:2,y:3},keys=new Set(),trees=[],bats=[];let audio;
const LANTERN_COOLDOWN=1.15,GLOW_DURATION=1.05;
let lampPosts=[],lanternMotes=[],waypoints=[],waypointSeen=new Set(),treeBuckets=new Map();
const moods=[{moon:'#bce2e0',light:'#ffe0a3',mist:'#7da4a4',treeScale:1.12,density:.48},{moon:'#c3b8fa',light:'#ffe4bd',mist:'#b795d1',treeScale:.96,density:.57},{moon:'#bbebec',light:'#ffe5b3',mist:'#74c7c3',treeScale:1.04,density:.58},{moon:'#c7d5ff',light:'#e8ddff',mist:'#8b9ee2',treeScale:1.23,density:.56},{moon:'#e9e9c7',light:'#ffd297',mist:'#b7c5a0',treeScale:.94,density:.58}];
function tone(f=500,d=.18){if(!sound)return;try{audio??=new(window.AudioContext||window.webkitAudioContext)();audio.resume();let o=audio.createOscillator(),g=audio.createGain();o.type='sine';o.frequency.setValueAtTime(f,audio.currentTime);o.frequency.exponentialRampToValueAtTime(f*.65,audio.currentTime+d);g.gain.setValueAtTime(.05,audio.currentTime);g.gain.exponentialRampToValueAtTime(.001,audio.currentTime+d);o.connect(g);g.connect(audio.destination);o.start();o.stop(audio.currentTime+d)}catch{}}
function resize(){W=innerWidth;H=innerHeight;DPR=Math.min(devicePixelRatio||1,2);canvas.width=W*DPR;canvas.height=H*DPR;ctx.setTransform(DPR,0,0,DPR,0,0)}addEventListener('resize',resize);resize();
function seed(n){let v=Math.sin(n*127.1+311.7)*43758.5453;return v-Math.floor(v)}
const levels=[
{name:'The Whispering Woods',size:65,scene:'forest',task:'key',items:0,theme:['#53635b','#4c5c55','#59665a','#1b393b','#1e3b3b','#213f3c'],tint:'#254b4b',decor:7,bats:2,entry:'“Ira? It’s me. I brought a light.”',caption:'A ribbon, a rustle, and two very nosy bats.',outro:'The brass key turns with a tiny click. Beyond the woodland door, Ira’s ribbon points toward a glow in the trees.',joke:'“Ira, your directions are very… ribbon-y.”'},
{name:'Glowcap Glade',size:39,scene:'level-2',task:'glow',items:3,theme:['#6a5777','#63516e','#716080','#302d4d','#352c4d','#3b3451'],tint:'#50466b',decor:0,bats:2,entry:'“Are these mushrooms night-lights? Excellent.”',caption:'The mushrooms were asleep. Ara had a bright idea.',outro:'Three glowcaps stretch and shine. A trail of little ribbon scraps appears beside the brook.',joke:'“Thank you, mushrooms. Very illuminating.”'},
{name:'Puddlebrook Crossing',size:41,scene:'level-3',task:'collect',items:3,theme:['#7f8580','#737d77','#8b9188','#174f5e','#1e5a64','#226472'],tint:'#255f68',decor:1,bats:2,entry:'“Stepping stones. Not splashing stones. Got it.”',caption:'A brook, a bridge, and a frog with absolutely no advice.',outro:'Ara follows the last scrap across the brook. On the far bank, little stars wink between the branches.',joke:'“My paws are only a little bit soggy. A fashionable amount.”'},
{name:'Stargazer Hollow',size:43,scene:'level-4',task:'glow',items:3,theme:['#505f82','#475574','#5a678d','#1d294d','#233054','#26345b'],tint:'#33487a',decor:6,bats:3,entry:'“Excuse me, stars. Have you seen a pillow?”',caption:'Even the stars needed someone to leave a light on.',outro:'The sleepy lanterns blink awake. Beyond them, Ara spots a tiny cottage and a very familiar pink bow.',joke:'“Aha! Unless the cottage is wearing Ira’s bow…”'},
{name:'Pillowmoon Garden',size:45,scene:'level-5',task:'glow',items:2,theme:['#847866','#7a705e','#8e8370','#365348','#3a5a4d','#416254'],tint:'#5c6953',decor:4,bats:1,entry:'“Ira! Is that you? Please don’t be another cushion.”',caption:'Home was never very far from a sister’s hug.',outro:'Ira had followed a butterfly, lost her way, and waited beside the warm little cottage.',joke:'“I was hiding,” said Ira. “Just… a bit too successfully.”'}
];
function current(){return levels[levelIndex]}
function curve(x){return Math.sin(x*(.45+levelIndex*.025)+levelIndex*.6)*(1.3+levelIndex*.18)}
function pathY(x){return x+curve(x)}
function exitPoint(){return {x:current().size-3,y:pathY(current().size-3)}}
function buildLevel(){
 const l=current(),m=moods[levelIndex];trees.length=0;decorations.length=0;marks=[];sparkles=[];lampPosts=[];lanternMotes=[];waypoints=[];waypointSeen.clear();treeBuckets.clear();stageFinished=false;
 for(let i=0;i<l.items;i++){let x=6+i*(l.size-12)/Math.max(1,l.items-1);marks.push({x,y:pathY(x),lit:false,index:i})}
 const exit=exitPoint();
 for(let x=0;x<l.size;x++)for(let y=0;y<l.size;y++){
  const tx=x+.2+seed(x+y*36+levelIndex)*.25,ty=y+.2+seed(x*7+y+levelIndex)*.25,d=Math.abs(ty-pathY(tx));
  if(keyClearing(tx,ty))continue;
  // A continuous generous clear corridor keeps the longer trails traversable.
  const clearing=levelIndex===1?Math.sin(tx*.34)>.45:levelIndex===4?Math.sin(tx*.28)>.4:false;
  if(d>(clearing?4.8:3.4)&&seed(x*29+y+levelIndex*71)>m.density&&Math.hypot(tx-exit.x,ty-exit.y)>2.5){
   if(levelIndex===4&&(x%3===1||y%3===1))continue;
   if(levelIndex===3&&d<6&&Math.sin(tx*.4)>.65)continue;
   let type=Math.floor(seed(x+y*14+levelIndex*21)*3);if(levelIndex===2)type=d<5?2:ty>pathY(tx)?0:1;if(levelIndex===4)type=(Math.floor(x/3)+Math.floor(y/3))%3;
   const t={x:tx,y:ty,type,size:(.78+seed(x*39+y)*.45)*m.treeScale};trees.push(t);
   const k=Math.floor(tx)+','+Math.floor(ty);if(!treeBuckets.has(k))treeBuckets.set(k,[]);treeBuckets.get(k).push(t);
  }
 }
 for(let x=3;x<l.size-3;x+=3.5){
  const side=Math.floor(x/3.5)%2?1:-1;
  lampPosts.push({x,y:pathY(x)+side*2.15,type:Math.floor(x/3.5)%2,phase:seed(x*3)*6.28,lit:true});
  decorations.push({x:x+.8,y:pathY(x+.8)-side*2.8,type:l.decor,size:.65+seed(x+levelIndex)*.35});
  if(levelIndex===2)decorations.push({x:x+.3,y:pathY(x+.3)+3.1,type:1,size:.7});
 }
 const lines=[['The trees are whispering. Probably discussing biscuits.','A lantern! Finally, someone with a bright personality.'],['No touching the mushrooms. Unless they ask for a high-five.','This is the cosiest spooky place I have ever been.'],['The water says shhh. I say: where is my sister?','My paws are damp. My determination is waterproof.'],['A star winked at me. That counts as directions, right?','Ira, if you are in space, please come down for bedtime.'],['Those flowers smell like almost-home.','I can see a cottage. And something suspiciously pillow-shaped.']];
 for(let i=0;i<2;i++){let x=5+(l.size-12)*(i+1)/3;waypoints.push({x,y:pathY(x),line:lines[levelIndex][i],id:i})}
 initWoodlandQuest();
 bats.length=0;for(let i=0;i<l.bats;i++){let x=8+i*(l.size-15)/Math.max(1,l.bats-1);bats.push({x,y:pathY(x)+.4,homeX:x,homeY:pathY(x)+.4,fear:0,phase:i*2})}
}
function objective(){let done=marks.filter(m=>m.lit).length;$('#hudChapter').textContent='CHAPTER '+(levelIndex+1)+' OF 5';$('#hudTitle').textContent=current().name;$('#objective').textContent=done<marks.length?(levelIndex===2?'Follow the ribbon scraps':levelIndex===1?'Wake the glowcaps':'Light the sleepy lanterns')+' · '+done+' / '+marks.length:(levelIndex===4?'Find Ira beside the little cottage.':'Follow the path to the lantern gate.');if(levelIndex===0)$('#objective').textContent=questObjective();$('#keyStatus').classList.toggle('hidden',!keyQuest?.collected||keyQuest?.doorOpen);$('#journey').textContent=levels.map((_,i)=>i<levelIndex?'✦':i===levelIndex?'✧':'·').join('  ')}
const stories=[
{title:'The suspiciously giggly cushion.',caption:'One last game before bedtime.',text:'Ira was very good at being a pillow. Being a quiet pillow? A little trickier.',bubble:'Ready or not, here I come!',reply:'You can’t see me. I’m a cushion.',replySpeaker:'Ira',footnote:'A cushion with a very obvious bow.',word:'hee hee!',scene:'assets/comic-1.webp',alt:'Ara counts with her eyes covered while Ira peeks out from behind a tiny cushion in their cozy bedroom.'},
{title:'One sister, suddenly missing.',caption:'Then the giggling stopped.',text:'No Ira. Just an open window, a fluttering ribbon… and a very unhelpful teacup.',bubble:'Oh no! Ira’s missing!',reply:'Not in the teacup. Good to know.',replySpeaker:'Ara, checking everywhere',footnote:'Even excellent detectives start small.',word:'…Ira?',scene:'assets/comic-2.webp',alt:'Ara searches beneath an empty teacup as Ira’s ribbon flutters through the open bedroom window.'},
{title:'Brave. Mostly brave. Brave-ish.',caption:'A little light. A big deep breath.',text:'Ara followed the ribbon into the woods. Finding her sister mattered more than a few spooky shadows.',bubble:'Hold on, Ira. I’m coming!',reply:'Dear woods: please use your indoor voice.',replySpeaker:'Ara, politely',footnote:'Very small panda. Very big heart.',word:'gulp.',scene:'assets/comic-3.webp',alt:'Ara holds a warm glowing lantern at the edge of the moonlit woods while a little purple bat peeks down.'}
];
function showMenu(){stageFinished=false;state='menu';setMusicScene('menu');$('#menu').classList.remove('hidden');$('#comic').classList.add('hidden');$('#hud').classList.add('hidden');closeDialog();keys.clear();target=null}
function comic(){state='comic';setMusicScene('menu');$('#menu').classList.add('hidden');$('#comic').classList.remove('hidden');const s=stories[page];$('#panelTitle').textContent=s.title;$('#panelText').textContent=s.text;$('#caption').textContent=s.caption;$('#speaker').textContent='Ara';$('#bubble').textContent=s.bubble;$('#replySpeaker').textContent=s.replySpeaker;$('#replyBubble').textContent=s.reply;$('#footnote').textContent=s.footnote;$('#soundWord').textContent=s.word;$('#pageNum').textContent='OUR STORY · '+(page+1)+' OF 3';$('#next').textContent=page===2?'Into the woods!':'Turn the page';$('#previous').disabled=page===0;$('#comicAra').style.display='none';$('#comicIra').style.display='none';$('#comicArt').style.backgroundImage='url("'+s.scene+'")';$('#comicArt').setAttribute('aria-label',s.alt);$('#comicArt').dataset.panel=page;$('#dots').innerHTML=stories.map((_,i)=>'<i class="'+(i===page?'on':'')+'" aria-label="Page '+(i+1)+(i===page?', current':'')+'"></i>').join('');tone(660)}
$('#previous').onclick=()=>{if(page>0){page--;comic()}};
$('#start').onclick=()=>{page=0;comic()};$('#next').onclick=()=>{if(page<2){page++;comic()}else begin()};$('#skip').onclick=begin;
function begin(){startLevel(0)}
function startLevel(index){levelIndex=index;buildLevel();state='play';setMusicScene('gameplay');player.x=2;player.y=pathY(2);heart=3;invuln=0;cooldown=0;pulse=0;target=null;walk=false;gaitPhase=0;gaitWeight=0;araLook=0;keys.clear();$('#comic').classList.add('hidden');$('#menu').classList.add('hidden');$('#hud').classList.remove('hidden');closeDialog();hearts();objective();toast(current().entry,5)}
function hearts(){$('#hearts').textContent=Array.from({length:3},(_,i)=>i<heart?'♥':'♡').join(' ');$('#hearts').ariaLabel=heart+' hearts remaining'}
function toast(s,d=3){$('#toast').textContent=s;$('#toast').classList.add('on');toastTime=d}
function modal(title,body,actions,eyebrow){pausedFrom=state;state='dialog';keys.clear();target=null;$('#dialogTitle').textContent=title;$('#dialogBody').innerHTML=body;$('#dialogEyebrow').textContent=eyebrow||'A MOMENT BY THE MOONLIGHT';$('#dialogActions').innerHTML='';for(const a of actions){let b=document.createElement('button');b.textContent=a.text;if(a.primary)b.className='primary';b.onclick=a.fn;$('#dialogActions').append(b)}$('#dialog').classList.remove('hidden');$('#dialogActions button')?.focus()}
function closeDialog(){activeSpeaker=null;$('#dialog').classList.add('hidden')}
function resume(){if(stageFinished){return}if(pausedFrom==='menu'){showMenu();return}state=pausedFrom;closeDialog()}
$('#options').onclick=()=>{modal('Make yourself at home.','<label class="setting">Music<input id="music" type="checkbox" '+(musicEnabled?'checked':'')+'></label><label class="setting">Lantern sounds<input id="snd" type="checkbox" '+(sound?'checked':'')+'></label><label class="setting">Gentler motion<input id="motion" type="checkbox" '+(reduced?'checked':'')+'></label><p>Move with WASD or the arrow keys. Tap a spot on the path to walk there. Space makes your lantern glow.</p>',[{text:'Back',fn:resume,primary:true}]);$('#music').onchange=e=>{musicEnabled=e.target.checked;save();unlockMusic()};$('#snd').onchange=e=>{sound=e.target.checked;save();tone()};$('#motion').onchange=e=>{reduced=e.target.checked;document.body.classList.toggle('reduced',reduced);save()}};
function save(){try{localStorage.setItem('ara-options',JSON.stringify({sound,reduced,music:musicEnabled}))}catch{}}
$('#credits').onclick=()=>modal('Two sisters. One adventure.','<p>Starring Ara the Panda and Ira the Pillowcase.</p><p>Menu music: Curious Monsters (Remastered).<br>Gameplay music: Nimble Motif (Remastered).</p><p>Inspired by your original character designs. A tiny, moonlit story about kindness, courage, and finding your way home.</p>',[{text:'Back',fn:resume,primary:true}],'THE OPENING CREDITS');
function pause(){if(state!=='play')return;modal('A little breather.','<p>The woods can wait. Your lantern is still glowing.</p>',[{text:'Keep adventuring',primary:true,fn:resume},{text:'Return to title',fn:showMenu}])}$('#pause').onclick=pause;
function glow(){if(state!=='play'||cooldown>0)return;pulse=GLOW_DURATION;cooldown=LANTERN_COOLDOWN;emitLanternMotes();revealKey();for(const m of marks)if(!m.lit&&current().task==='glow'&&Math.hypot(m.x-player.x,m.y-player.y)<2.5){m.lit=true;sparkles.push({x:m.x,y:m.y,life:1});toast(levelIndex===1?'“Good morning… or good night, mushroom!”':'“There. Much less spooky.”',2.5);objective()}for(const b of bats)if(Math.hypot(b.x-player.x,b.y-player.y)<3.5){b.fear=3;toast('Just a little light. Off you flutter!',2)}tone(850,.32)}$('#glowTouch').onclick=glow;
addEventListener('keydown',e=>{if(['ArrowUp','ArrowDown','ArrowLeft','ArrowRight','Space'].includes(e.code))e.preventDefault();if(e.code==='Escape'){if(state==='play')pause();else if(state==='dialog')resume();return}if(state==='comic'&&(e.code==='Space'||e.code==='Enter')){$('#next').click();return}if(state==='play'){if(e.code==='KeyE'&&!e.repeat){interact();return}keys.add(e.code);target=null;if(e.code==='Space')glow()}});addEventListener('keyup',e=>keys.delete(e.code));addEventListener('blur',()=>{keys.clear();if(state==='play')pause()});
for(const b of document.querySelectorAll('[data-dir]')){let k={up:'ArrowUp',down:'ArrowDown',left:'ArrowLeft',right:'ArrowRight'}[b.dataset.dir];b.onpointerdown=e=>{e.preventDefault();b.setPointerCapture(e.pointerId);keys.add(k);target=null};b.onpointerup=b.onpointercancel=()=>keys.delete(k)}
let tile=55,camera={x:0,y:0};function project(x,y){return{x:(x-y)*tile+camera.x,y:(x+y)*tile*.49+camera.y}}function unproject(x,y){let a=(x-camera.x)/tile,b=(y-camera.y)/(tile*.49);return{x:(a+b)/2,y:(b-a)/2}};
canvas.addEventListener('pointerdown',e=>{if(state!=='play')return;const pt=unproject(e.clientX,e.clientY),n=npcs.find(n=>Math.hypot(n.x-pt.x,n.y-pt.y)<1.2);if(n&&Math.hypot(n.x-player.x,n.y-player.y)<2){talkToNPC(n);return}if(canUseDoor()&&Math.hypot(pt.x-exitPoint().x,pt.y-exitPoint().y)<1.2){interact();return}target=n?{x:n.x,y:n.y}:pt});
function blocked(x,y){if(x<.5||y<.5||x>current().size-1||y>current().size-1)return true;let bx=Math.floor(x),by=Math.floor(y);for(let dx=-1;dx<=1;dx++)for(let dy=-1;dy<=1;dy++)for(const t of treeBuckets.get((bx+dx)+','+(by+dy))||[])if(Math.hypot(t.x-x,t.y-y)<.57)return true;return false}
function move(dx,dy){if(!blocked(player.x+dx,player.y))player.x+=dx;if(!blocked(player.x,player.y+dy))player.y+=dy}
function update(dt){time+=dt;updateCast(dt);if(state!=='play')return;if(updateQuest())return;invuln=Math.max(0,invuln-dt);cooldown=Math.max(0,cooldown-dt);pulse=Math.max(0,pulse-dt);toastTime-=dt;if(toastTime<=0)$('#toast').classList.remove('on');const castOX=player.x,castOY=player.y;let sx=0,sy=0;if(keys.has('KeyW')||keys.has('ArrowUp'))sy--;if(keys.has('KeyS')||keys.has('ArrowDown'))sy++;if(keys.has('KeyA')||keys.has('ArrowLeft'))sx--;if(keys.has('KeyD')||keys.has('ArrowRight'))sx++;let dx=(sx+sy)*.707,dy=(sy-sx)*.707;if(target&&!sx&&!sy){dx=target.x-player.x;dy=target.y-player.y;if(Math.hypot(dx,dy)<.12){target=null;dx=dy=0}}let len=Math.hypot(dx,dy);walk=len>.05;if(walk){dx/=len;dy/=len;face=dx-dy>=0?1:-1;let ox=player.x,oy=player.y;move(dx*dt*2.3,dy*dt*2.3);if(target&&Math.hypot(ox-player.x,oy-player.y)<.001){target=null;toast('A crooked tree! Try the moonlit path.',2)}}updateGait(Math.hypot(player.x-castOX,player.y-castOY),dt);for(const b of bats){let dist=Math.hypot(b.x-player.x,b.y-player.y);b.fear=Math.max(0,b.fear-dt);let tx=b.homeX+Math.sin(time*.8+b.phase)*.9,ty=b.homeY+Math.cos(time*.65+b.phase)*.9;if(dist<3&&!b.fear){tx=player.x;ty=player.y}if(b.fear){tx=b.homeX+(b.x-player.x)*2;ty=b.homeY+(b.y-player.y)*2}let nx=tx-b.x,ny=ty-b.y,l=Math.hypot(nx,ny);if(l>.05){b.x+=nx/l*dt*(b.fear?2:dist<3?1.2:.6);b.y+=ny/l*dt*(b.fear?2:dist<3?1.2:.6)}if(dist<.6&&!invuln&&!b.fear){heart--;hearts();invuln=2.2;b.fear=2;toast('Oops! A fluttery bump. Space to shoo the bats.',3);tone(240);if(heart<=0){player.x=2;player.y=pathY(2);heart=3;hearts();toast('Take a breath. Let’s try the trail again.',4)}}}
for(const w of waypoints)if(!waypointSeen.has(w.id)&&Math.hypot(player.x-w.x,player.y-w.y)<1.4){waypointSeen.add(w.id);toast('“'+w.line+'”',4)}
for(const m of marks)if(!m.lit&&current().task==='collect'&&Math.hypot(player.x-m.x,player.y-m.y)<.85){m.lit=true;toast('“Another ribbon scrap! Ira was here.”',2.5);objective();tone(720)}for(const f of sparkles)f.life-=dt;sparkles=sparkles.filter(f=>f.life>0);
updateLanternMotes(dt);$('#glowStatus').textContent=cooldown>0?'✧ Gathering light · '+cooldown.toFixed(1)+'s':'✧ Lantern ready';$('#glowTouch').style.setProperty?.('--charge',String(1-cooldown/LANTERN_COOLDOWN));let ex=exitPoint();if(Math.hypot(player.x-ex.x,player.y-ex.y)<1.1){if(levelIndex===0){if(keyQuest.doorOpen)complete();else if(toastTime<=0)toast(keyQuest.collected?'Key ready. Press E or tap Open door.':'Locked. Search the birches beside the blue lantern trail.',4)}else if(marks.every(m=>m.lit))complete();else if(toastTime<=0)toast(current().task==='collect'?'A few ribbon scraps are still on the path.':'The path needs a little more light. Glow near the marked spots.',3)}}
function complete(){if(stageFinished||levelIndex===0&&!keyQuest?.doorOpen)return;stageFinished=true;tone(880,.5);const l=current();if(levelIndex<4){const next=levels[levelIndex+1];modal(next.name,'<img class="chapter-art" src="assets/'+next.scene+'.webp" alt="'+next.name+'"><p class="chapter-caption">'+next.caption+'</p><p>'+l.outro+'</p><p class="chapter-joke">'+l.joke+'</p>',[{text:'On to chapter '+(levelIndex+2),primary:true,fn:()=>startLevel(levelIndex+1)},{text:'Return to title',fn:showMenu}],'CHAPTER '+(levelIndex+1)+' COMPLETE · FOUR PAWS FORWARD')}else{modal('Found you, little sister.','<div class="reunion" style="background-image:url(assets/level-5.webp)"><canvas id="reunionAra" width="320" height="420" aria-label="Ara"></canvas><canvas id="reunionIra" width="320" height="420" aria-label="Ira"></canvas></div><p class="chapter-caption">Five little chapters. One very big hug.</p><p>'+l.outro+'</p><p class="chapter-joke">'+l.joke+'</p><p>“Next time,” Ara smiled, “we hide somewhere with biscuits.”</p>',[{text:'Adventure again',primary:true,fn:begin},{text:'Return to title',fn:showMenu}],'IRA FOUND · THE END')}pausedFrom='play'}

function drawImage(img,x,y,w,h){if(img.complete&&img.naturalWidth)ctx.drawImage(img,x,y,w,h)}
function cover(img){if(!img.naturalWidth)return;let s=Math.max(W/img.width,H/img.height);ctx.drawImage(img,(W-img.width*s)/2,(H-img.height*s)/2,img.width*s,img.height*s)}
// Atlas source rectangles are set after the artwork is integrated.
const atlasRects={trees:[[0,0,450,602],[450,0,370,605],[820,0,400,613]],bats:[[1090,185,446,320],[20,605,430,390]],lantern:[575,604,228,405],ribbon:[934,655,590,355]};
function sprite(rect,x,y,w,h){let im=imgs.atlas;if(im.complete&&im.naturalWidth)ctx.drawImage(im,rect[0]*im.naturalWidth/1536,rect[1]*im.naturalHeight/1024,rect[2]*im.naturalWidth/1536,rect[3]*im.naturalHeight/1024,x,y,w,h)}
function diamond(x,y,fill){const p=project(x,y);ctx.fillStyle=fill;ctx.beginPath();ctx.moveTo(p.x,p.y-tile*.49);ctx.lineTo(p.x+tile,p.y);ctx.lineTo(p.x,p.y+tile*.49);ctx.lineTo(p.x-tile,p.y);ctx.closePath();ctx.fill()}
const decorRects=[[0,0,385,512],[384,125,405,375],[790,175,435,345],[1230,35,305,480],[0,550,390,474],[385,540,460,450],[870,540,270,470],[1190,560,346,440]];
function decoration(type,x,y,w,h){let im=imgs.decor;if(im.complete&&im.naturalWidth){const r=decorRects[type],sx=im.naturalWidth/1536,sy=im.naturalHeight/1024;ctx.drawImage(im,r[0]*sx,r[1]*sy,r[2]*sx,r[3]*sy,x,y,w,h)}}
function aura(x,y,r,color){let a=ctx.createRadialGradient(x,y,2,x,y,r);a.addColorStop(0,color);a.addColorStop(1,color.slice(0,7)+'00');ctx.fillStyle=a;ctx.fillRect(x-r,y-r,r*2,r*2)}
// Painted 2.0 terrain and sprites. Light effects are composited over the artwork.
const assetCrops={"trees":[[15,13,310,313],[336,5,314,320],[650,4,311,321],[35,330,260,297],[335,329,302,301],[666,331,281,300],[15,634,299,301],[325,632,325,302],[669,633,287,302],[13,935,311,333],[338,936,297,329],[671,935,277,335],[13,1275,312,323],[325,1272,322,325],[660,1275,294,322]],"lamps":[[175,4,112,393],[493,65,170,331],[161,397,133,396],[484,467,197,311],[166,793,124,397],[482,833,190,343],[155,1190,141,396],[475,1236,207,331],[155,1586,143,384],[484,1616,197,350]]};
function paintedSprite(name,row,col,columns,rows,x,y,h,maxW=Infinity){
 const im=imgs[name];if(!im?.naturalWidth)return;
 const crop=(name==='trees-v2'?assetCrops.trees:assetCrops.lamps)[row*columns+col];
 const cw=im.naturalWidth/columns,ch=im.naturalHeight/rows,r=crop||[col*cw,row*ch,cw,ch];
 let w=h*r[2]/r[3];if(w>maxW){h*=maxW/w;w=maxW}
 ctx.drawImage(im,...r,x-w/2,y-h,w,h);return{w,h,top:y-h};
}
const groundCrops=[[2,2,276,272],[282,2,278,272],[564,2,277,272],[845,2,275,272],[2,278,276,273],[282,278,278,273],[564,278,277,273],[845,278,275,273],[2,555,276,273],[282,555,278,273],[564,555,277,273],[845,555,275,273],[2,832,276,271],[282,832,278,271],[564,832,277,271],[845,832,275,271],[2,1107,276,293],[282,1107,278,293],[564,1107,277,293],[845,1107,275,293]];
function paintedGround(x,y,trail){
 const p=project(x,y),im=imgs['ground-v2'],parity=(x+y)&1;
 if(!im?.naturalWidth){diamond(x,y,current().theme[(trail?0:3)+parity]);return}
 const cw=im.naturalWidth/4,ch=im.naturalHeight/5,col=(trail?0:2)+parity;
 ctx.save();ctx.transform(tile,tile*.49,-tile,tile*.49,p.x,p.y-tile*.49);
 ctx.drawImage(im,...groundCrops[levelIndex*4+col],-.004,-.004,1.008,1.008);ctx.restore();
 // Alternating gentle glazing makes the painted checkerboard legible.
 diamond(x,y,parity?'#12233515':'#edf1dc0d');
}
function onScreen(p,pad=180){return p.x>-pad&&p.x<W+pad&&p.y>-pad&&p.y<H+pad}
function softLight(x,y,r,color,strength=1){ctx.save();ctx.globalCompositeOperation='screen';ctx.globalAlpha=strength;aura(x,y,r,color);ctx.restore()}
function groundLight(p,r,color,alpha){ctx.save();ctx.globalCompositeOperation='screen';ctx.translate(p.x,p.y);ctx.scale(1,.49);ctx.globalAlpha=alpha;aura(0,0,r,color);ctx.restore()}
function emitLanternMotes(){
 // Motes live in world coordinates, so they don't slide with the camera.
 const count=reduced?8:42;
 for(let i=0;i<count;i++){
  const a=i/count*Math.PI*2+seed(i+time)*.7;
  lanternMotes.push({x:player.x,y:player.y,z:.55,age:0,life:.65+seed(i*5+time)*.65,vx:Math.cos(a)*(1+seed(i)*2.3),vy:Math.sin(a)*(1+seed(i+9)*2.3),vz:.25+seed(i*3)*.75,twist:seed(i*7)*6.28,size:1.2+seed(i*13)*2.4});
 }
}
function updateLanternMotes(dt){for(const m of lanternMotes){m.age+=dt;if(!reduced){m.x+=m.vx*dt;m.y+=m.vy*dt;m.z+=m.vz*dt;m.vx*=Math.exp(-dt*1.8);m.vy*=Math.exp(-dt*1.8)}}lanternMotes=lanternMotes.filter(m=>m.age<m.life)}
function drawLanternBurst(p){
 if(pulse<=0)return;
 const t=1-pulse/GLOW_DURATION,fade=Math.sin(Math.PI*Math.min(1,t*1.05)),m=moods[levelIndex];
 groundLight(p,reduced?135:100+t*145,m.light+'88',.55*fade);
 softLight(p.x,p.y-55,85+t*65,m.light+'66',fade);
 ctx.save();ctx.globalCompositeOperation='screen';
 // Three short wisps fan outward and twist around the lifted lantern.
 for(let k=0;k<(reduced?0:3);k++){
  ctx.strokeStyle=k===1?'#d3eaff':'#ffe2a6';ctx.globalAlpha=fade*.5;ctx.lineWidth=1.7;
  ctx.beginPath();for(let i=0;i<=22;i++){let u=i/22,a=u*3.1+k*2.094+t*3.4,r=(22+u*92)*Math.sin(Math.PI*t*.9);let x=p.x+Math.cos(a)*r,y=p.y-48+Math.sin(a)*r*.45-u*24*t;if(i===0)ctx.moveTo(x,y);else ctx.lineTo(x,y)}ctx.stroke();
 }
 ctx.restore();
}
function drawMotes(){ctx.save();ctx.globalCompositeOperation='screen';for(const m of lanternMotes){const p=project(m.x,m.y),a=1-m.age/m.life,x=p.x,y=p.y-m.z*tile;ctx.globalAlpha=a*(reduced?.7:.55+.25*Math.sin(m.age*19+m.twist));ctx.fillStyle=m.age>.5?'#cdeaff':'#ffe7b0';ctx.beginPath();ctx.arc(x,y,m.size,0,Math.PI*2);ctx.fill();if(m.size>2.7){ctx.strokeStyle='#fff1cd';ctx.lineWidth=1;ctx.beginPath();ctx.moveTo(x-4*a,y);ctx.lineTo(x+4*a,y);ctx.moveTo(x,y-4*a);ctx.lineTo(x,y+4*a);ctx.stroke()}}ctx.restore()}
function drawMoonlight(){
 const m=moods[levelIndex];
 ctx.save();ctx.globalCompositeOperation='screen';
 // Long, very soft shafts, kept faint enough for the lanterns to remain warm.
 for(let i=0;i<3;i++){ctx.save();ctx.translate(W*(.2+i*.3),-H*.1);ctx.rotate(-.24);let g=ctx.createLinearGradient(0,0,0,H*1.1);g.addColorStop(0,m.moon+'20');g.addColorStop(.45,m.moon+'09');g.addColorStop(1,m.moon+'00');ctx.fillStyle=g;ctx.fillRect(-36-i*12,0,72+i*24,H*1.3);ctx.restore()}
 ctx.restore();
}
function drawPost(t){const p=project(t.x,t.y);if(!onScreen(p,190))return;let h=tile*(t.type?1.75:2.7);let info=paintedSprite('lamps-v2',levelIndex,t.type,2,5,p.x,p.y,h,tile*1.25);const top=info?info.top:p.y-h;const flicker=reduced?1:1+Math.sin(time*2.6+t.phase)*.045+Math.sin(time*5.1+t.phase)*.02;softLight(p.x,top+h*.18,48*flicker,(t.blue?'#94d9ff':moods[levelIndex].light)+'75',.65);}
function drawAtmosphere(){
 const m=moods[levelIndex];
 ctx.save();ctx.globalCompositeOperation='screen';
 for(let i=0;i<24;i++){
  const wx=Math.floor(player.x/9)*9+seed(i*17+levelIndex*35)*18-9,wy=pathY(wx)+(seed(i*29)-.5)*9,p=project(wx,wy);
  if(!onScreen(p,20))continue;let drift=reduced?0:Math.sin(time*.65+i)*9;
  ctx.globalAlpha=.15+(reduced?.12:Math.sin(time*2+i)*.09);ctx.fillStyle=levelIndex===1?'#dad0ff':levelIndex===3?'#d8e9ff':levelIndex===4?'#ffe3c6':'#e4eab0';
  if(levelIndex===4){ctx.beginPath();ctx.ellipse(p.x+drift,p.y-45,3.5,1.8,i,0,7);ctx.fill()}
  else{ctx.beginPath();ctx.arc(p.x+drift,p.y-35-(reduced?0:Math.cos(time*.6+i)*12),levelIndex===3?1.7:1.3,0,7);ctx.fill()}
 }
 ctx.restore();
 // Low drifting mist grazes the screen edges rather than hiding the ground.
 ctx.save();for(let i=0;i<2;i++){ctx.fillStyle=m.mist+'0b';ctx.beginPath();ctx.ellipse(W*.5+(reduced?0:Math.sin(time*.12+i)*100),H*(.82+i*.12),W*.7,16,0,0,7);ctx.fill()}ctx.restore();
}
function render(){
 ctx.clearRect(0,0,W,H);
 if(state==='menu'||state==='comic'||(state==='dialog'&&pausedFrom==='menu')){cover(imgs.forest);if(!imgs.forest.naturalWidth){ctx.fillStyle='#142a32';ctx.fillRect(0,0,W,H)}drawMoonlight();fireflies();drawCastSurfaces();return}
 const l=current(),n=l.size,m=moods[levelIndex];ctx.fillStyle='#101d2a';ctx.fillRect(0,0,W,H);ctx.globalAlpha=.48;cover(imgs[l.scene]);ctx.globalAlpha=1;
 tile=W<700?42:58;camera.x=W*.5-(player.x-player.y)*tile;camera.y=H*.55-(player.x+player.y)*tile*.49;
 // Iterate only tiles within the current viewport, even on doubled maps.
 const corners=[unproject(-tile,-tile),unproject(W+tile,-tile),unproject(-tile,H+tile),unproject(W+tile,H+tile)];
 const minX=Math.max(0,Math.floor(Math.min(...corners.map(p=>p.x)))),maxX=Math.min(n-1,Math.ceil(Math.max(...corners.map(p=>p.x))));
 const minY=Math.max(0,Math.floor(Math.min(...corners.map(p=>p.y)))),maxY=Math.min(n-1,Math.ceil(Math.max(...corners.map(p=>p.y))));
 for(let sum=minX+minY;sum<=maxX+maxY;sum++)for(let x=minX;x<=maxX;x++){
  let y=sum-x;if(y<minY||y>maxY)continue;const p=project(x,y);if(!onScreen(p,tile*1.1))continue;
  const trail=Math.abs(y-pathY(x))<2.1||onKeyTrail(x,y);paintedGround(x,y,trail);
  if(levelIndex===2&&!trail){ctx.strokeStyle='#bde4e422';ctx.lineWidth=1;ctx.beginPath();ctx.ellipse(p.x,p.y+(reduced?0:Math.sin(time+x)*1.5),18,4,0,0,7);ctx.stroke()}
 }
 // Cool moonlight glazing sets the night without swallowing painted detail.
 ctx.fillStyle=['#08273825','#241a4430','#073a4927','#15234330','#1e352224'][levelIndex];ctx.fillRect(0,0,W,H);drawMoonlight();
 for(const t of lampPosts){const p=project(t.x,t.y);if(onScreen(p,170))groundLight(p,tile*(t.type?2:2.7),(t.blue?'#9ad9ff':m.light)+'9a',.42)}
 for(const t of marks)if(t.lit){const p=project(t.x,t.y);if(onScreen(p,120))groundLight(p,110,m.light+'99',.45)}
 const pp=project(player.x,player.y);groundLight(pp,135+(reduced?0:Math.sin(time*2)*2),'#ffe1ac77',.45);
 const ex=exitPoint(),gate=project(ex.x,ex.y),ready=levelIndex===0?keyQuest.collected:marks.every(t=>t.lit);
 const ents=trees.filter(t=>onScreen(project(t.x,t.y),tile*5)).map(t=>({depth:t.x+t.y,kind:'tree',t}));
 for(const t of decorations)if(onScreen(project(t.x,t.y),tile*2))ents.push({depth:t.x+t.y,kind:'decor',t});
 for(const t of lampPosts)if(onScreen(project(t.x,t.y),tile*3))ents.push({depth:t.x+t.y,kind:'post',t});
 for(const t of marks)if(onScreen(project(t.x,t.y),tile*3))ents.push({depth:t.x+t.y,kind:'mark',t});
 for(const n of npcs)if(onScreen(project(n.x,n.y),160))ents.push({depth:n.x+n.y,kind:'npc',n});
 if(keyQuest&&onScreen(project(keyQuest.clearing.x,keyQuest.clearing.y),300))ents.push({depth:keyQuest.clearing.x+keyQuest.clearing.y-.2,kind:'keylandmark'});
 ents.push({depth:player.x+player.y,kind:'player'});
 for(const b of bats)if(onScreen(project(b.x,b.y),100))ents.push({depth:b.x+b.y,kind:'bat',b});
 if(onScreen(gate,250))ents.push({depth:ex.x+ex.y,kind:'gate'});
 ents.sort((a,b)=>a.depth-b.depth);
 for(const e of ents){
  if(e.kind==='tree'){
   const t=e.t,p=project(t.x,t.y),h=tile*3.9*t.size;
   ctx.fillStyle='#0618273a';ctx.beginPath();ctx.ellipse(p.x-15,p.y+5,40*t.size,11*t.size,-.15,0,7);ctx.fill();
   ctx.globalAlpha=p.y>pp.y&&Math.abs(p.x-pp.x)<tile*1.2&&p.y-pp.y<h*.7?.2:1;
   paintedSprite('trees-v2',levelIndex,t.type,3,5,p.x,p.y,h,tile*2.25);ctx.globalAlpha=1;
  }else if(e.kind==='npc'){drawNPC(e.n)}else if(e.kind==='keylandmark'){drawQuestLandmark()}else if(e.kind==='post'){drawPost(e.t)}
  else if(e.kind==='decor'){const t=e.t,p=project(t.x,t.y),h=tile*1.5*t.size;decoration(t.type,p.x-h*.45,p.y-h,h*.9,h);if(levelIndex===1)softLight(p.x,p.y-30,38,'#bd9aff44',.3)}
  else if(e.kind==='mark'){
   const t=e.t,p=project(t.x,t.y);if(t.lit&&l.task==='collect')continue;
   if(l.task==='collect'){softLight(p.x,p.y-16,40,'#ffdeb355',.4);sprite(atlasRects.ribbon,p.x-24,p.y-36,48,29);ctx.fillStyle='#ffe6ba';ctx.font='16px Georgia';ctx.textAlign='center';ctx.fillText('✧',p.x,p.y-47)}
   else{
    if(levelIndex===1)decoration(0,p.x-39,p.y-88,78,93);else paintedSprite('lamps-v2',levelIndex,1,2,5,p.x,p.y,tile*1.9,tile*1.25);
    softLight(p.x,p.y-65,t.lit?65:26,t.lit?m.light+'aa':m.moon+'30',t.lit?.8:.4);
    ctx.textAlign='center';ctx.fillStyle=t.lit?'#ffe5b2':'#e1e6df';ctx.font='14px system-ui';ctx.fillText(t.lit?'Awake!':'Glow nearby',p.x,p.y-112);
   }
  }else if(e.kind==='bat'){drawBat(e.b)}
  else if(e.kind==='player'){drawAra(pp)}
  else if(e.kind==='gate'){
   groundLight(gate,130,ready?m.light+'99':m.moon+'44',.4);
   if(levelIndex===0){drawImage(imgs['woodland-door'],gate.x-85,gate.y-168,170,168);softLight(gate.x,gate.y-55,45,ready?'#ffdb9b66':'#9fcdea22',.5)}else if(levelIndex===4){decoration(5,gate.x-115,gate.y-190,230,215);drawIra({x:gate.x+44,y:gate.y+1})}
   else{paintedSprite('lamps-v2',levelIndex,0,2,5,gate.x-55,gate.y,160,90);paintedSprite('lamps-v2',levelIndex,0,2,5,gate.x+55,gate.y,160,90);sprite(atlasRects.ribbon,gate.x-23,gate.y-45,46,28);softLight(gate.x,gate.y-95,85,ready?m.light+'88':m.moon+'33',.55)}
   ctx.fillStyle='#f2e5ce';ctx.font='italic 16px Georgia';ctx.textAlign='center';ctx.fillText(levelIndex===0?(ready?'Key found · Open the woodland door':'Woodland door · Locked'):levelIndex===4?'Ira’s little hiding place':ready?'The way onward':'A little light will open the way',gate.x,gate.y-(levelIndex===4?210:180));
  }
 }
 for(const f of sparkles){const p=project(f.x,f.y);ctx.save();ctx.globalAlpha=f.life;ctx.fillStyle='#ffecba';ctx.font='18px Georgia';for(let i=0;i<6;i++)ctx.fillText('✧',p.x+Math.cos(i)*35*(1-f.life),p.y-50-Math.sin(i)*40*(1-f.life));ctx.restore()}
 let night=ctx.createRadialGradient(pp.x,pp.y-40,70,pp.x,pp.y,Math.max(W,H)*.65);night.addColorStop(0,'#08162605');night.addColorStop(.55,'#0a173619');night.addColorStop(1,'#04101d66');ctx.fillStyle=night;ctx.fillRect(0,0,W,H);drawMotes();if(target){const p=project(target.x,target.y);ctx.strokeStyle='#f0ddabaa';ctx.lineWidth=1.5;ctx.beginPath();ctx.ellipse(p.x,p.y,12,6,0,0,7);ctx.stroke()}drawAtmosphere();drawDialogCast();drawCastSurfaces();
}
function fireflies(){ctx.save();for(let i=0;i<32;i++){let x=seed(i*7)*W+(reduced?0:Math.sin(time*.4+i)*22),y=seed(i*23+5)*H+(reduced?0:Math.cos(time*.3+i)*12);ctx.fillStyle='rgba(228,211,144,'+(.18+(reduced?0:Math.sin(time*1.7+i)*.12))+')';ctx.beginPath();ctx.arc(x,y,1.5,0,7);ctx.fill()}ctx.restore()}

let npcs=[],keyQuest=null;
function distanceToSegment(x,y,a,b){let dx=b.x-a.x,dy=b.y-a.y,t=Math.max(0,Math.min(1,((x-a.x)*dx+(y-a.y)*dy)/(dx*dx+dy*dy)));return Math.hypot(x-a.x-t*dx,y-a.y-t*dy)}
function woodlandTrail(){return[{x:24,y:pathY(24)},{x:26,y:pathY(26)+3},{x:29,y:pathY(29)+6}]}
function onKeyTrail(x,y){if(levelIndex!==0)return false;const p=woodlandTrail();return distanceToSegment(x,y,p[0],p[1])<1.4||distanceToSegment(x,y,p[1],p[2])<1.4||Math.hypot(x-p[2].x,y-p[2].y)<2.4}
function keyClearing(x,y){if(levelIndex!==0)return false;const p=woodlandTrail();return distanceToSegment(x,y,p[0],p[1])<2.4||distanceToSegment(x,y,p[1],p[2])<2.4||Math.hypot(x-p[2].x,y-p[2].y)<3.4}
function initWoodlandQuest(){
 npcs=[];keyQuest=null;$('#interact').classList.add('hidden');
 if(levelIndex!==0)return;
 npcs=[{id:'pip',name:'Pip',role:'Lantern guide',x:4.5,y:pathY(4.5)+.75,art:0,introduced:false},{id:'bramble',name:'Bramble',role:'Door keeper',x:10,y:pathY(10)-.65,art:1,introduced:false},{id:'moss',name:'Moss',role:'Woodland explorer',x:17,y:pathY(17)+.75,art:2,introduced:false}];
 const c=woodlandTrail()[2];keyQuest={started:false,revealed:false,collected:false,doorOpen:false,key:{x:c.x+.85,y:c.y+.15},clearing:c};
 // A blue-tinted lantern marks the small branch; the main trail stays gold.
 lampPosts.push({x:24.2,y:pathY(24)+1.9,type:1,phase:0,lit:true,blue:true});
}
function questObjective(){
 if(!keyQuest)return null;
 if(keyQuest.doorOpen)return 'Quest 1 complete · The woodland door is open.';
 if(keyQuest.collected)return 'Quest 1 · Key found! Follow the main trail to the door.';
 if(keyQuest.revealed)return 'Quest 1 · Pick up the shimmering key near the birches.';
 if(keyQuest.started)return 'Quest 1 · Search the pale birches beside the blue lantern trail.';
 return 'Meet your woodland neighbours along the lantern trail.';
}
function talkToNPC(n){
 if(state!=='play'||!n)return;n.introduced=true;
 let text,action='Keep exploring';
 if(n.id==='pip')text='<p>“A little panda with a very big mission! Let’s find your sister.”</p><p><strong>Move:</strong> WASD or arrow keys. On a phone, use the direction pad or tap the path.</p><p><strong>Lantern:</strong> press Space or tap Glow. Its shimmer shoos away bats and reveals things hiding in the woods. It recharges quickly!</p><p><strong>Talk:</strong> come close and press E or tap Talk. Follow the warm lanterns to meet my neighbours.</p><p class="chapter-joke">“I would fly with you, but somebody must supervise this branch.”</p>';
 else if(n.id==='bramble')text=keyQuest.collected?'<p>“You found the key! Follow the main lantern trail to the far end of the woods. Use E or Open door when you reach the wooden door.”</p><p class="chapter-joke">“I knew it wasn’t locked forever. I was just being thorough.”</p>':'<p>“The wooden door at the far end of the woods is locked. You’ll need its brass key to reach the next glade.”</p><p>“Moss the fox is farther along this trail. If anyone knows where it went, he does.”</p><p class="chapter-joke">“I tried saying please. Very politely. Still locked.”</p>';
 else{
  if(!keyQuest.started){keyQuest.started=true;objective()}
  action=keyQuest.collected?'Back to the door':'I’ll look for it!';
  text=keyQuest.collected?'<p>“That’s the key! The wooden door is at the end of the main trail. Go on—your sister is waiting.”</p>':'<p><strong>Quest 1 · The Lost Woodland Key</strong></p><p>“I last saw it where <strong>three pale birches</strong> gather around <strong>blue mushrooms</strong>.”</p><p>“A little farther up this path, a <strong>blue lantern</strong> marks a narrow trail into the trees. Follow that trail and shine your lantern between the birch roots. Something brass may wink back.”</p><p class="chapter-joke">“Keys are dreadful at hide-and-seek. They never giggle.”</p>';
 }
 modal(n.name+' · '+n.role,'<div class="npc-portrait"><canvas id="npcPortrait" width="256" height="320" aria-label="'+n.name+'"></canvas></div>'+text,[{text:action,primary:true,fn:resume}],'A WOODLAND NEIGHBOUR');n.greetAt=castClock;activeSpeaker=n.id;
}
function nearestNPC(){return npcs.filter(n=>Math.hypot(n.x-player.x,n.y-player.y)<2).sort((a,b)=>Math.hypot(a.x-player.x,a.y-player.y)-Math.hypot(b.x-player.x,b.y-player.y))[0]}
function canUseDoor(){const e=exitPoint();return levelIndex===0&&Math.hypot(player.x-e.x,player.y-e.y)<1.8}
function interact(){if(state!=='play')return;const n=nearestNPC();if(n){talkToNPC(n);return}if(canUseDoor()){if(!keyQuest.collected){toast('Locked. Find the woodland key—Moss knows a little hint.',4);return}keyQuest.doorOpen=true;objective();tone(1100,.4);complete()}}
function updateQuest(){
 const button=$('#interact');if(!keyQuest){button.classList.add('hidden');return false}
 const n=nearestNPC(),door=canUseDoor();button.classList.toggle('hidden',!n&&!door);button.textContent=n?'Talk to '+n.name: keyQuest.collected?'Open door':'Check door';
 if(n&&!n.introduced){talkToNPC(n);return true}
 if(keyQuest.revealed&&!keyQuest.collected&&Math.hypot(player.x-keyQuest.key.x,player.y-keyQuest.key.y)<.85){keyQuest.collected=true;keyQuest.started=true;sparkles.push({x:keyQuest.key.x,y:keyQuest.key.y,life:1});objective();tone(1020,.35);toast('Key found! Follow the golden lanterns to the woodland door.',5)}
 return false;
}
function revealKey(){if(keyQuest&&!keyQuest.collected&&Math.hypot(player.x-keyQuest.key.x,player.y-keyQuest.key.y)<3){if(!keyQuest.revealed){keyQuest.revealed=true;keyQuest.started=true;objective();toast('A brass shimmer between the roots! Walk close to pick it up.',4)}}}
$('#interact').onclick=interact;
function drawQuestLandmark(){const c=keyQuest.clearing,p=project(c.x,c.y),im=imgs['key-birches'],h=tile*3.7,w=im.naturalWidth?h*im.naturalWidth/im.naturalHeight:h;drawImage(im,p.x-w/2,p.y-h,w,h);softLight(p.x,p.y-30,65,'#8fceff66',.6);if(!keyQuest.collected){const k=project(keyQuest.key.x,keyQuest.key.y);if(keyQuest.revealed){const y=k.y-14+(reduced?0:Math.sin(time*3)*3);softLight(k.x,y,35,'#ffe69999',.7);drawImage(imgs['woodland-key'],k.x-18,y-22,36,38);ctx.fillStyle='#ffe5a1';ctx.textAlign='center';ctx.font='14px Georgia';ctx.fillText('Woodland key',k.x,y-33)}else{ctx.fillStyle='#92cef488';ctx.beginPath();ctx.arc(k.x,k.y-10,2,0,7);ctx.fill()}}}

// Articulated 2.2 cast: attachment pivots stay fixed as each part moves.
let castClock=0,activeSpeaker=null,gaitPhase=0,gaitWeight=0,araLook=0;
const castRigRects={"ara-rig-22":[[0,32,588,451],[628,106,458,392],[1209,92,239,390],[125,515,330,465],[626,660,314,276],[1165,659,314,274]],"npc-rig-22":[[18,22,340,277],[379,2,330,319],[711,42,230,177],[1073,12,258,300],[1384,46,223,251],[7,319,343,279],[360,319,350,286],[729,343,300,223],[1063,331,222,248],[1336,328,278,287],[10,602,352,319],[363,613,408,350],[765,656,263,208],[1052,653,237,257],[1305,620,310,319]],"support-rig-22":[[32,50,442,450],[541,50,449,450],[1054,50,441,452],[58,530,418,436],[528,585,476,357],[1056,589,444,354]]}; // Source-pixel crops for isolated joint parts.
function castPart(c,atlas,index,x,y,w,h,angle=0,ax=.5,ay=.5){
 const im=imgs[atlas],r=castRigRects[atlas]?.[index];if(!r||!im?.naturalWidth)return false;
 c.save();c.translate(x,y);c.rotate(angle);c.drawImage(im,r[0],r[1],r[2],r[3],-w*ax,-h*ay,w,h);c.restore();return true;
}
function castShadow(c,x,y,w,alpha=.28){c.save();c.fillStyle='rgba(4,15,23,'+alpha+')';c.beginPath();c.ellipse(x,y,w,w*.26,0,0,Math.PI*2);c.fill();c.restore()}
function castBeat(phase=0,speed=1){return reduced?0:Math.sin(castClock*speed+phase)}
function castReady(name){return !!(imgs[name]?.naturalWidth&&castRigRects[name]?.length)}
function updateCast(dt){
 if(state==='menu'||state==='play'||state==='dialog'&&activeSpeaker)castClock+=dt;
 if(state!=='play')return;
 const n=nearestNPC(),desired=n?Math.max(-.11,Math.min(.11,(project(n.x,n.y).x-project(player.x,player.y).x)/600)):0;
 araLook+=(desired-araLook)*Math.min(1,dt*7);
}
function updateGait(distance,dt){gaitPhase+=distance*4.5;gaitWeight+=((distance>.001?1:0)-gaitWeight)*Math.min(1,dt*10)}
function drawAraRig(c,p,preview=false){
 castShadow(c,p.x,p.y+2,24);
 if(!castReady('ara-rig-22')){if(imgs.ara.complete&&imgs.ara.naturalWidth)c.drawImage(imgs.ara,p.x-35,p.y-94,70,98);return}
 const gait=reduced||preview?0:Math.sin(gaitPhase)*gaitWeight,step=reduced||preview?0:Math.abs(Math.sin(gaitPhase))*gaitWeight;
 const lift=!preview&&pulse>0?(reduced?.65:Math.sin((1-pulse/GLOW_DURATION)*Math.PI)):0;
 const breath=castBeat(0,2)*.65,bob=step*2.5;
 c.save();c.translate(p.x,p.y-bob);const facing=preview?1:face;c.scale(facing,1);if(invuln&&!preview)c.globalAlpha=.7+.3*(reduced?1:Math.sin(castClock*12)**2);
 castPart(c,'ara-rig-22',4,-12,-9+gait*2.5,18,14,-gait*.16);
 castPart(c,'ara-rig-22',5,12,-9-gait*2.5,18,14,gait*.16);
 castPart(c,'ara-rig-22',2,-18,-54,20,36,gait*.22-.12,.6,.12);
 castPart(c,'ara-rig-22',1,0,-35-breath,45,44,castBeat(1,2)*.015);
 // Paw, ring handle and lantern are one painted unit: never a floating lamp.
 const armAngle=-lift*.65+gait*.07+castBeat(0,2.7)*.025;
 castPart(c,'ara-rig-22',3,18,-54-breath,33,56,armAngle,.14,.09);
 const headTilt=reduced?0:(preview?0:araLook)*facing+castBeat(2,1.4)*.025-gait*.018;
 castPart(c,'ara-rig-22',0,0,-52-breath,70,59,headTilt,.5,.95);
 c.restore();
 const a=armAngle,dx=(20-33*.14),dy=(42-56*.09),lx=p.x+facing*(18+dx*Math.cos(a)-dy*Math.sin(a)),ly=p.y-bob-54-breath+dx*Math.sin(a)+dy*Math.cos(a);
 return{x:lx,y:ly,lift};
}
function drawAra(p){const lamp=drawAraRig(ctx,p);if(!lamp)return;softLight(lamp.x,lamp.y,45+lamp.lift*35,'#ffdc9470',.7);softLight(lamp.x,lamp.y,15,'#fff0be90',.8);drawLanternBurst({x:lamp.x,y:lamp.y+48})}
function drawNPCRig(c,n,p,h,portrait=false){
 const index=n.art*5,near=portrait||Math.hypot(n.x-player.x,n.y-player.y)<3.5,talking=activeSpeaker===n.id;
 const greet=reduced?0:Math.max(0,1-(castClock-(n.greetAt??-100))/1.1),breath=castBeat(n.art,1.8)*.7;
 const look=reduced?0:Math.max(-.1,Math.min(.1,(project(player.x,player.y).x-project(n.x,n.y).x)/400));
 const speak=talking?castBeat(n.art,5.5)*.025:0;
 c.save();c.translate(p.x,p.y);c.scale(h/110,h/110);
 castShadow(c,0,2,22);
 if(!castReady('npc-rig-22')){const im=imgs['npc-'+n.id];if(im?.naturalWidth)c.drawImage(im,-40,-110,80,110);c.restore();return}
 // Rear details are independent: fox tail, hedgehog quills, owl scarf fringe.
 if(n.id==='moss')castPart(c,'npc-rig-22',index+4,21,-22,51,47,castBeat(1,1.9)*.13,.15,.8);
 else if(n.id==='bramble')castPart(c,'npc-rig-22',index+4,-4,-54,48,57,castBeat(2,1.6)*.025);
 else castPart(c,'npc-rig-22',index+4,14,-48,17,31,castBeat(0,2.3)*.09,.5,.1);
 castPart(c,'npc-rig-22',index+1,0,-29-breath,62,58,castBeat(n.art,1.5)*.015);
 if(n.id==='pip'){
  castPart(c,'npc-rig-22',index+2,-23,-48-breath,35,31,-.08+castBeat(1,1.7)*.04,.6,.15);
  castPart(c,'npc-rig-22',index+3,23,-49-breath,33,39,-(near?.14:0)-greet*.12+castBeat(2,2)*.035,.18,.12);
 }else if(n.id==='bramble'){
  castPart(c,'npc-rig-22',index+2,-24,-45-breath,51,38,castBeat(0,1.8)*.035,.15,.3);
  castPart(c,'npc-rig-22',index+3,24,-47-breath,29,33,-(near?.25:0)-greet*.35+(talking?castBeat(1,5)*.05:castBeat(1,1.8)*.03),.25,.12);
 }else{
  castPart(c,'npc-rig-22',index+3,-24,-47-breath,30,34,castBeat(0,1.7)*.04,.35,.1);
  const point=near?.2:0;
  castPart(c,'npc-rig-22',index+2,23,-47-breath,44,35,-point-greet*.16+(talking?castBeat(1,3.5)*.055:castBeat(1,1.7)*.03),.1,.25);
 }
 castPart(c,'npc-rig-22',index,0,-53-breath,59,51,look+castBeat(n.art,1.4)*.035+speak,.5,.93);
 c.restore();
}
function drawNPC(n){
 const p=project(n.x,n.y),near=Math.hypot(n.x-player.x,n.y-player.y)<3.5;
 drawNPCRig(ctx,n,p,tile*2.15);
 if(n.id==='pip')softLight(p.x+tile*.55,p.y-tile*.68,32,'#ffe1a366',.5);
 ctx.textAlign='center';ctx.font='15px Georgia';ctx.fillStyle=near?'#fff4d7':'#e6dec8';ctx.fillText(n.name,p.x,p.y-tile*2.35);
 ctx.font='18px Georgia';ctx.fillStyle='#e9d29e';ctx.fillText(n.introduced?(near?'Talk · E':'…'):'!',p.x,p.y-tile*2.7);
}
function drawIraRig(c,p,preview=false){
 if(!castReady('support-rig-22')){if(imgs.ira.complete&&imgs.ira.naturalWidth)c.drawImage(imgs.ira,p.x-28,p.y-65,56,65);return}
 const near=preview||Math.hypot(player.x-exitPoint().x,player.y-exitPoint().y)<4;
 const blink=!reduced&&castClock%4.8>4.62;
 c.save();c.translate(p.x,p.y);c.rotate(castBeat(1,near?2.5:1.2)*.035);c.scale(1+castBeat(2,1.7)*.018,1-castBeat(2,1.7)*.018);
 castShadow(c,0,1,21);castPart(c,'support-rig-22',blink?1:near?2:0,0,-34,62,68);c.restore();
}
function drawIra(p){drawIraRig(ctx,p)}
function drawBat(b){
 const p=project(b.x,b.y),flap=reduced?.18:Math.sin(castClock*(b.fear?19:12)+b.phase),squash=reduced?1:.8+.18*Math.abs(flap);
 castShadow(ctx,p.x,p.y,15,.18);
 if(!castReady('support-rig-22')){sprite(atlasRects.bats[0],p.x-31,p.y-62,62,58);return}
 ctx.save();ctx.translate(p.x,p.y-42+castBeat(b.phase,3)*3);ctx.rotate(castBeat(b.phase,2)*.045+(b.fear?castBeat(b.phase,8)*.09:0));
 ctx.save();ctx.scale(1,squash);castPart(ctx,'support-rig-22',4,-8,-11,40,30,-flap*.24,.72,.1);castPart(ctx,'support-rig-22',5,8,-11,40,30,flap*.24,.35,.1);ctx.restore();
 castPart(ctx,'support-rig-22',3,0,-3,24,34,castBeat(b.phase,2)*.04);ctx.restore();
}
function drawDialogCast(){
 if(!activeSpeaker||state!=='dialog')return;const n=npcs.find(n=>n.id===activeSpeaker),el=$('#npcPortrait');
 if(!n||!el?.getContext)return;const c=el.getContext('2d');c.clearRect(0,0,256,320);drawNPCRig(c,n,{x:128,y:300},250,true);
}

function drawCastSurfaces(){
 for(const [id,type]of [['menuAra','ara'],['menuIra','ira'],['reunionAra','ara'],['reunionIra','ira']]){
  if(id.startsWith('menu')&&state!=='menu'||id.startsWith('reunion')&&!(state==='dialog'&&stageFinished&&levelIndex===4))continue;
  const el=$('#'+id);if(!el?.getContext)continue;const c=el.getContext('2d');c.clearRect(0,0,320,420);c.save();
  if(type==='ara'){c.translate(140,397);c.scale(3.1,3.1);drawAraRig(c,{x:0,y:0},true)}else{c.translate(155,373);c.scale(4,4);drawIraRig(c,{x:0,y:0},true)}c.restore();
 }
}

function loop(ts){let dt=Math.min((ts-last)/1000,.04);last=ts;update(dt);render();requestAnimationFrame(loop)}requestAnimationFrame(loop);
