const spriteSpeeds=new Map(),spriteImages=new Map();
let spritePlayers=[];
function spriteOutput(key){const edge=graph().edges.find(e=>e.to===key);if(!edge)return null;const record=edge.from.startsWith('sheet-edit-')?sheet(edge.from.slice(11)):edge.from.startsWith('process-')?a(edge.from.slice(8)):null;const ex=last(record);return ex?{source:edge.from,ex}:null}
function setupSpritePlayback(){
 spritePlayers=[];
 for(const node of $$('#nodes .node.export')){
  const data=spriteOutput(node.dataset.node);if(!data)continue;
  const {ex,source}=data,key=pid+':'+ex.base,meta=ex.meta,base=meta.base_fps||meta.fps;
  if(!spriteSpeeds.has(key))spriteSpeeds.set(key,meta.playback_speed||1);
  let panel=node.querySelector('.sprite-playback');
  if(!panel){panel=document.createElement('div');panel.className='sprite-playback';node.querySelector('.node-body').append(panel)}
  const speed=spriteSpeeds.get(key);
  panel.innerHTML=`<div class="sprite-motion checker"><canvas width="${meta.frame_width}" height="${meta.frame_height}" aria-label="动画播放预览"></canvas></div><label><span>播放速度 <b data-speed-label>${speed.toFixed(2)}× · ${(base*speed).toFixed(1)} FPS</b></span><input type="range" min="0.25" max="2" step="0.05" value="${speed}" aria-label="动画播放速度"></label><button type="button" data-save-speed>保存预览速度</button><small>PNG 不含播放速度；导入游戏后请设置帧率。</small>`;
  const slider=panel.querySelector('input');slider.oninput=()=>{spriteSpeeds.set(key,Number(slider.value));panel.querySelector('[data-speed-label]').textContent=`${Number(slider.value).toFixed(2)}× · ${(base*Number(slider.value)).toFixed(1)} FPS`};
  const projectId=pid;panel.querySelector('[data-save-speed]').onclick=async e=>{e.stopPropagation();e.target.disabled=true;try{await api('/projects/'+projectId+'/playback-speed','POST',{source,speed:Number(slider.value)});notify('正在保存画布播放速度；PNG 像素与帧数不变');await refresh(true)}catch(err){notify(err.message,true);e.target.disabled=false}};
  let img=spriteImages.get(ex.base);if(!img){img=new Image();img.src=ex.base+'/spritesheet.png';spriteImages.set(ex.base,img)}
  spritePlayers.push({canvas:panel.querySelector('canvas'),img,key,meta,base,frame:0,time:performance.now()});
 }
 // Only retain images used by visible output nodes.
 const visible=new Set(spritePlayers.map(p=>p.img));for(const [key,img] of spriteImages)if(!visible.has(img))spriteImages.delete(key);
}
function animateSprites(now){
 for(const player of spritePlayers){
  if(!player.canvas.isConnected||!player.img.complete||!player.img.naturalWidth)continue;
  const elapsed=Math.max(0,now-player.time);player.time=now;player.frame+=elapsed/1000*player.base*(spriteSpeeds.get(player.key)||1);
  const index=player.meta.loop?Math.floor(player.frame)%player.meta.frame_count:Math.min(Math.floor(player.frame),player.meta.frame_count-1),f=player.meta.frames[index];if(!f)continue;
  const ctx=player.canvas.getContext('2d');ctx.imageSmoothingEnabled=false;ctx.clearRect(0,0,player.canvas.width,player.canvas.height);ctx.drawImage(player.img,f.x,f.y,f.w,f.h,0,0,player.canvas.width,player.canvas.height);
 }
 requestAnimationFrame(animateSprites);
}
requestAnimationFrame(animateSprites);
