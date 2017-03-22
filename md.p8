pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
-- mademoiselle danmaku 0.22
-- martin mauchauffee

-- todo: make hit flash when
-- increased

-- todo: prevent lazer to 
-- shoot backward

-- todo: create particle that
-- goes from dead ship to
-- scores

-- todo: display a werkage
-- of ship after kill

-- todo: create particle that
-- goes from dead to hit

-- todo: display random digit
-- for score for a couple of
-- frames

-- todo: check hit multiplier

-- todo: add a special sound
-- for red lazer

-- todo: add moar effect for
-- red lazer

-- todo: prevent ship shoot
-- bullets after vessel dead
-- when below a certain y

-- todo: vessel should no gain
-- lazer when dead

-- todo: add a timer for boss

-- todo: add a boss score
-- multiplyer depends on timer
-- or a depends on the speed of
-- damage done on the boss

-- todo: add a var that contain
-- the additionnal value use
-- to growh the health boss.
-- increase it when t==79

-- reset() should stop the sound

-- todo: when the vessel shaking
-- because it's been hit, make
-- it go down a little too.

-- todo: count number of ship
-- spawned

-- todo: count number of ship
-- destroyed

-- todo: prevent the ship to
-- shoot bullets when player
-- revive. it make bullets
-- impossible to avoid.

-- todo: create a slow down
-- effect for boss pattern

-- todo: effect on scoreboard
-- like train station

-- todo: display boss during
-- certain condition

-- todo: ship drop coins to
-- collect?

-- todo: need a real conductor
-- plan

-- todo: when die not only
-- prevent ennemy to shoot
-- bullets, also, destroy the
-- shape function if the are
-- below a specific line.

-- todo: distance from cannon
-- stored into ship object is
-- useless. it is always 5 for
-- ship and 10 for boss.

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

bs={} -- bullets
bs.g,bs.l=1,512
qs={} -- shapes
qs.g,qs.l=1,16
ps={} -- patterns
ps.g,ps.l=1,8
hs={} -- ships
hs.g,hs.l=1,16
fs={} -- formations
fs.g,fs.l=1,8
bo={} -- boss
ve={} -- vessel
be={} -- beam
be.g,be.l=1,16
be.d,be.e,be.f=0,2,0
pp={} -- particles
pp.g,pp.l=1,8
sp={} -- sprite particles
sp.g,sp.l=1,32
bp={} -- back circle particle
bp.g,bp.l=11,32
fp={} -- front circle particl
fp.g,fp.l=21,32
le={} -- level
co={} -- director normal setup
co.ss=1000 -- shape speed multiplyer
co.sc=1000 -- shape count multiplyer
co.hb=1000 -- ship hp multiplyer
ui={} -- ui
ui.d={} -- digit for score
ui.s={} -- score per digits
ui.c={} -- digit for hit
ui.t=0 -- hit counter
lo={} -- local damage
lo.g=1
lo.l=16
err="" -- message
wa=0 -- warning message

function next(t,a)
 t.g=(t.g+a)%t.l+1
end

function none()end

-- ============================
-- conductor helper

function bcount(c)
 local n=max(1,c*(co.sc/1000))
 if(c%2!=n%2)n+=1
 return n end

-- ============================
-- bullet movements

function roundexpl(r,m)
local z=le.z
local a
return function(i,b)
 err="z:"..(le.z-z)
 local a=le.z-z
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
 --xxx: should work now
 --flee(i,h,ve)
 h.x+=h.u*h.s h.y+=h.v*h.s end

function curve(i,h)
 h.x+=h.u*h.s h.y+=h.v*h.s
 h.u,h.v=rot(h.u,h.v,h.t) end

function flee(i,h)
 dx=ve.x-h.x
 h.u=-dx*0.01 h.v+=0.03
 --xxx: should work now
 --cross(i,h,ve) end
 --deleteme
 h.x+=h.u*h.s h.y+=h.v*h.s end

function target(i,h)
 x=ve.x
 if(h.u==0)h.u=0.2
 if(h.x>x+6)h.u=-abs(h.u)
 if(h.x<x-6)h.u=abs(h.u)
 cross(i,h,ve) end

-- xxx: not used
--function keepdistance(i,h)
-- local dx=ve.x-h.x
-- h.u=-(64-dx)*0.05
-- h.x+=h.u*h.s
-- h.y+=h.v*h.s
--end

-- return vessel position to aim at
function vepos()
 if lpf then -- fixed
  local x,y=ve.x,ve.y
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
   return ve.x,ve.y
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
 if(q.w)m,n=aim(h.x,h.y,x,y)
 r=(((2*j)-1)/q.c-1)*a
 u,v=rot(m,n,r+(q.z*s))
 bx,by=h.x+u*(h.o),h.y+v*(h.o)
 return true,bx,by,u*q.s,v*q.s end
end

-- old shape functino
-- xxx: not used
--function chump(i,q,j,x,y,f)
-- h=q.h
-- x,y
-- =h.x+rnd(4)*3-6,h.y+h.o+9+rnd(4)*3-6*3
-- return true,x,y,h.u,h.v end

-- xxx: not used
--function scan(i,q,j,x,y,f)
-- h=q.h
-- r=j/q.c+(h.z%100)/100
-- u,v=rot(h.u,h.v,r*(q.z/100))
-- m,n=h.x+u*(h.o),h.y+v*(h.o)
-- return true,m,n,u*q.s,v*q.s end

-- todo: replace by arc()
--function spir(i,q,j,x,y,f)
-- h=q.h
-- r=j/q.c+(h.z%100)/100
-- u,v=rot(h.u,h.v,r+(q.z/100))
-- m,n=h.x+u*(h.o),h.y+v*(h.o)
-- return true,m,n,u*q.s,v*q.s end

-- ============================
-- level

function apply(t)
 if(#le.h<1)return
 for i in all(le.h)do
  if le.bo then
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
    local s=le.bn
    if s==arc then
     s=s(le.aa,le.as)
    end
    fire(h,le.c,le.d,le.t,s,
    le.bm,le.bs,le.bf,le.w)
    le.bt=1
   end
   if t==46 or t==47 or t==63 or (t>=1 and t<=9) then
    le.m=false
   end
  end
 end
 return true
end

function findt()
 for i=1,100 do
  local x,y=(le.a+i)%128,(le.a+i)/128
  if mget(x,y)==78 then
   return flr(le.a+i)
  end
 end
end

function level()
 le.a+=0.25
 if flr(le.a)==le.a then
  x,y=le.a%128,le.a/128
  t=mget(x,y)
	 if t==111 then
    anim=false
	  reset(1)
	  scene=title
	  --reset(1)
	  --for i=1,bs.l do
	   --bs[i].m=none
	  --end
	  for i=1,qs.l do
	   qs[i].n=none
	   qs[i].t=0
   end
  --boss waiting position
  elseif t==94 then
   if bo.x~=bo.u
   or bo.y~=bo.v then
    le.a-=1
   end
  --position and direction
  elseif t==40 then
   if le.bo then
    bo.u,bo.v=0,30
   else
    le.x,le.y=0,-18
    le.u,le.v=0,1
   end
  elseif t==41 then
   if le.bo then
    bo.u,bo.v=-25,30
   else
    le.x,le.y=-40,-18
    le.u,le.v=0,1
   end
  elseif t==42 then
   if le.bo then
    bo.u,bo.v=25,30
   else
    le.x,le.y=40,-18
    le.u,le.v=0,1
   end
  elseif t==43 then
   if le.bo then
    bo.u,bo.v=20,44
   else
    le.x,le.y=-70,-18
    le.u,le.v=0.7,0.7
   end
  elseif t==44 then
   if le.bo then
    bo.u,bo.v=-20,44
   else
    le.x,le.y=80,-18
    le.u,le.v=-0.7,0.7
   end
  elseif t==56 then
   if le.bo then
    bo.u,bo.v=30,34
   else
    le.x,le.y=-82,40
    le.u,le.v=1.0,0
   end
  elseif t==57 then
   if le.bo then
    bo.u,bo.v=-30,34
   else
    le.x,le.y=82,40
    le.u,le.v=-1.0,0
   end
  elseif t==58 then
   if le.bo then
    bo.u,bo.v=30,24
   else
    le.x,le.y=-82,20
    le.u,le.v=1.0,0
   end
  elseif t==59 then
   if le.bo then
    bo.u,bo.v=-30,24
   else
    le.x,le.y=82,20
    le.u,le.v=-1.0,0
   end
  --ship movement
  elseif t==47 then
   if(not apply(t))le.sm=cross
  elseif t==46 then
   if(not apply(t))le.sm=flee
  elseif t==62 then
   if(not apply(t))le.sm=target
  elseif t==45 then
   apply(t)
  --ship rotation
  elseif t==5 then
   if not apply(t) then
    le.u,le.v=rot(le.u,le.v,-0.05)
   end
  elseif t==6 then
   if not apply(t) then
    le.u,le.v=rot(le.u,le.v,0.05)
   end
  --ship speed
  elseif t==7 then
   if le.bo then
    bo.s=0.25
   elseif not apply(t) then
    le.ss=0.75
    if(le.l==7)le.ss=0.85
   end
  elseif t==8 then
   if le.bo then
    bo.s=0.5
   elseif not apply(t) then
    le.ss=1
    if(le.l==8)le.ss=1.5
   end
  elseif t==9 then
   if le.bo then
    bo.s=1.5
   elseif not apply(t) then
    le.ss=2
    if(le.l==9)le.ss=2.5
   end
  --boss hp
  elseif t==79 then
   bo.m+=100
   bo.b+=100
   bo.i+=2
   bo.a=true
  --developer markers
  elseif t==24 then
   for ii=1,1000 do
    local xx,yy=(le.a+ii)%128,(le.a+ii)/128
    if mget(xx,yy)==25 then
     le.a=flr(le.a+ii)
     break
    end
   end
  elseif t==26 then

  --markers
  elseif t==78 then
   if le.ma==0 then
    le.ma=le.a
    le.c,le.d,le.t=0,0,0
   else
    le.rk=le.a
    le.a=le.ma
   end
  --hp, score, ship frame
  elseif t==131 then
   le.b,le.r,le.sf=5,550,131
  elseif t==147 then
   le.b,le.r,le.sf=7,800,131
  elseif t==130 then
   le.b,le.r,le.sf=12,1000,130
  elseif t==146 then
   le.b,le.r,le.sf=18,1500,130
  elseif t==129 then
   le.b,le.r,le.sf=30,3000,129
  elseif t==145 then
   le.b,le.r,le.sf=40,4000,129
  elseif t==128 then
   le.b,le.r,le.sf=70,8000,128
  elseif t==144 then
   le.b,le.r,le.sf=90,10000,128
  --boss arrive! distance from canon
  elseif t==127 then
   le.bo,wa=true,1
   bo.x,bo.y=0,-50
   bo.u,bo.v=0,30
  --arc angle
  elseif t==28 then
   le.aa=0.5
  elseif t==29 then
   le.aa=0.25
  elseif t==30 then
   le.aa=0.125
  elseif t==31 then
   le.aa=0.0625
  --arc spirale
  elseif t==60 then
   le.as-=0.01
  elseif t==61 then
   le.as+=0.01
  --bullet movement
  elseif t==34 then
   le.bm=none
  elseif t==35 then
   err="t==35"
  elseif t==50 then
   err="t==50"
  elseif t==16 then
   le.bm=roundexpl(0.02,120)
  elseif t==51 then
   lpa=true
  elseif t==90 then
   lpf=true
  --bullet frame, bullet speed
  elseif t==1 then
   le.bf,le.bs=1,1.5
   apply(t)
  elseif t==2 then
   le.bf,le.bs=2,3
   apply(t)
  elseif t==3 then
   le.bf,le.bs=3,4
   apply(t)
  elseif t==4 then
   le.bf,le.bs=4,2
   apply(t)
  --aim mode
  elseif t==33 then
   le.w,lpa,lpf
   =false,false,false
  elseif t==49 then
   le.w,lpa,lpf
   =true,false,false
  end
  --arc
  if t>=28 and t<=31 then
   le.bn=arc
   le.as=0
  --cancel selection
  elseif t==0 then
   le.m=false
   le.h={}
  --multiple selection
  elseif t==63 then
   le.m=true
  --select spawned ship
  elseif t>=10 and t<=15 then
   if(not le.m)le.h={}
   if le.bo then
    -- todo: put the ship object directly
    add(le.h,(t-9))
   else
    -- todo: put the ship object directly
    add(le.h,(hs.g+8-t)%hs.l+1)
   end
  --spawn ship
  elseif (t>=128 and t<=131)
  or (t>=144 and t<=147) then
   spawn(le.x,le.y,le.u,le.v,
   le.sf,le.ss,5,le.sm,
   le.b,le.r)
  --count,delay,repeat x10
  elseif t>=96 and t<=105 then
   local v=(t-96)*10
   if le.bt==1 then
    le.c=v
   elseif le.bt==2 then
    le.d=v
   elseif le.bt==3 then
    le.t=v
   end
  --count,delay,repeat x1
  elseif t>=112 and t<=121 then
   local v=(t-112)
   if le.bt==1 then
    le.c=flr(le.c/10)*10+v
   elseif le.bt==2 then
    le.d=flr(le.d/10)*10+v
   elseif le.bt==3 then
    le.t=flr(le.t/10)*10+v
   end
   le.bt=le.bt%3+1
  end
  le.l=t
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
 u,v=-61,124-ve.p
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

function point(c)
 c=max(1,c/100)
 return function(i,p)
  if p.z<c then
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
 if(s.z==15) s.f,s.y=none,-128 end

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
 if p.z==(i%14)+24 then
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
  cls(0)
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
 b=bs[bs.g] next(bs,0)
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
 q=qs[qs.g] next(qs,0)
 q.c,q.d,q.e,q.t,q.n,q.m,q.s,
 q.w,q.z,q.h,q.f
 =bcount(c),0,d,t,n,m,
 s*(co.ss/1000),w,0,h,f end

-- x,y= position
-- u,v= direction
-- f= frame tile index
-- s= speed
-- o= distance from cannon
-- m= movement function
-- b= hp
-- r= base score when destroyed
function spawn(x,y,u,v,f,s,o,m,
b,r)
 h=hs[hs.g] next(hs,0)
 h.x,h.y,h.u,h.v,h.f,h.s,h.o,
 h.m,h.a,h.b,h.d,h.e,h.c,h.z,
 h.r,h.t
 =x,y,u,v,f,s,o,m,true,
 flr(b*(co.hb/1000)),0,b,0,0,r,0
 return h end

function damage(h,v,qs,ve,ui)
 if le.bo then
  if bo.b>0 then
   bo.b-=v
  elseif bo.a then
   -- fixme le.rk can be nil
   -- search for the next mark
   -- fixme avoid to overflow
   for i=1,100 do
    local x,y=(le.a+i)%128,(le.a+i)/128
    if mget(x,y)==78 then
     le.rk=flr(le.a+i)
     break
    end
   end
   le.a=le.rk
   le.rk,le.ma=0,0
   bo.m,bo.a,bo.i=0,false,4
   for i=1,6 do
    local b=bo[i]
    if(b.q>0)qs[b.q].t=0
   end
  end
 elseif h.c then
  if h.b>0
  then h.b-=v h.d=6
  else
   kill(h)
   locald(h.x,h.y,h.r/2,h.r/100)
   --co.ss=min(1400,co.ss+10)
  end
 end
end

function locald(x,y,s,z)
 l=lo[lo.g] next(lo,0)
 l.x,l.y,l.s,l.z=x,y,s,z end

function kill(h)
 effect(h.x,h.y,explosion)
 effect(h.x,h.y,point(h.r))
 sfx(5)
 h.b,h.m,h.a=0,none,false
 if(qs[h.q])qs[h.q].t=0
 sco(max(99,(h.c*333)-h.z+h.r))
 if(h.q>0)qs[h.q].t=0
 if ve.p<ui.p-3 then
  effect(h.x,h.y,hit(h.r))
  if ui.t<999 then
   ui.t+=1
   if ui.c[3]<9 then
    ui.c[3]+=1
   else
    ui.c[3]=0
    if ui.c[2]<9 then
     ui.c[2]+=1
    else
     ui.c[2]=0
     if ui.c[1]<9 then
      ui.c[1]+=1
     end
    end
   end
  end
  extend(i)
  ui.i=50
 else
  for i=1,3 do ui.c[i]=0 end
  ui.t=0
  --ui.p=20
 end
 --co.hb=min(1300,co.hb+10)
end

function dead()
 ve.a,ve.b,ve.l=false,false,false
 effect(ve.x,ve.y,die,0)
 ve.x,ve.y=0,140
 anim=arrive(110)
 --co.ss=max(700,co.ss-150)
 --co.sc=max(500,co.sc-200)
 --co.hb=max(600,co.hb-100)
end

-- ============================
-- emitter

function effect(x,y,f,i)
 p=pp[i or pp.g] next(pp,0)
 p.x,p.y,p.f,p.z
 =x,y,f,0 end

function sprite(x,y,t,f)
 s=sp[sp.g] next(sp,0)
 s.x,s.y,s.t,s.a,s.f,s.z,s.d
 =x,y,t,0,f,0,3 end

function back(x,y,r,c,f)
 p=bp[bp.g] next(bp,0)
 p.x,p.y,p.r,p.c,p.f,p.z
 =x,y,r,c,f,0 end

function front(x,y,r,c,f)
 p=fp[fp.g] next(fp,0)
 p.x,p.y,p.r,p.c,p.f,p.z
 =x,y,r,c,f,0 end

-- ============================
-- gameplay

function sco(h)
 s,i,d=ui.s,9,ui.d
 if(h<0)err="sco>32787" return
 while h>0 do
  a=h%10
  if(s[i]+a>9)h+=10
  s[i]=(s[i]+a)%10
  d[i]=112+s[i]
  h=flr(h/10) i-=1 end end

function power(v,p)
 if v.p<ui.p and p>0.125
 and le.z%5==0 then
  effect(ve.x,ve.y,dart)
 end
 v.p=min(ui.p,v.p+p+ui.t/100)
end

function extend(p)
 ui.p=min(80,ui.p+1) end

function reset(lvl)
 la=16
 ve.x,ve.y,ve.u,ve.v,ve.a,ve.b,
 ve.z,ve.d,ve.l,ve.s,ve.p,ve.w,
 ve.g
 =0,140,0,0,false,false,0,false,
 false,3,10,40,false
 lp={}--late postion of vessels
 lp.i=1
 lpa=false--late position active
 lpf=false--fix late position
 for i=1,4 do lp[i]={x=0,y=0} end
 -- z=level frame counter
 -- a=index of the tile to read
 le.z,le.a,le.bo,le.ma,le.rk
 =0,0,false,0,0
 --=0,384,false
 -- x,y=ship position
 -- u,v=ship direction
 -- sm=ship movement
 -- ss=ship speed
 -- sf=ship frame
 -- b=base hp
 -- r=base scare
 -- h=selected ship for shoot settings
 -- m=multi selection enable
 -- p=consumed, h will be reset
 -- c=bullet count
 -- d=bullet delay
 -- t=bullet repeat
 -- bn=shape
 -- aa=arc angle
 -- as=arc spirale
 -- bm=bullet movement
 -- bs=bullet speed
 -- bz=bullet speed multiplyer
 -- w=aim
 -- bf=bullet frame
 -- bt=bullet number state 1=count 2=delay 3=repeat
 -- l=old tile
 le.x,le.y,le.u,le.v,le.sm,
 le.ss,le.b,le.r,le.h,
 le.c,le.d,le.t,le.bn,le.aa,
 le.as,le.bm,le.bs,le.bz,le.w,
 le.sf,le.bf,le.bt,le.m,le.l
 =0,-82,0,1,cross,1,5,0,{},
 1,0,1,arc,0,0,none,0,1,false,
 0,0,1,false,0
 -- ui
 for i=1,9 do ui.d[i]=112 ui.s[i]=0 end
 for i=1,3 do ui.c[i]=0 end
 ui.p,ui.h,ui.i,ui.t=20,0,0,0
 -- x,y=position
 -- u,v=target position
 -- s=speed
 -- h=sel canon
 -- b=real hp
 -- m=max hp
 -- d=disp hp
 -- i=hp heal speed
 bo.x,bo.y,bo.u,bo.v,bo.s,bo.h,
 bo.b,bo.d,bo.m,bo.a,bo.i
 =0,-50,0,30,0.5,1,
 0,0,0,false,4
 -- x,y=pos from boss
 -- a=active (needed)
 -- u,v=canon dir
 -- o=?
 -- c=?
 for i=1,6 do
  local b={}
  bo[i]=b
  b.a,b.u,b.v,b.o,b.c,b.q
  =true,0,1,10,0,0
 end
 -- todo: change dir of canon: u,v
 bo[1].x,bo[1].y=-20,bo.y-5
 bo[2].x,bo[2].y=20,bo.y-5
 bo[3].x,bo[3].y=-22,bo.y+10
 bo[4].x,bo[4].y=22,bo.y+10
 bo[5].x,bo[5].y=0,bo.y-8
 bo[6].x,bo[6].y=0,bo.y+14
 wa=0
end

function mhere()dset(63,le.a)run()end
function mhind()dset(63,max(0,le.a-8))run()end
function mrese()dset(63,0)run()end

function arrive(wait)
 return cocreate(function()
  ve.g=true
  while wait>0 do
   wait-=1
   yield()
  end
  ve.x,ve.y=0,140
  while ve.y>101 do
   ve.y+=max(-5,(100-ve.y)/3)
   yield()
  end
  while ve.y<117 do
   ve.y+=min(3,(118-ve.y)/4)
   yield()
  end
  ve.a=true
  wait=30
  while wait>0 do
   wait-=1
   yield()
  end
  ve.g=false
  anim=false
 end)
end

function present()
 local s,c,d=0,{},{}
 c.x,c.y,c.u,c.v,c.o,c.c
 =14,26,0,1,7,0
 d.x,d.y,d.u,d.v,d.o,d.c
 =-6,101,0,1,4,0
 fire(d,3,3,20000,arc(.5,.05),roundinf,.4,4,false)
 fire(c,8,2,30000,arc(.5,.03),roundinf,1,1,false)
 return cocreate(function()
  while true do
   spr(192,-49,16,9,2)
   if(s>15)spr(224,-50,30,2,2)
   if(s>16)spr(226,-35,30,1,2)
   if(s>17)spr(226,-28,30,1,2,true)
   if(s>18)spr(227,-22,30,2,2)
   if(s>19)spr(229,-7,30,1,2)
   if(s>20)spr(229,0,30,1,2,true)
   if(s>21)spr(226,7,30,1,2)
   if(s>22)spr(226,14,30,1,2,true)
   if(s>23)spr(230,20,30,2,2)
   if(s>24)spr(232,35,30,1,2)
   if(s>25)spr(232,42,30,1,2,true)
   if(s>39)rectfill(-49,44,15,50,1)rectfill(19,44,35,50,1)print("uncomprehensible zero",-48,45,13)
   if(s>44)rectfill(-49,50,-25,56,1)rectfill(-21,50,7,56,1)print("bomber fighter",-48,51,13)
   rectfill(-12,99,12,105,1)
   print("\151play",-11,100,7)
   if(s<75)s=s+1
   if s>30 and btnp(5) then
    anim=false
    scene=play
    for i=1,qs.l do
     qs[i].t=0
    end
   end
   yield()
  end
	end)
end

anim=false
function play()
 if ve.a then
  ctr()
 elseif not anim then
  anim=arrive(10)
 end
 if anim and costatus(anim) then
  coresume(anim)
 end
 upd()
 -- update level,spawn ship
 level() le.z+=1
end

titlerotpal=palrot({1,2,14},{1,2,14,15,13,12})

function title()
 if not anim then
  anim=present()
 end
 cls(1)
 pat(true)
 titlerotpal(0.2)
 bul()
 pal()
 if anim and costatus(anim) then
  coresume(anim)
 end
end

function ctr()
 -- move vessel
 ve.u,ve.v=0,0
 if(btn(0))ve.u-=ve.s
 if(btn(1))ve.u+=ve.s
 if(btn(2))ve.v-=ve.s
 if(btn(3))ve.v+=ve.s
 -- shoot beam/lazer
 if ve.a and btn(4) then
  if(not ve.l and ve.p>5.75)ve.l,ve.s=true,2 sfx(6,0) -- fixme: ve.s=2 !!!???
  if(ve.p<0)ve.l,ve.s=false,3 sfx(-2,0)
 else
  if(ve.l)ve.l,ve.s=false,3 sfx(-2,0)
 end
 if ve.a and btn(5) and not ve.l then
  if(not ve.b)ve.b,ve.s=true,3 sfx(0,0)
 else
  if ve.b then
   ve.b,be.d=false,0
   if(not ve.l)sfx(-2,0) ve.s=3
  end
 end
 lp[lp.i].x=ve.x
 lp[lp.i].y=ve.y
 lp.i=(lp.i%4)+1
 ve.x=mid(-60,60,ve.x+ve.u)
 ve.y=mid(4,126,ve.y+ve.v)
end

function pat(canshoot)
 -- update shape,shoot bullet
 for i=1,qs.l do
  q=qs[i] q.z+=1
  if q.t>0 then
   w=ang(q.h.x,q.h.y,ve.x,ve.y)
   if q.d>0 then q.d-=1
   else q.d=q.e
    for j=1,q.c do
     a,x,y,u,v
     =q.n(i,q,j,w)
     if(ve.a or canshoot)shoot(x,y,u,v,q.f,q.m)
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
  local d=dis(b.x-3,b.y-3,ve.x-4,ve.y-3)
  if ve.a and d>0 and not ve.g then
   if(d<6)dead()
   --todo reduce the distance
   --of touch
   if d<200 then
    ve.d=true
    power(ve,0.375)
    --co.sc=min(1500,co.sc+1)
   end
  end
  if b.x<-72 or b.x>72
  or b.y<-16 or b.y>142 then
   b.m,b.y,b.x=none,0,160 end
 end
end

function upd()
 ve.d=false
 -- draw score
 for i=1,9 do
  spr(ui.d[i],i*7-8,1)
 end --pal()palt()
 -- draw lazerbar
 spr(74,-65,122-ui.p)
 spr(75,-65,111,1,2)
 line(-63,115,-63,126-ui.p,1)
 line(-59,119,-59,130-ui.p,1)
 for i=0,2 do
  if ve.p>0.125 then
   c=12
   if(ve.p<5)c=6
   if(ve.p>ui.p-3.25)c=8
   line(-62+i,123+i,-62+i,123+i-ve.p,c)
  end
 end
 -- draw hit
 if ui.i>0 then
  if ui.i>48 then
   pal(2,7)pal(14,5)pal(4,5)
  end
  ui.i-=1
  for i=1,3 do
   spr(64+ui.c[i],-72+i*9,1,1,2)
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
  if(wa>40 and wa<43 or wa>114)pal(6,7)
  if(wa>40 and wa<116)print("100% bullets sstorm",-56,72,6)
  if(wa>50 and wa<53 or wa>112)pal(6,7)
  if(wa>50 and wa<114)print("#"..flr(wa/9%9).."."..(wa%9)..(wa%9)..(wa%9).."\x8132767\x99"..(shl(1,wa)%9).."\x80mk2",-56,79,6)
  if(wa>60 and wa<63 or wa>110)pal(6,7)
  if(wa>60 and wa<112)print("he is tough!!!",-56,86,6)
  pal()
  wa+=1
 end
 -- update,draw boss
 if le.bo then
  -- hp
  d=bo.b-bo.d
  if d>4 then
   bo.d+=bo.i
  elseif d<-2 then
   bo.d-=2
  else
   bo.d=bo.b
  end
  rectfill(-58,18,58,20,2)
  if bo.d>0 then
   rectfill(-58,18,bo.d/bo.m*116-58,20,14)
  end
  -- compute direction using target
  bd=dis(bo.x,bo.y,bo.u,bo.v)
  if bd<-1 or bd>1 then
   bu,bv=nor(aim(bo.x,bo.y,bo.u,bo.v))
   bu,bv=bu*bo.s,bv*bo.s
   bo.x+=bu
   bo.y+=bv
   for i=1,6 do
    bo[i].x+=bu
    bo[i].y+=bv
   end
  else
   bo.x=bo.u
   bo.y=bo.v
  end
  x,y=bo.x,bo.y
  spr(132,x-32,y-16,4,4)
  spr(136,x-32,y+0,4,2)
  spr(140,x-32,y+16,4,2)
  spr(132,x,y-16,4,4,true)
  spr(136,x,y+0,4,2,true)
  spr(140,x,y+16,4,2,true)
  -- check collision with boss
  --d=dis(bo.x,bo.y,ve.x,ve.y)
  --if(d<400)dead()
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
 if ve.g and le.z%4>1 then
  pal(10,7) pal(9,7)
  pal(4,7) pal(12,7)
  pal(13,7) pal(1,7)
  pal(2,7) pal(5,7)
 end
 spr(32,ve.x-8,ve.y-11,1,2)
 spr(32,ve.x,ve.y-11,1,2,true)
 pal()
 -- update beam
 if ve.b then
  if be.d==0 then
   be.d=be.e
   for j=0,1 do
    b=be[be.g]
    be.g=(be.g==be.l)and 1or be.g+1
    b.x=ve.x-8*j
    b.y=ve.y-24
   end
  else be.d-=1 end
  spr(16+be.f,ve.x-11,ve.y-16)
  spr(16+(be.f+2)%4,ve.x+3,ve.y-16,1,1,true)
  be.f=(be.f+1)%4
 end
 -- draw beam
 s2=false
 for i=1,be.l do
  b=be[i]
  if b.y>-16 then
   spr(36+((i+le.z)%2),b.x,b.y,1,2)
   if le.bo then
    -- collision with boss
    d=dis(bo.x-4,bo.y-8,b.x,b.y)
    if d>0 and d<700 then
     if(not s2)sfx(2) s2=true
     effect(b.x+8,b.y+16,beam)
     b.y=-128
     damage(bo,1,qs,ve,ui)
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
       damage(h,1,qs,ve,ui)
      end
     end
    end
   end
   b.y-=9
  end
 end
 -- draw lazer
 if ve.l then
  x,y,t,i=ve.x,ve.y,-16,false
  yy,hh=-99,false
  if le.bo then
   -- collision with boss
   if bo.x>x-30 and bo.x<x+31 then
    sfx(2)
    hh,yy=bo,bo.y-10
    if bo.x>x-6 and bo.x<x+7 then
     yy=bo.y+10
    elseif bo.x>x-20 and bo.x<x+21 then
     yy=bo.y+4
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
  if ve.p>ui.p-3.25 then
   if(la==16)la=25
   ld=1.7
   pal(7,0)pal(12,8)pal(6,2)
   palt(0,false)
  end
  la=max(16,la-1)
  if hh then
   sfx(7)
   damage(hh,ld,qs,ve,ui)
  end
  local lh=(le.z%2==0)
  sspr(48,21,16,3,x-la/2,t+16,la,y-t-24,lh,false)
  sspr(48,24,16,8,x-la/2,y-16,la,8,lh,false)
  if(hh)sspr(48,16,16,8,x-la/2,t+8,la,8,lh,false)
  pal()palt()
  ve.p=max(-1,ve.p-1)
 else
  power(ve,0.0625)
 end
 bul()
 -- draw vessel colision
 if ve.d then
  ve.z=(ve.z==3)and 0or ve.z+1
  spr(24+ve.z,ve.x-4,ve.y-3)
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
     damage(h,2,qs,ve,ui)
    end
   end
  end
 end
end

--scene=play
scene=title

function _init()
 cartdata("moechofe_md_1")
 printh("==========fresh start")
 menuitem(1,"mark here",mhere)
 menuitem(2,"mark behind",mhind)
 menuitem(3,"reset mark",mrese)
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
 -- ship warmup
 for i=1,hs.l do
  h={} hs[i]=h
  h.x,h.y,h.u,h.v,h.f,h.s,h.o,
  h.m,h.a,h.b,h.d,h.e,h.c,h.z,
  h.r,h.q,h.t
  =-128,0,0,0,0,0,0,none,false,
  0,0,0,0,0,0,0,0
 end
 -- formation warmup
 for i=1,fs.l do
  f={} fs[i]=f
  f.f,f.z=none,0
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
 for i=1,32 do
  s,b,f,l={},{},{},{}
  sp[i],bp[i],fp[i]
  =s,b,f
  s.x,s.y,s.f,s.z,s.f,s.t,s.d,
  s.a
  =0,-64,none,0,0,0,0,0
  b.x,b.y,b.c,b.r,b.f,b.z
  =0,-64,0,0,none,0
  f.x,f.y,f.c,f.r,f.f,f.z
  =0,-64,0,0,none,0
 end
 reset(1)
 if false then le.a=dget(63) end
end

--function _update()end

function _draw()
 camera(-64,0)
 rectfill(-64,0,64,127,0)
 scene()

 if false then -- debug
  print("m"..flr(stat(0)).." c"..flr(stat(1)*1000)/1000,18,1,7)
  print("z"..le.z..">"..flr(le.a),18,7,9)
  print(err,-57,122,8)
  --print("speed:"..co.ss.." count:"..co.sc.." hp"..co.hb,-60,30,10)

  x,y=le.a%128,flr(le.a/128)
  map(x-8,y,-68,17,32,1)
  spr(95,-7,14)
  spr(95,-2,14,1,1,true)
  spr(95,-7,19,1,1,false,true)
  spr(95,-2,19,1,1,true,true)
 end
end

__gfx__
0000000000eee0000088800001111100009990000000050000500000aaa4000099940000888e0000000111100001111000011110000111000001111000011110
000000000e222e0008f7f80011ccc11009aaa9000000050000500000aaaa4000999940008888e0000001cc100001cc100001cc100001c1000001cc100001cc10
00000000e21112e08f777f801c777c109af7fa900000600000060000666aa4001619940061688e0011111c1011111c1011111c101111c1101111c1101111c110
00000000e21112e0877777801c777c109a777a900700600000060070111aaa4016199940111888e01cc11c101cc1cc101cc1cc101cc1cc101cc1cc101cc1cc10
00000000e21112e08f777f801c777c109af7fa900707000000007070666aa4001619940061688e0011111c101111c11011111c1011111c1011111c101111cc10
000000000e222e0008f7f80011ccc11009aaa9000760000000000670aaaa4000999940008888e00000001c100001cc100001cc1000001c100001cc100001cc10
0000000000eee0000088800001111100009990000777700000077770aaa4000099940000888e0000000011100001111000011110000011100001111000011110
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002e2000000000000000000000000000
000000b0000000bb00000b000000b30000000000000000000000000000000000000000000000000000000000000000000e000e00000000000000000000000000
00b00bbb00000b7b00007b300007b30000070000000b000000030000000500000008800000088000000000000000000020000020000000000000000000000000
00000b770000b773000b7b3000bb30300077700000b7b000003b30000053500000822800008778000007700000022000e00000e0e00000e00000000000000000
0b00b77b0000b7b30007b330007b300000070000000b000000030000000500000082280000877800000770000002200020000020200000200000000000000000
0000b773000b773000b7330000b3030000000000000000000000000000000000000880000008800000000000000000000e000e000e000e000e000e0000000000
0000b7b3000b7b30000b3000000030000000000000000000000000000000000000000000000000000000000000000000002e2000002e2000002e2000002e2000
0000b7300000b3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000c000000020000200000002000000033000000330000ccc000c0cccc00c0506050006050000000506006500000000000560000077700005000000000000
000000c0000000200d020000000200000033330000333300ccccccc0cc7ccc000506050006050000000506000650500000505600000006700000607005000500
000000c0000000200d0200000000200003bbbb3003bbbb300cccc7ccc7c7ccc05666665066665500055666600065600000656000000060700000067000606000
00000ac000c000e00d0200000000200003b77b3003b77b30000c77777c7cc00c556665506665500000556660005660000066500000c5000000c0777000070000
c0000ac0c090c000ccc20000000c020003b77b3003b77b3000ccc767777cc0000506050006050000000506000566600000666500c090c000c090c00070707070
c000a9c0c222c0000c020000dddcc0e003b77b3003b77b30000cc767777cc0000000000000000000000000000000000000000000c222c000c222c00076000670
c00aacc00c2c0000000e0000000c000003bb7b3003b77b30000cc767777cc00000000000000000000000000000000000000000000c2c00000c2c000077707770
cc094cd1000000000000000000000000003bbb3003b7bb30000cc767777cc0000000000000000000000000000000000000000000000000000000000000000000
dc004d940000002000020000eeeee200003bbb3003bbbb30000cc767777cc0000055000000055000006600000006600000220000000022000000005011111110
dcc011410000020000020000ee02ee20003bb300033bb30000cc7767777cc000556550000055655066666000006666600200000000000020000706001c1c1c10
d1c12d120000e00000200000ee002ee0003bb300003b30300cc777677777cc0000660000000660000066000000066000200000e00e000002000760001c1c1c10
0d1c222100c0000000200000ee000ee00003b300003330300c77777777c77cc066666000006666605565500000556550200d00200200d00200c777001c1c1c10
0dd1c221c090c000020c0000ee002ee000303000000303000c777d777777d7c0006600000006600000550000000550002000002002000002c090c0001c1c1c10
00d1c1c2c222c000e0ccddd0ee02ee2000303030030303000ccc7c77d7d7cd00006000000000600000500000000050000200020000200020c222c0001c1c1c10
00dc00050c2c0000000c0000eeeee200000000300003000000cc7c770ccdc0000000000000000000000000000000000000222000000222000c2c000011111110
0dc000000000000000000000000000000000300000000300000cccc00d0000000000000000000000000000000000000000000000000000000000000000000000
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
02220000222200002222000022222000222220002222200002222000222220002222200022222000888888888888888888888888888888888888888812288990
22a220002a9200002a9220002a9920002a2920002a99200022a920002a9920002a9920002a9920000000000000000000000000000000000000000000228899a0
29292000229200002229200022292000292920002922200029222000222920002929200029292000888888288228828888802888800002882000288228899aa0
2929200002920000222920000292200029292000299220002922200002292000229220002929200080880808800880880080088028000800800280088899aa70
27272000027200002272200002272000277720002227200027772000027220002727200022772000008800088008808800000880080028008208800028899aa0
2e2e200022e220002e222000222e2000222e2000222e20002e2e200002e200002e2e2000222e20000088000880088088000008802800880088088000228899a0
22e220002eee20002eee20002ee22000022e20002ee220002eee200002e2000022e220002ee22000008800088008808808000888800088008800820012288990
02220000222220002222200022220000022220002222000022222000022200000222000022220000008800088888808888000880280088008800282000000000
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
4002fff2000822990e25888128820d4400000b3bb338825dd65550000002311600bbbbbbbbbbbbbb33000055518882220000000bb30000000000000666768888
f0221112008222440885288228800560000000bb3b3388255ddd55122882311600bbbbbb3bbbbbb33000000000822eee0000000b330000000000000066767888
f2222772082e72290885587202800050000000b3b3b33882555555128888b77600bbbbb30bbbbb3300000000022ee8880000000b300000000000000067667888
ff4227120827028a6d885712028200000000000b3bb33388211111128888bb6600bbbb300bbbbb30000000dddee888880000000b300000000000000007677788
4ff4222188222809d0085522002800000000000bbb3b333882555551288223bb000bb3300bbbb3300000ddddd88888880000000b300000000000000000677778
4fff40228e822800006d5002002d000000000000bbbb333356ddd55128221553000bb300bbbbb3000000ddddd888888800000000300000000000000000077770
44f0f0008e88800000d500000005600000000000bbb3b3356dd5551288215512000b3300bbbb33000000ddddd888888800000000000000000000000000000770
04f00f0088e800000d5000000000d00000000000bbbbb35dd555112882155512000b3000bbbb30000000ddddd888888800000000000000000000000000000000
00400000088000000d000000000005000000000bbbbb35d55551228821555182000b3000bbb3300000000ddddd88888800000000000000000000000000000000
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
00000000111000000111001110000000001110000000111000000000000000000000000000000000000000000000000000000000000000000000000000000000
111101111d11001111d1011d10111101111d101110111d1111100000000000000000000000000000000000000000000000000000000000000000000000000000
1dd111d11dd1011dd11111dd101dd111d111111d111d1d11dd100000000000000000000000000000000000000000000000000000000000000000000000000000
1d1d1d1d1d1101d111d11d1d101ddd1ddd1d11ddd1d1111d11100000000000111100000000000000000000000000000000000000000000000000000000000000
1d1d1d1d1d110111d1d11d1d101d1d1d111d11d111d100111d100000000000188100000000000000000000000000000000000000000000000000000000000000
1d1d11d111d101dd111d11dd101d1d11dd11d11dd1d1001dd1100000000000188100000000000000000000000000000000000000000000000000000000000000
11111111111101111011111111111111111111111111001111110000000000181110000000000000000000000000000000000000000000000000000000000000
11100011171000011111117101710011111171000011111101710111111011188810000000000000000000000000000000000000000000000000000000000000
1710001717111111777711710171011777717111101777711111017177111e181111000000000000000000000000000000000000000000000000000000000000
171111171777711711117171017101711111777711111117117101771111e1188811000000000000000000000000000000000000000000000000000000000000
171171171711171711117171017101710001711171177777117101711001e1111181100000000000000000000000000000000000000000000000000000000000
171171171710171777771171017101710001710171711117117101710001e1101118100000000000000000000000000000000000000000000000000000000000
1711711717101717111111711171117111117101717111171171117100011e111e11100000000000000000000000000000000000000000000000000000000000
11771771171017117777111771177117777171017117777171177171000011eee110000000000000000000000000000000000000000000000000000000000000
01111111111011111111111111111111111111011111111111111111000001111100000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111111111111100111111101111110001111111111110001111110001111111111110000000000000000000000000000000000000000000000000000000000
01777777777777111177777701777711001777711777711001777710001777711777710000000000000000000000000000000000000000000000000000000000
01777777777777711777777701777771101777711777771101777710001777711777710000000000000000000000000000000000000000000000000000000000
01777777777777711777777701777777111777711777777101777710001777711777710000000000000000000000000000000000000000000000000000000000
01666611111666611666611101666666611666611666666601666611111666611666610000000000000000000000000000000000000000000000000000000000
01777710001777711777711101777777771777711777777701777777777777111777710000000000000000000000000000000000000000000000000000000000
01777710001777711777777701777717777777711777717701777777777771111777710000000000000000000000000000000000000000000000000000000000
01777710001777711777777701777711777777711777711701777777777777111777710000000000000000000000000000000000000000000000000000000000
01777710001777711777711101777711177777711777711101777711111777711777710000000000000000000000000000000000000000000000000000000000
01777711111777711777710001777710117777711777710001777710001777711777711100000000000000000000000000000000000000000000000000000000
01777777777777711777710001777710011777711777710001777710001777711777777700000000000000000000000000000000000000000000000000000000
01777777777777711777710001777710001777711777710001777710001777711777777700000000000000000000000000000000000000000000000000000000
01777777777777111777710001777710001777711777710001777710001777711177777700000000000000000000000000000000000000000000000000000000
01111111111111101111110001111110001111111111110001111110001111110111111100000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111cdddc111111111111cdddc11111111111111cdddc1111111111
111111111111111111111111111111111111111111111111111111111111111111111111111111ccc11111111111111ccc1111111111111111ccc11111111111
1111111ccc111111111111111111111111111111111111111111111111111111111111111111111111ccc1111111111111111111111111111111111111111111
111111cdddc1111111111111111111111111111111111111111111111111111111111111111111111cdddc111111111111111111111111111111111111111111
111111cdddc11111111111111111111111111111111111111111111111ccc11111ccc111111111111cdddc111111111111111111111111111111111111111111
111111cdddc111111111111111111111111111111111111111ccc1111cdddc111cdddc11111111111cdddc1111111111ccc11111111111111111111111111111
1111111ccc111111111111111111111111111111111111111cdddc111cdddc111cdddc111111111111ccc1111111111cdddc1111111111111111111111111111
1111111111111111111111111111111111111111111111111cdddc111cdddc111cdddc1ccc111111111111111111111cdddc1111111111111111111111111111
1111111111111111111111111111111111111111111111111cdddc1111ccc11111ccc1cdddc1111111111ccc1111111cdddc1111111111111111111111111111
1111111111111111111111111111111111111111ccc1111111ccc11111111111111111cdddc111111111cdddc1111111ccc1111111111111ccc1111111111111
111111111111111111111111111111111111111cdddc11111111111111111111111111cddd1ccc111111cdddc1111111111111111111111cdddc111111111111
111111111111111111111111111111111111111cdddc111111111111111111111111111cc1cdddc11111cdddc1111111111111111111111cdddc111111111111
111111111111111111111111111111111111111cdddc111111111111111111111111111111cddd111111111111111111111111111111111cdddc111111111111
1111111111111111111111111111111111111111ccc1111111111111111111111111111111cdd1ccc1111ccc11111111ccc1111111111111ccc1111111111111
111111111111111111111111111111111111111111111111111111111111111111111111111c1cdddc11cdddc111111cdddc1111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111111ccc11ccc1ccc1111cdddc11cdddc111111cdddc1111111111111111111111111111
1111111111111111111111111111111ccc11111111111111111111111111cddd1cdd1cdddc111cd11111c111c111111cdddc1111111111111111111111111111
111111111111111111111111111111cd111111111111111111111111111111dd1cdd1cddd1ccc11ccc111ccc11111111ccc11111111111111111111111111111
111111111111111111111111d11111111d1111d11111111111d11111c111d11111dd1cdd1cdddc1dddc1cdddc1111ccc1111111111111ccc1111111111111111
1111111111111111dd111d11dd1111dd11111dd111dd111d111111d111d1d11dd1ccc1cc1cdddc1dddc1cdddc111cdddc11111111111cdddc111111111111111
1111111111111111d1d1d1d1d1111d111d11d1d111ddd1ddd1d11ddd1d1111d1111111111cddd1111dc111ddc111cdddc11111111111cdddc111111111111111
1111111111111111d1d1d1d1d111111d1d11d1d111d1d1d111d11d111d111111d11111ccc1ccc1881c1ccc1c11111dddc11111111111cdddc111111111111111
1111111111111111d1d11d111d111dd111d11dd111d1d11dd11d11dd1d1111dd11cc1cdddc11118811cdddc111ccc1cc1111111111111ccc1111111111111111
1111111111111111111111111111111111111111111111111111111111111111111d1cdddc11118111cdddc11cdddc1111111111111111111111111111111111
11111111111111111111111171111111111117111711111111171c1111111111171d11111111118881cdddc111dddc1111111111111111111111111111111111
1111111111111111711111717111111777711711171111777717111111777711111d17177111e181111ccc1ccc1ddc111111111ccc1111111111111111111111
1111111111111111711111717777117111171711171117111117777111111171171c1771111e11888111111dddc1c111111111cdddc111111111111111111111
111111111111111171171171711171711117171117111711111711171177777117111711dc1e11111811ddc1ddc11111111111cdddc111111111111111111111
11111111111111117117117171117177777117111711171111171117171111711711171ddc1e11111181ddc1ddc11111111111cdddc111111111111111111111
11111111111111117117117171117171111117111711171111171117171111711711171ddc11e111e111ddc1cc11111111ccc11ccc1111111111111111111111
11111111111111111771771171117117777111771177117777171117117777171177171cc1c11eee111ccc11111111111cdddc11111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111ccc111
11111111111111117777777777771117777777777711777711111777717777111117777117777777777711777711cc177771777711111777711111111cdddc11
11111111111111117777777777777177777777777771777771111777717777711177777177777777777771777711dd177771777711111777711111111cdddc11
11111111111111117777777777777177777777777771777777111777717777771777777177777777777771777711dd177771777711111777711111111cdddc11
11111111111111116666111116666166661111166661666666611666616666666666666166661111166661666611111666616666111116666111111111ccc111
11111111111111117777111117777177771111177771777777771777717777777777777177771111177771777777777777117777111117777111111111111111
11111111111111117777111117777177777777777771777717777777717777177717777177777777777771777777777771117777111117777111111111111111
111111111111111177771111177771777777777777717777117777777177771171177771777777777777717777777777771177771111177771c1111111111111
111111111111111177771111177771777711111777717777111777777177771111177771777711111777717777111117777177771111177771dc111111111111
11111111111111117777111117777177771111177771777711117777717777111117777177771cdd1777717777111117777177771111177771dc111111111111
111111111111111177777777777771777711111777717777111117777177771111177771777711cc1777717777111117777177777777777771dc111111111111
111111111111111177777777777771777711111777717777111117777177771111177771777711111777717777111117777177777777777771c1111111111111
11111111111111117777777777771177771111177771777711111777717777111117777177771111177771777711111777711777777777771111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111111d1d1dd111dd11dd1ddd1ddd1ddd1ddd1d1d1ddd1dd111dd1ddd1ddd1d111ddd11111ddd1ddd1ddd11dd111cdddc111111111111111111111
1111111111111111d1d1d1d1d111d1d1ddd1d1d1d1d1d111d1d1d111d1d1d1111d11d1d1d111d111111111d1d111d1d1d1d1111ccc1111111111111111111111
1111111111111111d1d1d1d1d111d1d1d1d1ddd1dd11dd11ddd1dd11d1d1ddd11d11dd11d111dd1111111d11dd11dd11d1d11111111111111111111111111111
1111111111111111d1d1d1d1d111d1d1d1d1d111d1d1d111d1d1d111d1d111d11d11d1d1d111d1111111d111d111d1d1d1d11111111111111111111111111111
11111111111111111dd1d1d11dd1dd11d1d1d111d1d1ddd1d1d1ddd1d1d1dd11ddd1ddd1ddd1ddd11111ddd1ddd1d1d1dd111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111111ddd11dd1ddd1ddd1ddd1ddd1ddc1ddd1ddd11dd1d1d1ddd1ddd1ddd111cdddc1111111111111111111111111111111111111111111111111
1111111111111111d1d1d1d1ddd1d1d1d111d1d1ddc1d1111d11d111d1d11d11d111d1d111cdddc1111111111111111111111111111111111111111111111111
1111111111111111dd11d1d1d1d1dd11dd11dd11ddc1dd111d11d111ddd11d11dd11dd1111cdddc1111111111111111111111111111111111111111111111111
1111111111111111d1d1d1d1d1d1d1d1d111d1d1cc11d1111d11d1d1d1d11d11d111d1d1111ccc11111111111111111111111111111111111111111111111111
1111111111111111ddd1dd11d1d1ddd1ddd1d1d11111d111ddd1ddd1d1d11d11ddd1d1d111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111111111111111111111111111ccc1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111111111111111111111111111111111cdddc111111111111111111111111111111111111111111
111111111111ccc111111111111111111111111111111111111111111111111111111111111111111cdddc111111111111111111111111111111111111111111
11111111111cdddc1111111111111111111999111111111111111111111111ccc1111111111111111cdddc11111ccc1111111111111111111111111111111111
11111111111cdddc1111111111111111119aaa91111111111111111111111cdddc1111111111111111ccc11111cdddc111111111111111111111ccc111111111
11111111111cdddc111111111111111119af7fa9111111111111111111111cdddc111111111111111111111111cdddc19111111ccc111111111cdddc11111111
111111111111ccc1111111111111111119a777a9111111111111111111111cdddc111111111111111111111111cdddc1911111cdddc11111111cdddc11111111
1111111111111111111111111111111119af7fa1ccc1111111111111111111ccc11199911111111111111111111ccc1a911111cdddc11111111cdddc11111111
11111111111111111111111111111111119aaa1cdddc111111111111111111111119aaa91111111111111111111111a9111111cdddc111111111ccc111111111
111111111111111111111111111111111119991cdddc11111111111111111111119af7fa9111111111111111111199911111111ccc1111111111111111111111
111111111111111111111111111111111111111cdddc11111111111111111111119a777a91111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111ccc111111111111111111111119af7fa91111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111119a11111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111111111111111111111ccc11111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111cdddc1111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111cdddc1111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111199911111111111cdddc1111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111119aaa911111111111ccc11111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111119af7fa9111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111119a777a9111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111119af7fa9111111111111111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111119aaa91111111111111111111111111111111111111111111111111111111111111111111111
111111111111ccc111111111111111111111111111111ccc1111119991111111111111111111111ccc1111111111111111111111111111111111111111111111
11111111111cdddc1111111111111111111111111111cdddc11111111111111111111111111111cdddc111111111111111111111111111111111111111111111
11111111111cdddc1111111111111111999111111111cdddc11111111111111111111111111111cdddc111111111111111111111111111111111111111111111
11111111111cdddc1111111111111119aaa911111111cdddc11111111111111111111111111111cdddc111111111111111111111111111111111111111111111
111111111111ccc1111111111111119af7fa911111111ccc1111111111111111111111999111111ccc1111111111111111111111111111111111111111111111
1111111111111111111111111111119a777a9111111111119991111111111111111119aaa9111111111111111111111111111111111111111111111111111111
1111111111111111111111111111119af7fa911111111119aaa911111111111111119af7fa9111111111111111111ccc11111111111111111111111111111111
11111111111111111111111111111119aaa911111111119af7fa91111111199911119a777a911111111199911111cdddc1111111111111111111111111111111
11111111111111111111111111111111999111111111119a777a911111119aaa91119af7fa9111111119aaa91111cdddc1111111111111111111111111111111
11111999111111111111111111111111111111111111119af7fa91111119af7fa91119aaa9111111119af7fa9111cdddc1111111111111111111111111111111
11119aaa9111111111111111111111111111111111111119aaa911111119a777a911119991111111119a777a91111ccc111111111111111ccc11111111111111
1119af7fa911111111111111111111111111111111111111999111119999af7fa911111111111111119af7fa9111111111111111111111cdddc1111111111111
1119a777a91111111111111111111111111111111111111111111119aaa99aaa91111111111111111119aaa91111111111111111111111cdddc1111111111111
1119af7fa9111111111111111111111111111111111111119991119af7fa99991111111111111111111199911111111111111111111111cdddc1111111111111
11119aaa9111111111111111111111111111111111111119aaa9119a777a911111111111111111111111111111111111111111111111111ccc11111111111111
11111999111111111111111111111111111199911111119af7fa919af7fa99991199911111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111119aaa91111119a777a91999aa99aaa99aaa91111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111119af7fa9111119af7fa99aaa999af7fa9f7fa9111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111119a777a91111119aa999af7fa99a777a9777a9111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111119af7fa9111111199aa9a777a99af7fa9f7fa9111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111119aaa9111111119af79af7fa91999999aaa91119991111111111111111111111119991111111111111111111111111
1111111111111111111111111111111111119991111111119a77111111111111111111111111111111111111111111111119aaa9111111111111111111111111
1111111111111111111111111111111111111111111999119af711777771177717111777171719111111111111111111119af7fa911111111111111111111111
111111111111111111ccc1111111111111111111119aaa9119aa17717177171717111717171719111111111111111111119a777a911111111111111111111111
11111111111111111cdddc11111111111111111119af7fa9119917771777177717111777177719111111111111111111119af7fa911111111111111111111111
11111111111111111cdddc11111111111111111119a777a919aa177171771711171117171117111111111111111111111119aaa9111111111111111111111111
11111111111111111cdddc11111111111111111119af7fa99af71177777117111777171717771111111111111111111111119991111111111111111111111111
111111111111111111ccc9991111111111111111119aaa919a771111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111111111119aaa9111111111111111111999119af7f9aaa9777a99aaa9111111111111111111111111111111111111111111111111111111111111
11111111111111111119af7fa9111111111111111111111119aaa9999af7fa919991111111111111111111111111111111111111111111111111111111111111
11111111111111111119a777a911111111111111111111111199911999aaa911199911ccc1111119991111111111111111111111111111111111111111111111
11111111111111111119af7fa911111111111111111111111111119aaa9991119aaa9cdddc11119aaa9111111111111111111111111111111111111111111111
111111111111111111119aaa911111111111111111111111111119af7fa91119af7fa9dddc1119af7fa911111111111111111111111111111111111111111111
111111111111111111111999111111111111111111111111111119a777a91119a777a9dddc1119a777a911111111111111111111111111111111111111111111
111111111111111111111111111111111111999111111111999119af7fa91119af7fa9ccc11119af7fa911111111111111111111111111111111111111111111
111111111111111111111111111111111119aaa911111119aaa9119aaa9111119aaa91111111119aaa9111111111111111111111111111111111111111111111
11111111111111111111111111111111119af7fa9111119af7fa9119991111111999111111111119991111111111111111111111111111111111111111111111
11111111111111111111111111111111119a777a9111119a777a9111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111119af7fa9111119af7fa9111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111119aaa911111119aaa91111111111199911111111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111999111111111999111111111119aaa91111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111119af7fa9111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111119a777a91111111111111111111111ccc11111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111119af7fa9111111111111111111111cdddc1111111111111111111111111111111111
111111111111111111111111111111111111111111111111111111111111119aaa91111111111111111111111cdddc1111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111199911111111111111111111111cdddc1111111111111111111111111111111111
111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111ccc11111111111111111111111111111111111
111111111111111111111111111111ccc11111111111111111111111111111111111111111111111199911111111111111111111111111111111111111111111
11111111111111111111111111111cdddc11111111111111111111111111111111111111111111119aaa91111111111111111111111111111111111111111111
11111111111111111111111111111cdddc1111111111111111111111111111111111111111111119af7fa9111111111111111111111111111111111111111111

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
60706070607000000000000029092f831f22833171837071830b01830a01832a830a01830a01830a01810a010500002b082f811c3b092f0078836175837221830d0707040c06060b06060a06060d2e09090c05050b05050a050500082f1f73617072313a82003982003a82003982003a820039823f0f0e0d0c0b0a0100000000
2a072f801c213c3c73607362780a070100082f29820a062f717974311f022e090000000000000000000000000000002a08083e05821f71798272310b82020b020a02002b062f09801c3c3c3c76730a07070708627022047376740100000000000000000000000a092d0909000000000000000000006070607060702f00787774
00290906821c31820b070607820b0706070a0706070c070505010b070505010a07050501000000002907062f911c3c21737362700a04002f092b05833906832b05833906832b05833906830000000000293e0909311f7178607200930a03930a03930a03930a0300000000000000000000000000000000000000000000000000
006070607060707f00090000000000000000080000000000070008285e39004f4f384e1f607279617321390a010b0100003a0000001c6174703b60710f02000000384e093b4f4f4f5e073a4e211e5a60757369703f0a0b030000211c63727160720e010000000000000e01000e01000000003b000e01000e010000000000000e
01000000000e01000e010000000000000e01000e010000000000000e01000e01000000384e19284f4f4f5e004e000000211d61747363773c3c0e01000000000000311f5a60717860733f0c0d03000000004e093b380039003a0039285e004f4f4f4f4e211c3d3d3d3d61717363760e040000213c1c6078736172100f01000000
000000000000000000000000000000000000000000000000004e00000000006f000000000000000000000000000000000000000000000000000000000000000000000000000000006f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0101000b00000090300b3401005012050107300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0107080a39512395123851237512355222f5222053110531045450457500505005050050500505005050000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200003c54300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600001065300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100090f61600000096301261600000000001c61700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400002d6513366009660256650a66323655076501e6451364006640026200162001620016100160001600016000b6000e600256000d6001160012600156000000000000000000000000000000000000000000
00060006071320a1360f5210a1310b1360a1360000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002e72300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f00200170704707027000d707117070f700017000570002700197001d7001a7000170005700027000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f001e1560634503000002460500000000001560634503000002460500000000001560634503000002460500000000001560634503000002460500000000001560634503000002460500000000000560000000
011100201f7551f752325151f7551f7522b1143251521755227551f7551f752186031f7551f7522b11432515137551b75233515137551b7522e114335151d7521b752137551a75218603137551a7523011435515
011100201120307050070503251507050070500705032515130333251507050070503251507050070501303313001030500305033515030500305003050335151103335515050500505035515050500505011033
011100201222513335134251333512225133351642513335112251333513425133351622513335164251333516225163350a425163350a2251633518425163351522515335094251533515225133351142513335
0111002032515296452f613325151f640325152f6132f61332515296452f61332515186402f6132f6232f61333515296452f6133351518640335152f6132f61335515296432f61335515186402f613355152f613
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011c00000a737017370a7370173710737017370f737017370a737017370a7370173710737017370f73701737077370173708737017370973701737077370173708737017370973701737077370d7370873701737
011000001c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 0d0c0a0b
02 0d0c0a0b
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 50424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

