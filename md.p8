pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- not sid meier's danmaku 0.24
-- martin mauchauffee

-- todo: add an input player
-- from a string data

-- todo: fix boss pattern not
-- stopped at next phase

-- todo: fix score is better when
-- die at boss

-- todo: score is too big in
-- boss part against ships part

-- more reward for long life ship

-- todo: the blinking vesse effect
-- activate with too far bullets

-- todo: new boss message: dont
-- be scared, it's only the boss

-- todo: display a werkage
-- of ships after kill

-- todo: add a special sound
-- for red lazer

-- todo: prevent ship shoot
-- bullets after vessel dead
-- when below a certain y

-- ============================
-- math

function nor(x,y)
 l=1/sqrt(x*x+y*y)
 return x*l,y*l end

function rot(x,y,r)
 c,s=cos(r),sin(r)
 return x*c-y*s,x*s+y*c end

function ang(x,y,u,v)
 atan2(v-y,x-u) end

function aim(x,y,u,v)
 r=atan2(u-x,v-y)
 return cos(r),sin(r) end

function dis(x,y,u,v)
 m,n=u-x,v-y
 return m*m+n*n end

-- ============================
-- data

-- x,y= position
-- u,v= direction
-- s= speed
-- t= rotate speed

-- a= active
-- !b= ship/cannon hp
-- !e= initial hp
-- !z= frame live counter
-- !c= bullet shotted
-- !r= base score when shooted

-- d,!e= frame delay,initial

-- g= next index of object
-- l= length of object list

-- !c= bullet count this frame
-- t= repeat x times

-- m= movement function
-- n= shape function
-- p= pattern function

-- i,j= object index
-- b= bullet object
-- q= shape object
-- p= pattern object
-- h= ship/cannon object

-- f= frame tile index
-- o= distance from cannon
-- !z= tile index incr

-- w= aim follow mode
-- xxx: not used for shoot?
-- !r= contiguous shoot mode

-- !d= show vessel colision

-- bullets,shapes,ships,beam,
-- particles,sprite particles,
-- back circle particle,
-- front circle particle,
-- score digits,best score
-- digits,hit combo digits,
-- local damage,boss cannons
bs,qs,hs,be,pp,sp,bp,fp,scos,
best,hitg,lo,bo,slow
={},{},{},{},{},{},{},{},{},{},
{},{},{},-1

-- some table current index and
-- maximum size...,
-- shape speed multiplyer,
-- shape count multiplyer,
-- ship hp multiplyer,
-- hit counter,message,
-- warning message
bs.g,bs.l,qs.g,qs.l,hs.g,hs.l,
be.g,be.l,bed,bee,bef,pp.g,pp.l,
sp.g,sp.l,bp.g,bp.l,fp.g,fp.l,
hitv,lo.g,lo.l,
err,poa
=1,512,1,16,1,16,1,16,0,2,0,1,8,
1,32,11,32,21,32,0,1,16,"",0

function next(t)
 t.g=t.g%t.l+1 end

function none()end

-- ============================
-- conductor helper

function bcount(c)
 local n=max(1,c)
 if(c%2!=n%2)n+=1
 return n end

-- ============================
-- bullet movements

function roundexpl(r,m)
local z,a=lez
return function(i,b)
 --err="z:"..(lez-z)
 local a=lez-z
 if a<m then
  b.u,b.v=rot(b.u,b.v,r)
 elseif a==m then
  b.u*=1.7
  b.v*=1.7
 else
  b.u*=1.01
  b.v*=1.01
 end
end
end

function roundinf(i,b)
 b.u*=1.04
 b.v*=1.04
end

-- ============================
-- ship movements

function cross(i,h)
 h.x+=h.u*h.s h.y+=h.v*h.s end

function retreat(i,h)
 h.v=mid(-0.1,h.v-0.05,-1)
 cross(i,h,ve) end

function curve(i,h)
 h.x+=h.u*h.s h.y+=h.v*h.s
 h.u,h.v=rot(h.u,h.v,h.t) end

function flee(i,h)
 dx=vex-h.x
 h.u=-dx*0.01 h.v+=0.03
 cross(i,h,ve) end

function target(i,h)
 x=vex
 if(h.u==0)h.u=0.2
 if(h.x>x+6)h.u=-abs(h.u)
 if(h.x<x-6)h.u=abs(h.u)
 cross(i,h) end

-- return vessel position to aim at
function vepos()
 if lpf then -- fixed
  local x,y=vex,vey
  return function()
   return x,y
  end
 elseif lpa then -- late position
  return function()
   local p=lp[(lp.i-3)%4+1]
   return p.x,p.y
  end
 else -- current position
  return function()
   return vex,vey
  end
 end
end

-- ============================
-- shape fire

function arc(
a,--0.5..0=circle,point
s)--spirale
local vepos=vepos()
return function(i,q,j,f)
 h=q.h
 m,n=h.u,h.v
 local x,y=vepos()
 local o=boss and 10 or 5
 if(q.w)m,n=aim(h.x,h.y,x,y)
 r=(((2*j)-1)/q.c-1)*a
 u,v=rot(m,n,r+(q.z*s))
 bx,by=h.x+u*o,h.y+v*o
 return true,bx,by,u*q.s,v*q.s end
end

-- ============================
-- level

function apply(t)
 if(#leh<1)return
 for i in all(leh)do
  if boss then
   h=bo[i]
  else
   h=hs[i]
  end
  if h and h.a then
   if t==5 or t==6 then
    h.t=h.t+0.006*(((t-4)*2)-3)
    h.m=curve
   --slower ship
   elseif t==7 then
    h.s-=0.25
   --stop ship
   elseif t==8 then
    h.s=0
   --faster ship
   elseif t==9 then
    if h.s==0 then
     h.s=0.5
    else
     h.s+=0.25
    end
   --movement ship
   elseif t==45 then
    h.m=retreat
   elseif t==46 then
    h.m=flee
   elseif t==47 then
    h.m=cross
   elseif t==62 then
    h.m=target
   --fire shape
   elseif t>=1 and t<=4 then
    local s=lebn
    if s==arc then
     s=s(leaa,leas)
    end
    fire(h,lec,led,let,s,
    lebm,lebs,lebf,lew)
    lebt=1
   end
   if t==46 or t==47 or t==63 or (t>=1 and t<=9) then
    lem=false
   end
  end
 end
 return true
end

--function findt()
-- for i=1,100 do
--  local x,y=(lea+i)%128,(lea+i)/128
--  if mget(x,y)==78 then
--   return flr(lea+i)
--  end
-- end
--end

function level()
 lea+=0.25
 if flr(lea)==lea then
  x,y=lea%128,lea/128
  t=mget(x,y)
  if t==111 then
   scene,vel,veb=upd,false,false
   anim=win()
   sfx(-2,0)
   for i=1,qs.l do
    qs[i].n=none
    qs[i].t=0
   end
  --boss waiting position
  elseif t==94 then
   if box~=bou
   or boy~=bov then
    lea-=1
   end
  --position and direction
  elseif t==40 then
   bou,bov,lex,ley,leu,lev
   =0,30,0,-18,0,1
  elseif t==41 then
   bou,bov,lex,ley,leu,lev
   =-25,30,-40,-18,0,1
  elseif t==42 then
   bou,bov,lex,ley,leu,lev
   =25,30,40,-18,0,1
  elseif t==43 then
   bou,bov,lex,ley,leu,lev
   =20,44,-70,-18,0.7,0.7
  elseif t==44 then
   bou,bov,lex,ley,leu,lev
   =-20,44,80,-18,-0.7,0.7
  elseif t==56 then
   bou,bov,lex,ley,leu,lev
   =30,34,-82,40,1.0,0
  elseif t==57 then
   bou,bov,lex,ley,leu,lev
   =-30,34,82,40,-1.0,0
  elseif t==58 then
   bou,bov,lex,ley,leu,lev
   =30,24,-82,20,1.0,0
  elseif t==59 then
   bou,bov,lex,ley,leu,lev
   =-30,24,82,20,-1.0,0
  --ship movement
  elseif t==47 then
   if(not apply(t))lesm=cross
  elseif t==46 then
   if(not apply(t))lesm=flee
  elseif t==62 then
   if(not apply(t))lesm=target
  elseif t==45 then
   apply(t)
  --ship rotation
  elseif t==5 then
   if not apply(t) then
    leu,lev=rot(leu,lev,-0.05)
   end
  elseif t==6 then
   if not apply(t) then
    leu,lev=rot(leu,lev,0.05)
   end
  --ship speed
  elseif t==7 then
   if boss then
    bos=0.25
   elseif not apply(t) then
    less=lel==7 and 0.85 or 0.75
   end
  elseif t==8 then
   if boss then
    bos=0.5
   elseif not apply(t) then
    less=lel==8 and 1.5 or 1
   end
  elseif t==9 then
   if boss then
    bos=1.5
   elseif not apply(t) then
    less=lel==9 and 2.5 or 2
   end
  --boss hp
  elseif t==79 then
   bom+=100
   bob+=100
   boi+=2
   boa=true
  --developer markers
  elseif t==24 then
   for ii=1,1000 do
    local xx,yy=(lea+ii)%128,(lea+ii)/128
    if mget(xx,yy)==25 then
     lea=flr(lea+ii)
     break
    end
   end
  elseif t==26 then
   slow=1
  elseif t==27 then
   slow=-1
  --markers
  elseif t==78 then
   if lema==0 then
    lema,lec,led,let
    =lea,0,0,0
   else
    lerk=lea
    lea=lema
   end
  --hp, score, ship frame
  elseif t==131 or t==163 then
   leb,ler,lesf=5,550,t>159 and 163 or 131
  elseif t==147 or t==179 then
   leb,ler,lesf=7,800,t>159 and 163 or 131
  elseif t==130 or t==161 then
   leb,ler,lesf=12,1000,t>159 and 161 or 130
  elseif t==146 or t==177 then
   leb,ler,lesf=18,1500,t>159 and 161 or 130
  elseif t==129 or t==160 then
   leb,ler,lesf=30,3000,t>159 and 160 or 129
  elseif t==145 or t==176 then
   leb,ler,lesf=40,4000,t>159 and 160 or 129
  elseif t==128 or t==162 then
   leb,ler,lesf=70,8000,t>159 and 162 or 128
  elseif t==144 or t==178 then
   leb,ler,lesf=90,10000,t>159 and 162 or 128
  --boss arrive! distance from canon
  elseif t==127 then
   boss,wa,box,boy,bou,bov
   =true,1,0,-50,0,30
  --arc angle
  elseif t==28 then
   leaa=0.5
  elseif t==29 then
   leaa=0.25
  elseif t==30 then
   leaa=0.125
  elseif t==31 then
   leaa=0.0625
  --arc spirale
  elseif t==60 then
   leas-=0.01
  elseif t==61 then
   leas+=0.01
  --bullet movement
  elseif t==34 then
   lebm=none
  elseif t==16 then
   lebm=roundexpl(0.02,110)
  elseif t==51 then
   lpa=true
  elseif t==90 then
   lpf=true
  --bullet frame, bullet speed
  elseif t==1 then
   lebf,lebs=1,1.5
   apply(t)
  elseif t==2 then
   lebf,lebs=2,3
   apply(t)
  elseif t==3 then
   lebf,lebs=3,4
   apply(t)
  elseif t==4 then
   lebf,lebs=4,2
   apply(t)
  --aim mode
  elseif t==33 then
   lew,lpa,lpf
   =false,false,false
  elseif t==49 then
   lew,lpa,lpf
   =true,false,false
  end
  --arc
  if t>=28 and t<=31 then
   lebn,leas=arc,0
  --cancel selection
  elseif t==0 then
   lem,leh=false,{}
  --multiple selection
  elseif t==63 then
   lem=true
  --select spawned ship
  elseif t>=10 and t<=15 then
   if(not lem)leh={}
   if boss then
    -- todo: put the ship object directly
    add(leh,(t-9))
   else
    -- todo: put the ship object directly
    add(leh,(hs.g+8-t)%hs.l+1)
   end
  --fake spawn ship
  elseif t==32 then
   next(hs)
  --spawn ship
  elseif (t>=128 and t<=131)
  or (t>=144 and t<=147) 
  or (t>=160 and t<=163)
  or (t>=176 and t<=179) then
   spawn(lex,ley,leu,lev,
   lesf,less,lesm,leb,ler)
  --count,delay,repeat x10
  elseif t>=96 and t<=105 then
   local v=(t-96)*10
   if lebt==1 then
    lec=v
   elseif lebt==2 then
    led=v
   elseif lebt==3 then
    let=v
   end
  --count,delay,repeat x1
  elseif t>=112 and t<=121 then
   local v=(t-112)
   if lebt==1 then
    lec=flr(lec/10)*10+v
   elseif lebt==2 then
    led=flr(led/10)*10+v
   elseif lebt==3 then
    let=flr(let/10)*10+v
   end
   lebt=lebt%3+1
  end
  lel=t
 end
end

-- ============================
-- particle functions

function beam(i,p)
 if p.z<3 then
  x,y
  =(i%p.z-4)*0.5,(p.z-3)*0.5
  sprite(p.x+x,p.y+y,20,glitter)
 else p.f=none end end

function lazer(i,p)
 if p.z<3 then
  x,y
  =(i%p.z-4)*0.5,(p.z-3)*0.5
  sprite(p.x+x,p.y+y,20,firin)
 else p.f=none end end

function dart(i,p)
 u,v=-61,124-vep
 x,y=(p.x+u)/2,(p.y+v)/2
 if p.z==0 then
  line(p.x,p.y,x,y,12)
 elseif p.z<3 then
  line(x,y,u,v,12)
  line(p.x,p.y,x,y,1)
  p.x,p.y=x,y
 elseif p.z==3 then
  line(x,y,u,v,12)
  line(p.x,p.y,x,y,1)
 else
  p.f=none
 end
end

function stars(i,p)
 if p.y<280 then
  if i<3 then
   p.x+=9
   p.y+=18
   line(p.x,p.y,p.x+3,p.y+7,5)
   line(p.x+4,p.y+8,p.x+7,
   p.y+15,6)
   line(p.x+8,p.y+16,p.x+11,
   p.y+23,7)
  elseif i<7 then
   p.x+=6
   p.y+=12
   line(p.x,p.y,p.x+1,p.y+3,1)
   line(p.x+2,p.y+4,p.x+3,
   p.y+7,13)
   line(p.x+4,p.y+8,p.x+5,
   p.y+11,12)
  else
   p.x+=2
   p.y+=4
   pset(p.x,p.y+12,5)
  end
 else 
  p.f=none
end
end

function point(c)
 c=max(1,c/100)
 return function(i,p)
  if p.z<c then
   poa+=1
   sprite(p.x,p.y,24,gotoscore)
  else p.f=none end
 end
end

function hit(c)
 return function(i,p)
  if p.z<4 then
   sprite(p.x,p.y,24,gotohit)
  else p.f=none end
 end
end

function explosion(i,p)
 if p.z<20 then
  if p.z<(10+i%3) and (
   p.z%4==1 or p.z%3==1) then
   x,y,r
   =rnd(12)*2-12,rnd(8)*2-8,i%12+8
   front(p.x+x,p.y+y,r,7,bang)
  end
  if p.z<12 and
   (p.z%2==1 or p.z%3==1) then
   x,y
   =rnd(4)*2-4,rnd(4)-2
   sprite(p.x+x,p.y+y,20,flick)
  end
  if p.z>7 and p.z<20 and (
   p.z%4==1 or p.z%5==1
   ) then
   x,y,r
   =rnd(12)*2-12,rnd(8)*3-12,i%4+6
   back(p.x+x,p.y+y,r,1,smoke)
  end
 else p.f=none end end

function gotoscore(i,s)
 u,v=aim(s.x,s.y,58-rnd()*20,6+rnd()*4)
 s.x+=u*min(15,s.z+i)*0.7
 s.y+=v*min(15,s.z+i)*0.6
 pal(8,1)pal(2,12)pal(7,13)
 if s.z==15 then
  s.f,s.y=none,-128
 else
  poa+=1
 end
end

function gotohit(i,s)
 u,v=aim(s.x,s.y,-30,12)
 s.x+=u*s.z*0.3
 s.y+=v*s.z*0.3
 pal(8,4)pal(2,9)pal(7,10)
 if(s.z==30) s.f,s.y=none,-128 end

function glitter(i,s)
 s.x+=0.124*i-2
 s.y+=s.z-2
 if(s.z==9) s.f,s.y=none,-128 end

function firin(i,s)
 glitter(i,s)
 pal(11,12)pal(3,13) end

function flick(i,s)
 glitter(i,s)
 pal(11,9)pal(3,4) end

function smoke(i,p)
 p.y-=0.25
 p.y+=(i-16)*0.01
 p.r+=((i%4)+2)*0.03
 if p.z==(i%14)+18 then
  p.f=none p.y=-64 end end

function bang(i,p)
 p.x+=(p.z%3)-1
 if p.z==0 then p.c=0
 elseif p.z==1 then p.c=10
 elseif p.r>17 then p.r-=4 p.c=10
 elseif p.r>5 then p.r-=3 p.c=6
 elseif p.r>3 then p.r-=2 p.c=6
 else p.f=none p.y=-64 end end

--todo: can be transformed
--to an anim
function die(i,p)
 p.y+=0.1
 if p.z<30 then
  x=rnd()*2-1
  --xxx: weird, normally
  --vessel should always be
  --drawn
  spr(32,p.x-8+x,p.y-11,1,2)
  spr(32,p.x+x,p.y-11,1,2,true)
 end
 if(p.z==0)sfx(1,1)sfx(4,0)
 if p.z<16 then
  for i=0.25,1,0.25 do
   x,y=rot(-130,0,
   i+rnd()/80+p.z/400)
   line(p.x,p.y,p.x+x,p.y+y,7)
   for j=-1,1 do
    line(p.x-j/2,p.y+j/2,p.x+x-j,p.y+y+j,7)
    line(p.x+j/2,p.y+j/2,p.x+x+j,p.y+y+j,6)
   end
  end
  x=rnd()*2-1
  circ(p.x+x,p.y,30-p.z,7)
  circ(p.x+x,p.y,31.25-p.z,6)
  circ(p.x+x,p.y,32.5-p.z,7)
 elseif p.z==16 or p.z==18 then
  cls(7)
 elseif p.z==17 then
  cls()
 elseif p.z<30 then
  x,y=rnd()*2-1,rnd()*2-1
  circfill(p.x+x*2,p.y+y*2,45-p.z/2,6)
  circfill(p.x+x,p.y+y,40-p.z/2,7)
 elseif p.z==30 or p.z==33
 or p.z==37 then
  if(p.z==30)sfx(-2,0)sfx(-2,1)
  sfx(5)
  effect(p.x,p.y,explosion)
 elseif p.z==50 then
  sfx(-1)
 elseif p.z==41 then
  p.f=none
 end
end

function palrot(from,to)
local a,l=1,#to
return function(s)
 for i,c in pairs(from) do
  pal(from[i],to[flr(i+a)%l+1])
 end
 a=a%l+s
end
end

-- ============================
-- ennemy function

function shoot(x,y,u,v,f,m)
 b=bs[bs.g] next(bs)
 b.x,b.y,b.u,b.v,b.f,b.z,b.m
 =x,y,u,v,f,0,m end

-- h= ship/cannon object
-- c= bullet count this frame
-- d= frame delay
-- t= repeat x times
-- n= shape function
-- m= movement function
-- s= speed
-- f= frame tile index
-- w= aim follow mode
function fire(h,c,d,t,n,m,s,
f,w)
 h.q=qs.g
 q=qs[qs.g] next(qs)
 q.c,q.d,q.e,q.t,q.n,q.m,q.s,
 q.w,q.z,q.h,q.f
 =bcount(c),0,d,t,n,m,
 s,w,0,h,f end

-- x,y= position
-- u,v= direction
-- f= frame tile index
-- s= speed
-- o= distance from cannon
-- m= movement function
-- b= hp
-- r= base score when destroyed
function spawn(x,y,u,v,f,s,m,
b,r)
 h=hs[hs.g] next(hs)
 h.x,h.y,h.u,h.v,h.f,h.s,
 h.m,h.a,h.b,h.d,h.e,h.c,h.z,
 h.r,h.t
 =x,y,u,v,f,s,m,true,
 flr(b*.7),0,b,0,0,r,0
 return h end

function damage(h,v,qs)
 if boss then
  if bob>0 then
   for i=1,6 do
    sco(min(32000,h[i].c))
   end
   bob-=v
  elseif boa then
   -- fixme lerk can be nil
   -- search for the next mark
   -- fixme avoid to overflow
   for i=1,100 do
    local x,y=(lea+i)%128,(lea+i)/128
    if mget(x,y)==78 then
     lerk=flr(lea+i)
     break
    end
   end
   lea=lerk
   lerk,lema=0,0
   bom,boa,boi=0,false,4
   lebt,lec,led,let=1,0,0,0
   for i=1,6 do
    local b=bo[i]
    if(b.q>0)qs[b.q].t=0
   end
   for i=1,6 do
    sco(max(0,32000-lez))
   end
  end
 elseif h.c then
  if h.b>0
  then h.b-=v h.d=6
  else
   kill(h)
   locald(h.x,h.y,h.r/2,h.r/100)
  end
 end
end

function locald(x,y,s,z)
 l=lo[lo.g] next(lo)
 l.x,l.y,l.s,l.z=x,y,s,z end

function kill(h)
 effect(h.x,h.y,explosion)
 effect(h.x,h.y,point(h.r))
 sfx(5)
 h.b,h.m,h.a=0,none,false
 if(qs[h.q])qs[h.q].t=0
 sco(max(99,(h.c*333)-h.z+h.r))
 if(h.q>0)qs[h.q].t=0
 if vep<uipo-3 then
  effect(h.x,h.y,hit(h.r))
  if hitv<999 then
   hitv+=1
   if hitg[3]<9 then
    hitg[3]+=1
   else
    hitg[3]=0
    if hitg[2]<9 then
     hitg[2]+=1
    else
     hitg[2]=0
     if hitg[1]<9 then
      hitg[1]+=1
     end
    end
   end
  end
  extend(i)
  hitd=50
 end
end

function dead()
 vea,veb,vel=false,false,false
 effect(vex,vey,die,0)
 vex,vey=0,140
 anim=arrive(110)
end

-- ============================
-- emitter

function effect(x,y,f,i)
 p=pp[i or pp.g] next(pp)
 p.x,p.y,p.f,p.z
 =x,y,f,0 end

function sprite(x,y,t,f)
 s=sp[sp.g] next(sp)
 s.x,s.y,s.t,s.a,s.f,s.z,s.d
 =x,y,t,0,f,0,3 end

function back(x,y,r,c,f)
 p=bp[bp.g] next(bp)
 p.x,p.y,p.r,p.c,p.f,p.z
 =x,y,r,c,f,0 end

function front(x,y,r,c,f)
 p=fp[fp.g] next(fp)
 p.x,p.y,p.r,p.c,p.f,p.z
 =x,y,r,c,f,0 end

-- ============================
-- gameplay

function sco(h)
 local i=8
 h=flr(h*(1+hitv/10))
 --printh("sco>32787")
 while h>0 do
  a=h%10
  if(scos[i]+a>9)h+=10
  scos[i]=(scos[i]+a)%10
  h=flr(h/10) i-=1
 end
 local b=false
 for i=1,8 do
  if scos[i]>best[i] then
   b=true
  end
 end
 if b then
  for i=1,8 do
   best[i]=scos[i]
   dset(i,scos[i])
  end
 end
end

function power(p)
 if vep<uipo and p>0.125
 and lez%5==0 then
  effect(vex,vey,dart)
 end
 vep=min(uipo,vep+p+hitv/100)
end

function extend(p)
 uipo=min(80,uipo+1) end

function slottoscore(s)
 local a,n,t,v
 =0x5e00+12*s,3*s+1,{}
 for i=1,8 do
  if i%4==1 then
   v=dget(n)
   n-=1
  end
  t[i]=band(v,15)
  v=shr(v,4)
 end
 return t
end

--function scoretoslot(t,s)
-- local a,n,v=0x5e00+12*s,3*s,0
-- for i=8,1,-1 do
--  v=bor(shl(v,4),t[i])
--  if i%4==1 then
--   dset(n,v)
--   a+=4
--   n+=1
--   v=0
--  end
-- end
--end

function resetscore()
 for i=1,8 do scos[i]=0 end
end

function reset()
 -- lp=late postion of vessels,
 -- late position active
 -- fix late position
 -- lez=level frame counter
 -- lea=index of tile to read
 --=0,384,false,0,0,132 --1 boss
 --=0,768,false,0,0,164 --2
 -- lex,ley=ship position
 -- leu,lev=ship direction
 -- lesm=ship movement
 -- less=ship speed
 -- lesf=ship frame
 -- leb=base hp
 -- ler=base scare
 -- leh=selected ship for shoot
 -- settings
 -- lem=multi selection enable
 -- lep=consumed, will be reset
 -- lec=bullet count
 -- led=bullet delay
 -- let=bullet repeat
 -- lebn=shape
 -- leaa=arc angle
 -- leas=arc spirale
 -- lebm=bullet movement
 -- lebs=bullet speed
 -- lebz=bullet speed multiplyer
 -- lew=aim
 -- lebf=bullet frame
 -- lebt=bullet number state 
 -- 1=count 2=delay 3=repeat
 -- lel=old tile
 -- box,boy=position
 -- bou,bov=target position
 -- bos=speed
 -- boh=sel canon
 -- bob=real hp
 -- bom=max hp
 -- bod=disp hp
 -- boi=hp heal speed
 -- poa=point anim
 la,vex,vey,veu,vev,vea,veb,vez,
 ved,vel,ves,vep,vew,veg,lp,
 lpa,lpf,lez,boss,lema,lerk,
 boti,lex,ley,leu,lev,lesm,less,
 leb,ler,leh,lec,led,let,lebn,
 leaa,leas,lebm,lebs,lebz,lew,
 lesf,lebf,lebt,lem,lel,uipo,
 hitd,hitv,box,boy,bou,bov,bos,
 boh,bob,bod,bom,boa,boi,poa
 =16,0,140,0,0,false,false,0,
 false,false,3,10,40,false,{},
 false,false,0,false,0,0,
 132,0,-82,0,1,cross,1,
 5,0,{},1,0,1,arc,
 0,0,none,0,1,false,
 0,0,1,false,0,20,
 0,0,0,-50,0,30,0.5,
 1,0,0,0,false,4,0
 lp.i=1
 for i=1,4 do lp[i]={x=0,y=0} end
 -- ui
 for i=1,3 do hitg[i]=0 end
 -- x,y=pos from boss
 -- a=active (needed)
 -- u,v=canon dir
 -- o=?
 -- c=?
 for i=1,6 do
  local b={}
  bo[i]=b
  b.a,b.u,b.v,b.c,b.q,b.z
  =true,0,1,0,0,0
 end
 -- todo: change dir of canon: u,v
 -- todo: setup cannon for boss 2?
 bo[1].x,bo[1].y=-20,boy-5
 bo[2].x,bo[2].y=20,boy-5
 bo[3].x,bo[3].y=-22,boy+10
 bo[4].x,bo[4].y=22,boy+10
 bo[5].x,bo[5].y=0,boy-8
 bo[6].x,bo[6].y=0,boy+14
 wa=0
end

--debug
function mhere()dset(63,lea)run()end
function mhind()dset(63,max(0,lea-8))run()end
function mrese()dset(63,0)run()end

function arrive(wait)
 return cocreate(function()
  veg=true
  while wait>0 do
   wait-=1
   yield()
  end
  vex,vey=0,140
  while vey>101 do
   vey+=max(-5,(100-vey)/3)
   yield()
  end
  while vey<117 do
   vey+=min(3,(118-vey)/4)
   yield()
  end
  vea=true
  wait=30
  while wait>0 do
   wait-=1
   yield()
  end
  veg=false
  anim=false
 end)
end

function win()
 local t=0
 warmup()
 return cocreate(function()
  veg,vea=true,true
  for t=0,70 do
   y+=0.5
   sfx(8)
   if t%11==0 then
    sfx(5)
    effect(box+t*0.5-25+rnd(10),
    boy+(t*33)%20,explosion)
   end
   if t==50 then
    effect(box,boy+15,die,0)
    rectfill(-64,0,64,128,7)
   end
   if t==65 then
    boss=false
   end
   yield()
  end
  for t=0,20 do
   vev-=1
   vey+=vev
   rectfill(vex-2,vey+4,vex+1,
   128,7-max(t-18,0))
   sspr(64+(t%2)*24,16,24,16,
   vex-8,vey+4,15,12)
   yield()
  end
  for t=0,120 do
   spr(5,-20,70-t*0.25,5,1)
   yield()
  end
  if lea<768 then
   anim,scene=ranking(),title
   music(1,0,7)
  else
   anim,scene,lea=false,play,768
  end
  reset()
 end)
end

function present(st)
 local s,c,d,x,y,z,w,m,n,t
 =-st,{},{},70,283,0,1,0,0,0
 return cocreate(function()
  while true do
   if(y>43 and s>-10)y-=(y-43)/8
   camera(rnd(2)-1,rnd(3)-1)
   x+=w/4
   spr(203,x-8,y,5,3)
   spr(252,x,y+24,2,1)
   spr(249,x,y-8,3,1)
   spr(254,x-8,y-16,2,1)
   m=x+14
   n=y+27
   for i=1,10 do
    line(m+i,n,m+i+30,n+60
    ,i%9==1 and 6 or 7)
   end
   if(z==58)w=-w
   z=z%50+9
   spr(96,m+z/2-5,n+z)
   spr(97,m+z/2+2,n+z-8,2,1)
   spr((z%30)>15 and 40 or 43
   ,m-5,n-3,3,2)
   camera(-64,-64)
   if(s>-10)spr(192,-43,y-21,9,1)
   if(s>14)spr(201,-62,30,2,2)
   if(s>15)spr(224,-46,30,2,2)
   if(s>16)spr(226,-31,30,1,2)
   if(s>17)spr(226,-24,30,1,2,true)
   if(s>18)spr(227,-18,30,2,2)
   if(s>19)spr(229,-3,30,1,2)
   if(s>20)spr(229,4,30,1,2,true)
   if(s>21)spr(226,11,30,1,2)
   if(s>22)spr(226,18,30,1,2,true)
   if(s>23)spr(230,24,30,2,2)
   if(s>24)spr(232,39,30,1,2)
   if(s>25)spr(232,46,30,1,2,true)
   if(s>39)rectfill(-45,46,19,51,1)rectfill(23,46,39,51,1)print("\85\78\67\79\77\80\82\69\72\69\78\83\73\66\76\69 \90\69\82\79",-44,46,13)
   if(s>44)rectfill(-45,51,-21,56,1)rectfill(-17,51,11,56,1)print("\66\79\77\66\69\82 \70\73\71\72\84\69\82",-44,51,13)
   if(s<45)s=s+1
   if t==160 then
    anim=ranking()
   elseif btnp(5) then
    if s<45 then
     s,y=45,43
    else
     anim,scene,lea
     =false,play,0
     reset()
     music(-1,200)
     for i=1,pp.l do
      pp[i].f=none
     end
    end
   end
   t+=1
   yield()
  end
 end)
end

function sprtext(str,x,y)
 local num,c=""
 for i=1,#str do
  c=sub(str,i,i)
  if c=="," then
   spr(tonum(num),x,y)
   x+=7
   num=""
  else
   num=num..c
  end
 end
end

function ranking()
 local h,z=-130,0
 score(scos,-12,20)
 return cocreate(function()
  while true do
   z+=1
   camera(-40,h)
   sprtext("33,34,35,49,50,35,51,",0,0)
   print("last",-4,14,13)
   score(scos,-12,20)
   print("best",-4,30,13)
   score(best,-12,36)
   sprtext("28,33,29,30,50,31,46,",0,50)
   print("title screen art",-5,63,13)
   print("radigo",12,70,6)
   print("everything else",-3,83,13)
   print("moechofe",9,90,6)
   print("tests & qa",5,103,13)
   print("david cruau",3,110,6)
   if btnp(5) then
    if h<-8 then
     h=-8
    else
     anim=present(5)
    end
   end
   if z>100 then
    if h<110 then
     h+=z/6
    else
     anim=present(5)
    end
   else
    if(h<-8)h+=(-h+8)/6
   end
   yield()
  end
 end)
end

anim=false
function play()
 if vea then
  ctr()
 elseif not anim then
  anim=arrive(10)
 end
 upd()
 -- update level,spawn ship
 level() lez+=1
end

titlerotpal=palrot({1,2,14},{1,2,14,15,13,12})

tz=0
function title()
 if(not anim)anim=present(55)
 tz=tz%2+1
 if tz==1 then
  effect(rnd()*-128+20,-20
  ,stars)
 end
 pat(true)
end

function ctr()
 -- move vessel
 veu,vev=0,0
 if(btn(0))veu-=ves
 if(btn(1))veu+=ves
 if(btn(2))vev-=ves
 if(btn(3))vev+=ves
 -- shoot beam/lazer
 if vea and btn(4) then
  if(not vel and vep>5.75)vel,ves=true,2 sfx(6,0) -- fixme: ves=2 !!!???
  if(vep<0)vel,ves=false,3 sfx(-2,0)
 else
  if(vel)vel,ves=false,3 sfx(-2,0)
 end
 if vea and btn(5) and not vel then
  if(not veb)veb,ves=true,3 sfx(0,0)
 else
  if veb then
   veb,bed=false,0
   if(not vel)sfx(-2,0) ves=3
  end
 end
 lp[lp.i].x=vex
 lp[lp.i].y=vey
 lp.i=(lp.i%4)+1
 vex=mid(-60,60,vex+veu)
 vey=mid(4,126,vey+vev)
end

function pat(canshoot)
 -- update shape,shoot bullet
 for i=1,qs.l do
  q=qs[i] q.z+=1
  if q.t>0 then
   w=ang(q.h.x,q.h.y,vex,vey)
   if q.d>0 then q.d-=1
   else q.d=q.e
    for j=1,q.c do
     a,x,y,u,v
     =q.n(i,q,j,w)
     if(vea or canshoot)shoot(x,y,u,v,q.f,q.m)
     q.h.c+=1 end
    q.t=(q.t==1)and -1or q.t-1
   end
  end
 end
 -- update particle
 for i=0,pp.l do
  local p=pp[i]
  p.f(i,p) p.z+=1
 end
 -- draw particles
 for i=1,32 do
  local b=bp[i]
  b.f(i,b)
  circfill(b.x,b.y,b.r,b.c)
  b.z+=1
 end
 for i=1,32 do
  local s,f=sp[i],fp[i]
  s.f(i,s)
  spr(s.t+s.a,s.x-3,s.y-3)
  pal()
  if s.d==0 then
   s.d=1
   s.a=(s.a==3)and 0or s.a+1
  else s.d-=1 end
  s.z+=1
  f.f(i,f)
  circfill(f.x,f.y,f.r,f.c)
  f.z+=1
 end
end

function bul()
 -- update,draw bullet
 for i=1,bs.l do
  b=bs[i]
  spr(b.f,b.x-3,b.y-3)
  b.x+=b.u b.y+=b.v
  b.m(i,b)
  local d=dis(b.x-3,b.y-3,vex-4,vey-3)
  if vea and d>0 and not veg then
   --debug
   if(d<6)dead()
   --todo reduce the distance
   --of touch
   if d<200 then
    ved=true
    power(0.375)
   end
  end
  if b.x<-72 or b.x>72
  or b.y<-16 or b.y>142 then
   b.m,b.y,b.x=none,0,160 end
 end
end

function score(d,x,y)
 poa=max(0,poa-flr(poa/2+1))
 por=false
 for i=1,8 do
  local v=por and rnd(9) or d[i]
  spr(112+v,i*7+x,y)
  por=(v>0 and poa>0) and true or false
 end
end

function upd()
 ved=false
 -- draw score
 score(scos,-8,1)
 -- draw lazerbar
 spr(74,-65,122-uipo)
 spr(75,-65,111,1,2)
 line(-63,115,-63,126-uipo,1)
 line(-59,119,-59,130-uipo,1)
 for i=0,2 do
  if vep>0.125 then
   c=12
   if(vep<5)c=6
   if(vep>uipo-3.25)c=8
   line(-62+i,123+i,-62+i,123+i-vep,c)
  end
 end
 -- draw hit
 if hitd>0 then
  if hitd>48 then
   pal(2,7)pal(14,5)pal(4,5)
  end
  hitd-=1
  for i=1,3 do
   spr(64+hitg[i],-72+i*9,1,1,2)
  end
  spr(76,-36,1,2,2)
  pal()
 end
 if wa>0 and wa<120 then
  if(wa>1 and wa<3)pal(9,7)
  print("here he comes",-56,29,9)
  pal()
  if(wa>20 and wa<23)pal(8,7)pal(2,6)
  if(wa>20)sspr(80,48,40,16,-56,38,96,32)sspr(114,48,6,16,39,38,16,32)
  pal()
  local wa9=wa%9
  if(wa>40 and wa<43 or wa>114)pal(6,7)
  --if(wa>40 and wa<116)print("100% bullets storm",-56,72,6)
  --if(wa>50 and wa<53 or wa>112)pal(6,7)
  --if(wa>50 and wa<114)print("#"..flr(wa/9%9).."."..wa9..wa9..wa9.."\x8132767\x99"..(shl(1,wa)%9).."\x80mk2",-56,79,6)
  --if(wa>60 and wa<63 or wa>110)pal(6,7)
  --if(wa>60 and wa<112)print("he is tough!!!",-56,86,6)
  pal()
  wa+=1
 end
 -- update,draw boss
 if boss then
  -- hp
  d=bob-bod
  if d>4 then
   bod+=boi
  elseif d<-2 then
   bod-=2
  else
   bod=bob
  end
  rectfill(-54,11,54,13,2)
  if bod>0 then
   rectfill(-54,11,bod/bom*116-54,13,8)
  end
  -- compute direction using target
  bd=dis(box,boy,bou,bov)
  if bd<-1 or bd>1 then
   bu,bv=nor(aim(box,boy,bou,bov))
   bu,bv=bu*bos,bv*bos
   box+=bu
   boy+=bv
   for i=1,6 do
    bo[i].x+=bu
    bo[i].y+=bv
   end
  else
   box=bou
   boy=bov
  end
  x,y=box,boy
  spr(boti,x-32,y-16,4,2)
  spr(boti+4,x-32,y+0,4,2)
  spr(boti+8,x-32,y+16,4,2)
  spr(boti,x,y-16,4,2,true)
  spr(boti+4,x,y+0,4,2,true)
  spr(boti+8,x,y+16,4,2,true)
 end
 -- update,draw ship
 for i=1,hs.l do
  h=hs[i]
  if h.a then
   if h.x<-96 or h.x>96
   or h.y>160 or h.y<-32 then
    h.m,h.x,h.a
    =none,-128,false
   else
    h.m(i,h)
    spr(h.f,h.x-8,h.y-7,1,2)
    spr(h.f,h.x,h.y-7,1,2,true)
    if h.d>0 then
     h.d-=1
     line(h.x-6,h.y-9,h.x+6,h.y-9,3)
     local b=(h.b/h.e)*12
     if(b>0)line(h.x-6,h.y-9,h.x-6+b,h.y-9,11)
    end
   end
  end
 end
 pat()
 -- update,draw vessel
 if veg and lez%4>1 then
  pal(10,7) pal(9,7)
  pal(4,7) pal(12,7)
  pal(13,7) pal(1,7)
  pal(2,7) pal(5,7)
 end
 spr(32,vex-8,vey-11,1,2)
 spr(32,vex,vey-11,1,2,true)
 pal()
 -- update beam
 if veb then
  if bed==0 then
   bed=bee
   for j=0,1 do
    b=be[be.g]
    be.g=(be.g==be.l)and 1or be.g+1
    b.x=vex-8*j
    b.y=vey-24
   end
  else bed-=1 end
  spr(16+bef,vex-11,vey-16)
  spr(16+(bef+2)%4,vex+3,vey-16,1,1,true)
  bef=(bef+1)%4
 end
 -- draw beam
 s2=false
 for i=1,be.l do
  b=be[i]
  if b.y>-16 then
   spr(36+((i+lez)%2),b.x,b.y,1,2)
   if boss then
    -- collision with boss
    d=dis(box-4,boy-8,b.x,b.y)
    if d>0 and d<700 then
     if(not s2)sfx(2) s2=true
     effect(b.x+8,b.y+16,beam)
     b.y=-128
     damage(bo,1,qs)
    end
   else
    -- collision with ship
    for j=1,hs.l do
     h=hs[j]
     if h.a then
      d=dis(h.x-4,h.y-8,b.x,b.y)
      if d>0 and d<70 then
       if(not s2)sfx(2) s2=true
       effect(b.x+8,b.y+16,beam)
       b.y=-128
       damage(h,1,qs)
      end
     end
    end
   end
   b.y-=9
  end
 end
 -- draw lazer
 if vel then
  x,y,t,i=vex,vey,-16,false
  yy,hh=-99,false
  if boss then
   -- collision with boss
   if box>x-30 and box<x+31 then
    sfx(2)
    hh,yy=bo,boy-10
    if box>x-6 and box<x+7 then
     yy=boy+10
    elseif box>x-20 and box<x+21 then
     yy=boy+4
    end
   end
  else
   -- collision with ship
   for j=1,hs.l do
    h=hs[j]
    if h.a then
     if h.y<y-22 and h.x>x-11
     and h.x<x+12
     and h.y>yy then
      yy,hh=h.y-10,h
     end
    end
   end
  end
  if hh then
   effect(x,yy+16,lazer)
   i,t=j,yy+6
  end
  ld=1.4
  -- fixme: duplicated
  if vep>uipo-3.25 then
   if(la==16)la=25
   ld=1.7
   pal(7,0)pal(12,8)pal(6,2)
  end
  la=max(16,la-1)
  if hh then
   sfx(7)
   damage(hh,ld,qs)
  end
  local lh=(lez%2==0)
  sspr(48,21,16,3,x-la/2,t+16,la,y-t-24,lh,false)
  sspr(48,24,16,8,x-la/2,y-16,la,8,lh,false)
  if(hh)sspr(48,16,16,8,x-la/2,t+8,la,8,lh,false)
  pal()palt()
  vep=max(-1,vep-1)
 else
  power(0.0625)
 end
 bul()
 -- draw vessel colision
 if ved then
  vez=(vez==3)and 0or vez+1
  spr(24+vez,vex-4,vey-3)
 end
 -- apply local damage
 for i=1,lo.l do
  l=lo[i]
  if l.z>0 then
   l.z-=3
   for j=1,hs.l do
    local h=hs[j]
    if h.a
    and dis(l.x,l.y,h.x,h.y)<l.s
    then
     damage(h,2,qs)
    end
   end
  end
 end
end

scene=title
music(1)

cartdata("moechofe_md_1")
--debug
printh("==========fresh start")
menuitem(1,"mark here",mhere)
menuitem(2,"mark behind",mhind)
menuitem(3,"reset mark",mrese)

function warmup()
 -- bullet warpup
 for i=1,bs.l do
  b={} bs[i]=b
  b.x,b.y,b.u,b.v,b.f,b.z,b.m
  =-28,-28,0,0,0,0,none
 end
 -- shape warmup
 for i=1,qs.l do
  q={} qs[i]=q
  q.c,q.d,q.e,q.t,q.f,q.n,q.m,
  q.s,q.h,q.z,q.w
  =0,0,0,-1,0,none,none,0.0,
  false,0,false
 end
end

function _init()
 warmup()
 -- ship warmup
 for i=1,hs.l do
  h={} hs[i]=h
  h.x,h.y,h.u,h.v,h.f,h.s,
  h.m,h.a,h.b,h.d,h.e,h.c,h.z,
  h.r,h.q,h.t
  =-128,0,0,0,0,0,none,false,
  0,0,0,0,0,0,0,0
 end
 -- local damage warmup
 for i=1,lo.l do
  l={} lo[i]=l
  l.x,l.y,l.s,l.z=0,0,0,0
 end
 -- beam warmup
 for i=1,be.l do
  b={} be[i]=b
  b.x,b.y,b.f=0,-128,0
 end
 -- particle warmup
 for i=0,pp.l do
  p={} pp[i]=p
  p.x,p.y,p.z,p.f
  =0,0,0,none
 end
 -- sprite particle warmup
 for i=1,sp.l do
  s,b,f,l={},{},{},{}
  sp[i],bp[i],fp[i]
  =s,b,f
  s.x,s.y,s.f,s.z,s.f,s.t,s.d,
  s.a,b.x,b.y,b.c,b.r,b.f,b.z,
  f.x,f.y,f.c,f.r,f.f,f.z
  =0,-64,none,0,0,0,0,0,0,-64,
  0,0,none,0,0,-64,0,0,none,0
 end
 -- score
 for i=1,8 do
  scos[i]=0
   best[i]=dget(i)
 end
 --debug
 if false then
  reset()
  scene=play
  music(-1)
  lea=dget(63)
 end
end

function _draw()
 camera(-64,0) 
 if slow==1 then
  slow=0
 else
  cls()scene()
  if(anim and costatus(anim))coresume(anim)
  if(slow==0)slow=1
 end
 print(err,-57,122,8)
 --debug
 if false and lez then
  --print("m"..flr(stat(0)).." c"..flr(stat(1)*1000)/1000,-57,115,7)
  --print("z"..lez..">"..flr(lea),0,115,9)
  x,y=lea%128,flr(lea/128)
  map(x-8,y,-68,17,32,1)
  --print("x,y:"..flr(x)..","..flr(y),0,109,8)
  --print("cdt:"..lec..","..led..","..let,0,121,10)
  spr(95,-7,14)
  spr(95,-2,14,1,1,true)
  spr(95,-7,19,1,1,false,true)
  spr(95,-2,19,1,1,true,true)
 end
end

__gfx__
0000000000eee0000088800001111100009990001110111111111110111111000111110111111000000111100001111000011110000111000001111000011110
000000000e222e0008f7f80011ccc11009aaa90017101711777117101711711111717101777711000001cc100001cc100001cc100001c1000001cc100001cc10
00000000e21112e08f777f801c777c109af7fa90171017171117171017117117117111017111710011111c1011111c1011111c101111c1101111c1101111c110
00000000e21112e0877777801c777c109a777a9017101717001717101711711711717101710171001cc11c101cc1cc101cc1cc101cc1cc101cc1cc101cc1cc10
00000000e21112e08f777f801c777c109af7fa90171117170017171017117117117171017101710011111c101111c11011111c1011111c1011111c101111cc10
000000000e222e0008f7f80011ccc11009aaa900117777171117171117117117117171117101710000001c100001cc100001cc1000001c100001cc100001cc10
0000000000eee0000088800001111100009990001111171177711177711117717711177171017100000011100001111000011110000011100001111000011110
00000000000000000000000000000000000000001777711111110111110011111110111111011100000000000000000000000000000000000000000000000000
00003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002222220222222202222222022222222
000000b0000000bb00000b000000b300000000000000000000000000000000000000000000000000000000000000000022888822288888822888882028888882
00b00bbb00000b7b00007b300007b30000070000000b00000003000000050000000880000008800000000000000000002ee22ee22ee222222ee22ee2222ee222
00000b770000b773000b7b3000bb30300077700000b7b000003b300000535000008228000087780000077000000220002ff222222ffff2222ff22ff2002ff200
0b00b77b0000b7b30007b330007b300000070000000b00000003000000050000008228000087780000077000000220002ff222222ff222222ff22ff2002ff200
0000b773000b773000b7330000b3030000000000000000000000000000000000000880000008800000000000000000002ee22ee22ee222222ee22ee2002ee200
0000b7b3000b7b30000b300000003000000000000000000000000000000000000000000000000000000000000000000022888822288888822888882200288200
0000b7300000b3000000000000000000000000000000000000000000000000000000000000000000000000000000000002222220222222222222222000222200
000000c022222220022222202222222200033000000330000ccc000c0cccc00c0000000677777777666000000000000677777777660000000222222000000000
000000c02888882222888822288228820033330000333300ccccccc0cc7ccc000000770777777777776660000000770777777777776600002288882005000500
000000c02ee22ee22ee22ee22eee2ee203bbbb3003bbbb300cccc7ccc7c7ccc00006777777777777777766600000677777776777776666002ee2222200606000
00000ac02ff22ff22ff22ff22ff2fff203b77b3003b77b30000c77777c7cc00c00676777777777777766600000006777777777777777776622ffff2200070000
c0000ac02fffff222ffffff22ff22ff203b77b3003b77b3000ccc767777cc00000766776677767776776000000067677777777777766666022222ff270707070
c000a9c02ee22ee22ee22ee22ee22ee203b77b3003b77b30000cc767777cc0000660677667776777666666000067667767776777767600002ee22ee276000670
c00aacc028822882288228822882288203bb7b3003b77b30000cc767777cc0000600677667776676760000060066606767766777666760002288882277707770
cc094cd1222222222222222222222222003bbb3003b7bb30000cc767777cc0006000676667766676760000000600006766766767666676000222222000000000
dc004d94222222220222222002222220003bbb3003bbbb30000cc767777cc0000000676067766666676000006000606766766677666066000000005011111110
dcc01141288228820288882022888820003bb300033bb30000cc7767777cc000000067606676606667600000000000666676667766660000000706001c1c1c10
d1c12d122ee2ee22022ee2202ee22222003bb300003b30300cc777677777cc00000066000676000066760000000600660666067760060006000760001c1c1c10
0d1c22212ffff220002ff2002ff2fff20003b300003330300c77777777c77cc000006600066600000066000000000066006606766000600000c777001c1c1c10
0dd1c2212ff2ff22002ff2002ff22ff200303000000303000c777d777777d7c0060066000666000000006000000000060060067600000000c090c0001c1c1c10
00d1c1c22ee22ee2022ee2202ee22ee200303030030303000ccc7c77d7d7cd00000066000666000000006000000000060000066600000600c222c0001c1c1c10
00dc0005288228820288882022888822000000300003000000cc7c770ccdc0000000060000600000000000000000000000000660000000000c2c000011111110
0dc000002222222202222220022222200000300000000300000cccc00d0000000000060000600000000006000000000000600060000000000000000000000000
002222000022222000222200002222000220022002222200002222002222222000222200002222000022200000000000022000000002200076000670eeee2220
020000200200002002000020020000202002200220000020020000202000000202000020020000200020220000000000200200000020020077606770eeee2220
2000000e200000e02000000e2000000e2002200e200000e0200000e02000000e2000000e2000000e002002200000000020020000224002207676767000000000
2002200e200000e02002200e2002200e2002200e20022e0020022e000222200e2002200e2002200e00200020000000002002000200e000027667667080808800
2002e00e022e00e02002e00e2222e00e2002e00e20020000200200000000200e2002e00e2002e00e0000002000000000200e000200e000027606067088808080
200ee004000e00400222e004000e0004200ee004200eee00200eee000000e004200ee004200ee0040000002000500000200eee202ee002207600067088808800
200ee002000e00200000e00200e00020200ee0022000004020000040000e0002020000402000000200000020005000002000000200e002007600067080808000
e00e400200040020000e000200e00020200e40020e000002200000020004000202000020020000020000002000500000e000000e00400e000000000000000000
e00420020002002000e0002000040002e000000200ee4002200e400200200020200e400200ee4002eeeee20000500000e002200e00200e007600067001111111
e0022002000200200e000200ee4220020e000002eee42002e004200200200020e0042002eee42002ee02ee2000500050e002200e00200e007600067011cccccc
4002200200020020e0002000e002200200422002e0022002e002200200200200e0022002e0022002ee002ee0005000504002200400200400760006701c111111
2002200200020020400222204002200200002002e0022002e002200200200200e0022002e0022002ee02ee20005000502002200200200220760606701c100000
20000004002000022000000220000004000020024000000440000004002002004000000440000004eeeee200005000502002200200200002776767701c100000
02000040002000042000000402000040000020040200004002000040002004000200004002000040ee000000005500502004200400420004077677001c100000
00224400000244400222244000224400000004400022440000224400000440000022440000224400ee000000000550500440044044002440076067001c100000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055500000000000000000000000001c100000
00000060000000000000000022222000222220002222200002222000222220002222200022222000888888888888888888888888888888888888888812288990
0000060000000000000660002a9920002a2920002a99200022a920002a9920002a9920002a9920000000000000000000000000000000000000000000228899a0
00066000000000000666660022292000292920002922200029222000222920002929200029292000888888288228828888802888800002882000288228899aa0
0066000000000006600006000292200029292000299220002922200002292000229220002929200080880808800880880080088028000800800280088899aa70
06600006000006600000600002272000277720002227200027772000027220002727200022772000008800088008808800000880080028008208800028899aa0
060066000006600000060000222e2000222e2000222e20002e2e200002e200002e2e2000222e20000088000880088088000008802800880088088000228899a0
0666000000600000000000002ee22000022e20002ee220002eee200002e2000022e220002ee22000008800088008808808000888800088008800820012288990
00000000600000000000000022220000022220002222000022222000022200000222000022220000008800088888808888000880280088008800282000000000
01111110001111000111111011111111011110001111111101111110111111110111111001111110008800088008808808000880088088008800028099989990
11dddd11011dd10011dddd1115dddd6101dd100016dddd5111ddd5101ddddd6111dddd1111dddd11008800088008808800000880088088008800008899e8e990
16711761017771001511177111111761117110001671111116711110151111611671176116711761008800088008808800000880088028008200008899808990
17f1f7710117710011111f71001ff71117711110177ff711177ff71111111771117ff71117f11f7100880008800880880080088028000800800800829e808e90
177f1f71001ff100117ff71111111f7117f1ff1111111f7117f11f710011ff1117f11f71117ff771028820288228828888802888800002882002882098888890
16711761011771101671111115111761167f776115111761167777610017711016711761011117610000000000000000000000000000000000000000e88088e0
11dddd1101dddd1016dddd5111dddd111111dd1111dddd1111dddd11001dd10011dddd110015dd11888888888888888888888888888888888888888888888880
01111110011111101111111101111110000111100111111001111110001111000111111000111110000000000000000000000000000000000000000000000000
00000000008800000000000000002044000000000000000000000000005500000000000bbbbb35555112888215d5512200030000bbb3000000000dddd6888888
0000000d08228800000000520002844f000000000000000000000000005d5500000000bbbbb3b355b88888215d55122200000000bbb3000000000d6d6d888822
000dd4fd822e228020005582002844ff0000000000000000000000000005d55000000bbbbbbbbb33bb8882156d5122220000000bbb330000000006d6d68822ee
004dffff82e22e82800588e20288425f0008000000000000000000000005d6500000bbbbbbbbb3bbbbb8b156d55122880000000bbb3000000000006d6d62ee88
00ffeeef0822e2248208ee8102824f7f000388800005d5000000000000005d550000bbbbbbbbbbbbbbbbb56d551288880000000bbb300000000000d6666e8888
00fefffe00882229880e88132882471f0000b33882005dd50000000000005dd5000bbbbbbbbbbbbbbbb335dd551888880000000bb33000000000006d66688888
000ffeef000082448805881b288824ff00003bb3388205d655000000000053bb000bbbbbbbbbbbbbb33305d5518888880000000bb300000000000006d6678888
4002fff2000822990e25888128820d4400000b3bb338825dd65550000002366600bbbbbbbbbbbbbb33000055518882220000000bb30000000000000666768888
f0221112008222440885288228800560000000bb3b3388255ddd55122882367700bbbbbb3bbbbbb33000000000822eee0000000b330000000000000066767888
f2222772082e72290885587202800050000000b3b3b33882555555128888b67100bbbbb30bbbbb3300000000022ee8880000000b300000000000000067667888
ff4227120827128a6d885712028200000000000b3bb33388211111128888bb7100bbbb300bbbbb30000000dddee888880000000b300000000000000007677788
4ff4222188222809d0085522002800000000000bbb3b333882555551288223bb000bb3300bbbb3300000ddddd88888880000000b300000000000000000677778
4fff40228e822800006d5002002d000000000000bbbb333356ddd55128221553000bb300bbbbb3000000ddddd888888800000000300000000000000000077770
44f0f0008e88800000d500000005600000000000bbb3b3356dd5551288215512000b3300bbbb33000000ddddd888888800000000000000000000000000000770
04f00f0088e800000d5000000000d00000000000bbbbb35dd555112882155512000b3000bbbb30000000ddddd888888800000000000000000000000000000000
00400000088000000d000000000005000000000bbbbb35d55551228821555182000b3000bbb3300000000ddddd88888800000000000000000000000000000000
0005115000000065000045660000000600000000000000000000000555500000000ddd5555000000005555667355544400000000000000000dd5555500005555
0051661500650165000499520005505600000000000000000000000577550000000ddd5500000000555666666752559400000000000000000dd2557550055777
06cd7767016501d50049a99901d65015000000000000000000000055666550000000dd00000000dd5666665555522544000000000000000000dd555755056666
6ccd776701d51dd1029949a9d6766d1d000000000000555555500056666655550000000000000ddd6666555005222559000000000000000000dd205675553667
dcc676761dd1711604a90499d6766d1d00000000055556666755055535356666000000000000ddd5d6555000005d22220000000000000000000dd05666665666
dc6776771d17667604920249d66666dd000000d555666676667555666663535300000000000ddd25d55000000005d22200000000000000000000d05566663666
677776771dd17667544004990d67666d0000dddd66666666666736667666566600000000000ddd5550000000000055dd00000000000000000000000566665353
67776777011117675650044900d6666d00dddddd6666555555535536666655560000000000ddd250000000000000055500000000000000000000000556653777
61176777011111765650540f000d66d70dddd255d55550000055665536665dd50000000000ddd500000000000050052200000000000000000000000056657777
111176671ddddd1600005609000dddd7ddd25555d000000000055566553655dd000000000ddd5000000000000525052400000000000000000000000055555666
56d517761dd55d1e0000560f000d666ddd5550000000000555557536665555550000000000dd000000000000052252290000000000000000000000000dd05667
0550d76701565d220000002400d656d6dd0000000000555566666753666665770000000000000000000000000052224400000000000000000000000000d05666
000067d6000601d20000004900d55ddc000000000dd556666666667536766570000000000000000000000000005d222900000000000000000000000000005566
0000677d000001dd000000490015510d0000000dddd6666655555667566665700000000000000000000000000005d22400000000000000000000000000000556
000006770000001d0000004a0050050000000dddd25d5555500055555665554400000000000000000dd00000000555d200000000000000000000000000000055
000000660000000100000004006006000000ddd2555d5000000005673565499400000000000000000dd505500000055d00000000000000000000000000000000
0000000000000011000000001110001110000000000000111000000000001110000000001111111111111111000000000900cc0000cc99000000c70000000000
11111101111011e1110011111710001710111111011111171011111011111711111100001777777dd7777771000000000990cc00003c79770000cc7000000000
1eeee111eee11eeee10117771110111710177171117771111117771117711711777100001666c66ddd6066710000000004900cc000bcc79970000c7000000000
1e111e1e111e11e111017111171117771017171717111717117111717111711711110000166e666ee6000671c000000000990cc00003cc7997000cc700000000
1e101e1e101e11e1000117701711711710171717177771171177771171011111771100001606dddd600050711000000000990ccc0003ccc759000cc700000000
1e101e1e111e11e11101111717117117101717171711111711711111710000111171000016666dddd00000010c00000004959ccc00974cc6959000c700000000
1e101e11eee1111ee1017771107117771017171711777111711777117100001777110000166666dd6006607101c00000099590cc044974ccc94000cc70000000
1110111111110011110111111011111110111111111111011111111111000011111000001600600dd006667103c00000499590ccc154964cc40000cc70000000
00000000000000000000000000000000000000000000000000000000000000000000000010000000dd006671001c0000995940ccc1152e44c5ee00ccc0000000
0000000000000000000000000000000000000000000000000000000000000000000000001006000dd0006671003c00005959400cc41228e4c522e0ccc0000000
0000000000000000000000000000000000000000000000000000000000000000000000001606000d000066710001c0004594540ccc42228ed652e0ccc7000000
000000000000000000000000000000000000000000000000000000000000000000000000166600000000007100031c0004544544cc52222edd622ecccc000000
0000000000000000000000000000000000000000000000000000000000000000000000001660000660066071000031c0000044222dd522282d652ec7cc000000
000000000000000000000000000000000000000000000000000000000000000000000000160660666060067100000b1c0000022525dd545222452ec7cc000000
000000000000000000000000000000000000000000000000000000000000000000000000140040044004444100000031c000025225dd2221112e22c7cc000000
0000000000000000000000000000000000000000000000000000000000000000000000001111111111111111000000b11cc00252225222111122e5cc7c000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b15ccc02522522411111255cc7cc00000
011111111111111001111111011111100011111111111100011111100011111111111100000000000000000000000000b115ccc525252411111265cc77c00000
01777777777777111177777701777711001777711777711001777710001777711777710000000000000000000000000003115cccc25522e1111dd62cc7cc0000
0177777777777771177777770177777110177771177777110177771000177771177771000000000000000000000000000b31155ccc5252411122dddccc7cc000
01777777777777711777777701777777111777711777777101777710001777711777710000000000000000000000000000b311155ccc5dd4e4222ddcccc77cc0
016666111116666116666111016666666116666116666666016666111116666116666100000000000000000000000000000b3111155ccddd22552d7ccc0000cc
0177771000177771177771110177777777177771177777770177777777777711177771000000000000000000000000000000b1111115ccdd5522277cc6660000
01777710001777711777777701777717777777711777717701777777777771111777710000000000000000000000000000000311111155cdd2255577c6000000
017777100017777117777777017777117777777117777117017777777777771117777100cc0000c60000000000000000000003111111115c0000000000c00000
0177771000177771177771110177771117777771177771110177771111177771177771000c00000c0000000007000000000000311100000500000c00000c0000
0177771111177771177771000177771011777771177771000177771000177771177771110cc0000cc7000000007000000000003110000000000000c0000c7000
01777777777777711777710001777710011777711777710001777710001777711777777700c00003cc90000000c000000000001100000000000000c00000c000
01777777777777711777710001777710001777711777710001777710001777711777777700cc0000cc900000000700000000001100000000000000cc0000c700
01777777777777111777710001777710001777711777710001777710001777711177777790cc00003cc90000000c700000000110000000000000000c00000c00
011111111111111011111100011111100011111111111100011111100011111101111111900cc0000cc90000000c700000000100000000000000000cc0000c70
000000000000000000000000000000000000000000000000000000000000000000000000090cc00003c690000000c700000010000000000000000000c00000c0
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000c00000c00010000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000c0000c70010000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000c00000c0001000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000cc0000c7001000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000c00000c000d00000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000cc0000c700d00000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000c00000c000d0000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000cc0000c600d0000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000c00000c000c000007000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000cc0000cc70c000000700000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000c00003cc90c00000c00000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000cc0000cc90c00000070000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000090cc00003cc90000000c7000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000900cc0000cc90000000c7000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000090cc00003c690000000c700000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000900cc0000cc99000000c700000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000990cc00003c79770000cc70000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000004900cc000bcc79970000c70000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000c000000000990cc00003cc7997000cc7000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000001000000000990ccc0003ccc759000cc7000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000c00000004959ccc00974cc6959000c7000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000001c00000099590cc044974ccc94000cc700000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000003c00000499590ccc154964cc40000cc700000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000001c0000995940ccc1152e44c5ee00ccc00000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000003c00005959400cc41228e4c522e0ccc00000000000100000000000000000000000000000
0000000000000000000000000000000000000000000000000000000001c0004594540ccc42228ed652e0ccc70000000000100000000000000000000000000000
00000000000000000000000000000000000000000000000000000000031c0004544544cc52222edd622ecccc0000000000010000000000000000000000000000
000000000000000000000000000000000000000000000000000000000031c0000044222dd522282d652ec7cc0000000000010000000000000000000000000000
00000000000000000000000000000000000000000000000000000005000b1c0000022525dd545222452ec7cc000000000000d000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000031c000025225dd2221112e22c7cc000000000000d000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000b11cc00252225222111122e5cc7c0000000000000d00000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000b15ccc02522522411111255cc7cc000000000000d00000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000b115ccc525252411111265cc77c0000000000000c0000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000003115cccc25522e1111dd62cc7cc000000000000c0000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000b31155ccc5252411122dddccc7cc000000000000c000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000b311155ccc5dd4e4222ddcccc77cc0000000000c000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000b3111155ccddd22552d7ccc0000cc0000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000b1111115ccdd5522277cc66600000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000311111155cdd2255577c60000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000003111111115c67777777766000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000311100077577777777777660000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000311000067777777677777666600000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000110000067777777777777777766000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000110000676777777777777666660000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000001100006766776777677776760000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000001000006660676776677766676000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000010000060000676676676766667600000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000600060676676667766606600000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000100000000000000000000000666676667766660000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000100000000000000000000600660666767767760006000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000010000000000000000000000660066767667766000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000010000000000000000000000060066767677776000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000d000000000000000000000060006766677776600000000000000000000000000000000000
0000000000000000000000011100000011100111000000000111000d000111000000000000000000000666777777600000000000000000000000000000000000
000000000000000111101111d11001111d1011d10111101111d10111d111d1111100000000000000060676777777600000000000000000000000000000000000
0000000000000001dd111d11dd1011dd11111dd101dd111d111111d111d1d11dd100000000000000000067777777760000000000000000000000000000000000
0000000000000001d1d1d1d1d1101d111d11d1d101ddd1ddd1d11ddd1d1111d11100000000000111100067777777760000000000000000000000000000000000
0000000000000001d1d1d1d1d110111d1d11d1d101d1d1d111d11d111d100111d100000000000188100006777777776000000000000000000000000000000000
0000000000000001d1d11d111d101dd111d11dd101d1d11dd11d11dd1d1001dd1100000000000188100006777777776000000000000000000000000000000000
00000000000000011111111111101111011111110111111111111111111001111110000000000181110000677777777600000000000000000000000000000000
00000000000000011100011171000011111011111171001111171000011111101710111111011188810000677777777600000000000000000000000000000000
0000000000000001710001717111111777111777117101177717111101777711111017177111e181111000067777777760000000000000000000000000000000
000000000000000171111171777711711171711171710171111777711111117117101771111e1188811000067777777760000000000000000000000000000000
000000000000000171171171711171711171711171710170001711171177777117101711001e1111181100006777777776000000000000000000000000000000
000000000000000171171171710171777711777711710170001710171711117117101710001e1101118100006777777776000000000000000000000000000000
0000000000000001711711717101717111117111117111711117101717111171171117100011e111e11100000677777777600000000000000000000000000000
00000000000000011771771171017117771117771117711777171017117777171177171000011eee110000000677777777600000000000000000000000000000
00000000000000011111111111111111111111111111111111111111111111111111111111111111111111111117771111111111100011111100000000000000
00000000000000017777777777771117777777777711777711001777717777110117777117777777777711777717771777717777100017777100000000000000
00000000000000017777777777777177777777777771777771101777717777711177777177777777777771777716771777717777100017777100000000000000
00000000000000017777777777777177777777777771777777111777717777771777777177777777777771777716771777717777106617777100000000000000
00000000000000016666111116666166661111166661666666611666616666666666666166661111166661666611111666616666166616666100000000000000
00000000000000017777100017777177771111177771777777771777717777777777777177771111177771777777777777117777100017777100000000000000
00000000000000017777100017777177777777777771777717777777717777177717777177777777777771777777777771117777100617777100000000000000
00000000000000017777100017777177777777777771777711777777717777117117777177777777777771777777777777117777106017777100000000000000
00000000000000017777100017777177771111177771777711177777717777111117777177771111177771777711111777717777100017777100000000000000
00000000000000017777111117777177771000177771777710117777717777100017777177771000177771777710001777717777111117777100000000000000
00000000000000017777777777777177771000177771777710011777717777100017777177771000177771777710001777717777777777777100000000000000
00000000000000017777777777777177771000177771777710001777717777100017777177771000177771777710061777717777777777777100000000000000
00000000000000017777777777771177771000177771777710001777717777100017777177771000177771777716601777711777777777771100000000000000
00000000000000011111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111000000000000000
0000000000000001d1d1dd111dd11dd1ddd1ddd1ddd1ddd1d1d1ddd1dd111dd1ddd1ddd1d111ddd10001ddd1ddd1ddd11dd17777776000000000000000000000
0000000000000001d1d1d1d1d111d1d1ddd1d1d1d1d1d111d1d1d111d1d1d1111d11d1d1d111d111000111d1d111d1d1d1d17777776000000000000000000000
0000000000000001d1d1d1d1d111d1d1d1d1ddd1dd11dd11ddd1dd11d1d1ddd11d11dd11d111dd1100011d11dd11dd11d1d17777777600000000000000000000
0000000000000001d1d1d1d1d111d1d1d1d1d111d1d1d111d1d1d111d1d111d11d11d1d1d111d1110001d111d111d1d1d1d17777777600000000000000000000
00000000000000011dd1d1d11dd1dd11d1d1d111d1d1ddd1d1d1ddd1d1d1dd11ddd1ddd1ddd1ddd10001ddd1ddd1d1d1dd117777777760000000000000000000
00000000000000011111111111111111111111111111111111111111111111111111111111111111000111111111111111117777777760000000000000000000
0000000000000001ddd11dd1ddd1ddd1ddd1ddd10001ddd1ddd11dd1d1d1ddd1ddd1ddd100000000000000000000000000006777777776000000000000000000
0000000000000001d1d1d1d1ddd1d1d1d111d1d10001d1111d11d111d1d11d11d111d1d100000000000000000000000000006777777776000000000000000000
0000000000000001dd11d1d1d1d1dd11dd11dd110001dd111d11d111ddd11d11dd11dd1100000000000000000000000000000677777777600000000000000000
0000000000000001d1d1d1d1d1d1d1d1d111d1d10001d1111d11d1d1d1d11d11d111d1d100000000000000000000000000000677777777600000000000000000
0000000000000001ddd1dd11d1d1ddd1ddd1d1d10001d111ddd1ddd1d1d11d11ddd1d1d100000000000000000000000000000067777777760000000000000000
00000000000000011111111111111111111111110001111111111111111111111111111100000000000000000000000000000067777777760000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006777777776000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006777777776000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000677777777600000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000677777777600000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000067777777760000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000067777777760000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006777777776000000000000

__map__
60706070607000000000000029092f831f22833171837071830b01830a01832a830a01830a01830a01810a010500002b082f811c3b092f0078836175837221830d0707040c06060b06060a06060d2e09090c05050b05050a050500082f1f73617072313a82003982003a82003982003a820039823f0f0e0d0c0b0a0100000000
2a072f801c213c3c73607362780a070100082f29820a062f717974311f022e090000000000000000000000000000002a08083e05821f71798272310b82020b020a02002b062f09801c3c3c3c76730a07070708627022047376740100000000000000000000000a092d0909000000000000000000006070607060702f00787774
00290906821c31820b070607820b0706070a0706070c070505010b070505010a07050501000000002907062f911c3c21737362700a04002f092b05833906832b05833906832b05833906830000000000293e0909311f7178607200930a03930a03930a03930a0300000000000000000000000000000000000000000000000000
006070607060707f00090000000000000000080000000000070008285e39004f4f384e1f607279617321390a010b0100003a0000001c6174703b60710f02000000384e093b4f4f4f5e073a4e211e5a60757369703f0a0b030000211c63727160720e010000000000000e01000e01000000003b000e01000e010000000000000e
01000000000e01000e010000000000000e01000e010000000000000e01000e01000000384e19284f4f4f5e004e000000211d61747363773c3c0e01000000000000311f5a60717860733f0c0d03000000004e093b380039003a0039285e004f4f4f4f4e211c3d1b3d3d3d61717363760e0400213c1c6078736172100f01000000
0000000000000000000000000000000000000000000000001a4e00000000006f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000031336072607060712f0829b12ab10029b12ab13f0a0b0c0d07070a050b060c050d063f0a0b0c0d090902020a060b050c060d05002808b06171607460721c3d210a010460710a2d09050906637260731f31332f0938a10a062f023aa10a052f0238a10a062f023aa10a052f0238a10a062f023aa10a052f020000000000
0000000000000000292fb2627260761c0a073c0a086278213c0400607162706072313300392f09b30a020000b30a020b05b30a020b05b30a020b05b30a020b050000003d3d607360736073093e2bb02cb02ba12ca12bb12cb11c3f0f0e0d0c0b0a08042d096171003f0d0c017974003f0b0a070200000000003a072fa20a0707
0506001f3e310960716077607228b30a03b30a03b30a03b30a03b30a03b30a03b30a03b30a032ab30a03b30a03b30a03b30a03b30a03b30a03b30a0320b30a03b30a03b30a03b30a0329b30a03b30a03b30a03b30a03b30a03b30a03b30a03b30a03b30a03b30a03b30a032028b30a03b30a030c0505b30a03b30a030e0606b3
0a0329b30a03b30a03b30a03b30a03b30a03b30a03b30a03b30a03b30a03b30a03202ab30a03b30a03b30a03b30a03b30a03b30a03b30a03b30a03b30a03b30a03b30a03b30a03b30a03b30a03b30a03200a05050500211d3c6170607365710a01003e3133071e6072607860622ab00a0200b00a020000b00a020000002f211e
607160726370070000000000000000000d09062f0d0906000d09000000000d0909090028a029a02aa00000000000003f0a0b0c0804000000000000000000000000000000000000000000000a2d09090000000c092e0909090000000b0905090509060906000000000000007f0000000000000000000000000000000000000000
__sfx__
0001000b00000090300b3401005012050107300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0107080a39512395123851237512355222f5222053110531045450457500505005050050500505005050000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200003c54300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010600001065300000000000000000000271000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100090f61600000096301261600000000001c61700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400002d6513366009660256650a66323655076501e6451364006640026200162001620016100160001600016000b6000e600256000d6001160012600156000000000000000000000000000000000000000000
00060006071320a1360f5210a1310b1360a1360000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002e72300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010f0000056571c6570565011657056471c6400364703630086301a637026271c6100261003617036100361000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f001e1560634503000002460500000000001560634503000002460500000000001560634503000002460500000000001560634503000002460500000000001560634503000002460500000000000560000000
0111002002500025000250003500035000450005500065000750007500095000a5000c5000d5000f50011500135001550017500195001a5001c5001e500205002250024500275002a5002c5002e5003050032500
011100201120307050070503251507050070500705032515130333251507050070503251507050070501303313000030500305033515030500305003050335151103335515050500505035515050500505011033
011100201222513335134251333512225133351642513335112251333513425133351622513335164251333516225163350a425163350a2251633518425163351522515335094251533515225133351142513335
0111002032515296452f613325151f640325152f6132f61332515296452f61332515186402f6132f6232f61333515296452f6133351518640335152f6132f61335515296432f61335515186402f613355152f613
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011c00000a737017370a7370173710737017370f737017370a737017370a7370173710737017370f73701737077370173708737017370973701737077370173708737017370973701737077370d7370873701737
010e002034633041502b11504150106332b115041502b11534633041502b11504150106332b115041502b11534633041502b11504150106332b115041502b11534633041502b11504150106332b115041302b115
010e0020042341f2501f2251f2501f225042321f2501f225042341f2501f2251f2501f225042321f2501f225042341f2501f2251f2501f225042321f2501f225042341f2501f2251f2501f225042321f2501f225
010e0000170320b532177320b532170320b532177320b532170320b532177320b532170320b532177320b532170320b532177320b532170320b532177320b532170320b532177320b532170320b532177320b532
010e0000042341e2501e2251e2501e225042321e2501e225042341e2501e2251e2501e225042321e2501e225042341e2501e2251e2501e225042321e2501e225042341e2501e2251e2501e225042321e2501e225
010e0000042341c2501c2251c2501c225042321c2501c225042341c2501c2251c2501c225042321c2501c225042341c2501c2251c2501c225042321c2501c225042341c2501c2251c2501c225042321c2501c225
010e0000232502325023225232502322504232232502322504234232502322523250232250423223250232250423421250212252125021225042322125021225042341e2501e2251e2501e225042321e2501e225
010a000004222132101321513210152150422215210152150423217210172151721018215042321821018215042421a2201a2151a2201c215042421c2201c215042421e2301e2151e2301f215042421f2301f215
010e000034633041502a11504150106332a115041502a11534633041502a11504150106332a115041502a11534633041502a11504150106332a115041502a11534633041502a11504150106332a115041502a115
010e00003463304150281150415010633281150415028115346330415028115041501063328115041502811534633041502811504150106332811504150281153463304150281150415010633281150415028115
010e000034633041502f11504150106332f115041502f11534633041502f11504150106332f115041502f11534633041502d11504150106332d115041502d11534633041502a11504150106332a115041502a115
010e00200476004765026340476004765047360263400000047600476502634047600476504736026340000004760047650263404760047650473602634000000476004765026340476004765047360263400000
010a000034613041202b11504120106132b115041202b11534623041202b11504120106232b115041202b11534633041202b11504120106332b115041202b11534643041202b11504120106432b115041202b115
010a00001301007510137100751013010075101371007510130100752013710075101301007520137100751013020075101372007510130200751013720075101302007520137200752013020075201372007520
010e0000180320c532187320c532180320c532187320c532180320c532187320c532180320c532187320c532180320c532187320c532180320c532187320c532180320c532187320c532180320c532187320c532
010e0000002341e2501e2251f2501f225002321c2501c225002341e2501e2251f2501f225002321c2501c225002341e2501e2251f2501f225002321c2501c225002341e2501e2251f2501f225002321c2501c225
010e000034633001502f11500150106332f115001502f11534633001502f11500150106332f115001502f11534633001502f11500150106332f115001502f11534633001502f11500150106332f115001502f115
010e00000076000765026240076000765286230262428623007600076502624007600076528623026242862300760007650262400760007652862302624286230076000765026240076000765286230262428623
010e00000023412250122251325013225002321c2501c225002340f2500f2251025010225002321c2501c2250023410250102250c2500c225002321c2501c2250023412250122251325013225002321c2501c225
010e0000042341c2501c225042341c2501c225042341c2501c225042341c2501c225042341c2501c225042341c2501c225042341c2501c225042341c2501c225042341c2501c2251c2501c2251c2501c22504234
__music__
01 4d4c4a4b
01 1c171d4b
01 1112131b
00 1814131b
00 1915131b
00 1915131b
00 1a16131b
00 1112131b
02 201f1e21
00 1112131b
02 1814131b
00 1923131b
00 41424344
00 41424344
00 41424344
00 41424344
00 50424344

