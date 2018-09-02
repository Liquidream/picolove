pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- low mem sky (#demakejam)
-- paul nicholas

curr_mode=0
-- 0=title
-- 1=galaxy
-- 2=system
-- 3=planet
-- 

--[music]
-- 00 - intro
-- 01 - shortwave
-- 17 - eotws_variation 1
-- 23 - velocity
playlist={1,7,23}
now_playing=-1

-- main loop
function _init()
 init_player()
 if (curr_mode<=1) then init_galaxy()
 elseif (curr_mode==2) then init_system()
 elseif (curr_mode==3) then init_surface()
 end
end

function _draw()
cls()
	-- draw title
	if (curr_mode<=1) then draw_galaxy()
 elseif (curr_mode==2) then
  if warp_count==0 then
   draw_system()
  else
   draw_warp()
  end
	elseif (curr_mode==3) then draw_surface()
	end
	-- debug
	-- print("cpu: "..flr(100*stat(1)).."%", 2, 2, 12) 
 -- print("mem: "..flr(stat(0)/1024*100).."%", 2, 8, 12)

	--printh("cpu: "..flr(100*stat(1)).."%") 
end

function _update60()
	if curr_mode<=1 then update_galaxy() 
 elseif curr_mode==2 then update_system() 
 elseif curr_mode==3 then update_surface()
 end
end

function init_player()
 -- todo: load saved data
 player_idle_anim={247,247}
 player_walk_anim={247,248}

 player={
  spr=247,
  x=0,
  y=0,
  health=100,
  mining_health=100,
  weapon_ammo=0,
  run=false,
  scanner_level=100,
  inv={},
  tmr=0,
  anim_pos=1,
  frame_delay=6,
  curr_anim=player_idle_anim,
  flipx=false,
  in_ship=true,
 }

 -- init player inventory
 for i=1,64 do player.inv[i]=0 end

 ship = {
  x=0,
  y=0,
  obj_type=3,  
  -- 1=planet, 2=space station, 3=ship, 4=flower, 
  -- 5=collectable, 6=mineable, 7=base?
  skin=3,
  thrust=0,
  dx=0,
  dy=0,
  aim=0, --.25
  trail={},
  landed=false
 }
end

--[[
--galaxy spiral code

e=2.71828
cols={0,1,12,14,7,7,7}
::_::
cls()
srand()
for n=2.5,0,-.1 do
 for i=min(n,5),45 do
  x=cos(e*i+t()/(e*10)-n/(e*7))*(i-n)/e*4+64
  y=sin(e*i+t()/(e*10)-n/(e*10))*(i-n)/e*2+64
  size=3-(i/28)+((sin()))
  circfill(x,y,size+.2-rnd(2),cols[flr(3*size-3)+flr(rnd(3))])--7-(n%2))
 end
end

flip()goto _ 

]]
-->8
-- galaxy map/title level


last_camx=0
last_camy=0
space={}
  -- 1=near star pages/sector
  -- 2=mid star pages/sector
  -- 3=far star pages/sector
scale=1 --.5
num_stars=7 -- per sector
star_cols={12,7,6,5,2,1,1}
max_depth=6
depth_offset=.0001
cam_speed=.00002--.0002
cam_maxspeed=.0004
hov_dist=5
curr_system=nil
curr_planet=nil
factions={"korvax","gek","vy'keen"}
warp_count=0

camx=0
camy=0
saved_galaxy_x=0--0.0955
saved_galaxy_y=0---0.057
sdist=nil --take first measurement
prev_star_hov=nil
_t=0
auto_start_time=320+rnd(100)
--printh(auto_start_time)
ready_to_begin=false
banner_count=0

function init_galaxy()
 printh("init_galaxy()...")
	camera()
 camx=saved_galaxy_x
 camy=saved_galaxy_y
 cam_dx=0
 cam_dy=0
	
 -- title?
 --if (curr_mode==0) music(0)

	-- create initial stars
	for d=1,max_depth do
		space[d]={}
		space[d].br_secx=0
		space[d].br_secy=0
  space[d].tl_secx=0
		space[d].tl_secy=0
		space[d].pages={}
		--for p=1,1 do
			space[d].pages[1]=
				make_sector(0,0,d,num_stars)
		--end
	end
end

function draw_galaxy()
--printh("draw_galaxy()...")
 cls()

 -- todo:seed to sector num?
 -- srand(1)

 fillp()
	
 star_hov = nil
 star_curr = nil

	-- loop through all depths
 for d=max_depth,1,-1 do
 --d=1
		camera(camx,camy)
	 local star_depth=space[d]
 	-- loop through all star pages
 	for p=1,4 do
 	 local page=star_depth.pages[p]
   
   -- bugfix for edge-case!
   if (page==nil) return

  	for s in all(page.stars) do
  		-- draw star
  		s.sx=s.x*scale-(camx/d)/depth_offset
  		s.sy=s.y*scale-(camy/d)/depth_offset
  		  		
  		if s.name 
     and s.sx>=64-hov_dist and s.sx<=64+hov_dist 
     and s.sy>=64-hov_dist and s.sy<=64+hov_dist then
      -- star in hover range
      -- is it closest to cursor?
      s.dist=dist(s.sx,s.sy,64,64)
      if star_hov == nil or s.dist < star_hov.dist then
       -- new closest star (to cursor)
       star_hov = s
      end
    end
    
    pset(s.sx,s.sy,s.col)

    -- names on title screen?
    if curr_mode==0 and s.seed<100 then
     print(s.name,s.sx-10,s.sy-7,s.col)
  	 end
    -- current?
    if curr_system 
     and curr_system.name==s.name then
     star_curr = s
    end
  	end
  end  -- pages	

 	--print("sector:"..space[1].tl_secx..","..space[1].tl_secy, 50, 2, 8)

 end -- depth

 
 -- title/galaxy mode
 if curr_mode==0 then

  draw_title()

  if (ready_to_begin and star_hov and wfade>=16) set_start_sys(star_hov)

  -- fades
  if (wfade>=0) fade(wfade, fade_table_white, 7, 1)
 else
  print(smallcaps("galactic core"),2,2,5)
  print("715597 ly",2,9,5)

  if star_curr then
   -- mark curr system
   circ(star_curr.sx,star_curr.sy,3,7)
  end

  if star_hov then
   
   -- current?
   if star_curr then
    -- measure dist (only once)
    if (sdist==nil) sdist=dist(star_curr.sx,star_curr.sy,star_hov.sx,star_hov.sy)
    
    -- plot course?
    if star_hov.name==curr_system.name then
     print("you are here",2,121,2)
    elseif sdist<=player.inv[20]*20 then
     line(star_curr.sx,star_curr.sy,star_hov.sx,star_hov.sy,9)
     print("press ❎ to warp ("..flr(sdist).."ly)",2,121,9)
    else
     local diff=flr((sdist-player.inv[20]*20)/20)+1
     fillp(0X5A5A)
     line(star_curr.sx,star_curr.sy,star_hov.sx,star_hov.sy,9)
     fillp()
     print("requires "..diff.." more warp cells",2,121,9)
    end
   end
   print(star_hov.name,star_hov.sx-10,star_hov.sy-7,star_hov.col)
   circ(star_hov.sx,star_hov.sy,1,star_hov.col)

   -- bottom portion
   print(star_hov.name..smallcaps(" system"),2,98,7)
   print(star_hov.num_planets..smallcaps(" planets"),2,105,6)
   print(smallcaps(star_hov.faction),2,112,6)
   
   
   -- check for change in hov (recalc dist)
   if (not prev_star_hov or star_hov.name!=prev_star_hov.name) prev_star_hov=star_hov sdist=nil
  end

  camera()

  spr(255,61,61)

 end -- title?

end

function set_start_sys(sys)
 -- todo: pick a random sys
 curr_system=sys
 saved_galaxy_x=camx
 saved_galaxy_y=camy
 init_system()
 -- todo: pick a random planet
 curr_planet=curr_system.planets[1]
 -- now jump to surface
 curr_mode=3

 init_surface()

 -- default to walking
 landing=true
 ship.landed=true
 player.in_ship=false
 return
end

function update_galaxy()	
--printh("update_galaxy()...")
 -- remember...
 last_camx=camx
 last_camy=camy
 
 local speed=cam_speed*scale


 -- title or map?
 if curr_mode==0 then
  -- auto-move camera pos
  camx+=speed*25
  _t+=.1
  if (btnp(5) or _t>auto_start_time) and (not ready_to_begin)  then 
   ready_to_begin=true
   wfade=0
   --sfx(60,3)
  end
  if (wfade>=0) wfade+=.25
 else
  -- galaxy map

  if(btn(0)) cam_dx-=speed
  if(btn(1)) cam_dx+=speed
  if(btn(2)) cam_dy-=speed
  if(btn(3)) cam_dy+=speed

  -- cancel
  -- >>> issue here as it flips back and forth!!!
  if(btnp(4) and warp_count==0) curr_mode=2 init_system() 

  -- warp (only if diff system!)
  if btnp(5) 
  and star_hov 
  and (curr_system==nil or curr_system.name!=star_hov.name) then
   -- save galaxy pos
   saved_galaxy_x=camx
   saved_galaxy_y=camy
   -- warp to new sys
   curr_system=star_hov 
   curr_mode=2 
   init_system() 
   warp_count=1
   -- sfx
   --music(-1,10)
   sfx(47,3)
  end

  -- stop?
  if (not btn(0)) and (not btn(1)) then
   cam_dx/=1.001
  else
   cam_dx=mid(-cam_maxspeed,cam_dx,cam_maxspeed)
  end 
  if (not btn(2)) and (not btn(3)) then
   cam_dy/=1.001
  else
   cam_dy=mid(-cam_maxspeed,cam_dy,cam_maxspeed)
  end 

 end -- title or map?
 



	
	camx+=cam_dx
 camy+=cam_dy


 
-- printh("camx = "..camx)
-- printh("camy = "..camy)
 
 -- loop through all depths
	for d=1,max_depth do
 --d=1
		local star_depth=space[d]
		
  -- check paging 
  -- (top-left & bottom-right corners for each depth)
  
  -- bottom-right
  local new_br_secx=
   flr((camx+127+(camx/d)/depth_offset)/127)
  local new_br_secy=
   flr((camy+127+(camy/d)/depth_offset)/127)
  -- top-left
  local new_tl_secx=
   flr((camx+(camx/d)/depth_offset)/127)
  local new_tl_secy=
   flr((camy+(camy/d)/depth_offset)/127)

  -- bottom-right
  if new_br_secx!=star_depth.br_secx 
   or new_br_secy!=star_depth.br_secy 
   or new_tl_secx!=star_depth.tl_secx 
   or new_tl_secy!=star_depth.tl_secy 
   then
  	-- moved into new sector
   -- create all new pages
   -- (assume all changed too)
   star_depth.pages[1]=make_sector(new_tl_secx,new_tl_secy,d,num_stars)
   star_depth.pages[2]=make_sector(new_tl_secx+1,new_tl_secy,d,num_stars)
   star_depth.pages[3]=make_sector(new_br_secx-1,new_br_secy,d,num_stars)
   star_depth.pages[4]=make_sector(new_br_secx,new_br_secy,d,num_stars)

   star_depth.tl_secx=new_tl_secx
   star_depth.tl_secy=new_tl_secy
   star_depth.br_secx=new_br_secx
   star_depth.br_secy=new_br_secy
  end
 end --depths
 
end

title_msg_line1={
 "    by paul nicholas",
 " ♪ by chris donnelly",
 "inspired by no man's sky"
}

title_msg_line2={
 "      @liquidream",
 "     @gruber_music",
 "     by hello games"
}

function draw_title()
 camera()

 if (_t<16) fade(16-_t,fade_table_black,0,0)  
 if (_t>0) spr(80,13,50,13,3) 
 pal()

 --printh("_t=".._t)
 if _t>15 and _t<105 then
  outline_text(title_msg_line1[flr((_t-15)/30)+1],17,100,6,1)
  outline_text(title_msg_line2[flr((_t-15)/30)+1],17,109,12,1)
 elseif _t>15 then
  outline_text("press ❎ to start",30,100,6,1)
 end
end

function draw_warp()
 cls(10)
 for i=1,50 do
  local x,y=rnd(127),rnd(150)
  line(x,y,x,y-rnd(50),rnd(16))
 end
 
end

function make_sector(secx,secy,depth,num_stars)
 local sector={}
 sector.stars={}
 
 -- calc sys number
 sector.sysnum=depth*1000+secx+secy/1000
 --printh("sysnum="..sector.sysnum)
 srand(sector.sysnum)
	
 for i=1,num_stars do
  local sys={
   x=secx*127+rnd(127),
   y=secy*127+rnd(127),
   col=star_cols[depth+flr(rnd(2))],
   secx=secx,
   secy=secy,
   name=getsystemname(
  	 secx,secy,rnd(32000)),
   seed=rnd(32000),
   faction=factions[flr(rnd(3)+1)],
   bgcol=flr(rnd(4)),
   num_planets=flr(rnd(8)+1),
   planets=nil
  }
  add(sector.stars,sys)
 end
 
 return sector
end

function getsystemname(secx,secy,sysnum)
	local namepart=
	  {"en", "la", "can","be",
    "and","phi","eth","ol",
    "ve", "ho", "a"  ,"lia",
    "an", "ar", "ur" ,"mi",
    "in", "ti", "qu" ,"so",
    "ed", "ess","ex" ,"io",
    "ce", "ze", "fa" ,"ay",
    "wa", "da", "ack","gre"}
	local name=""

 for i=1,flr(rnd(1)+3) do
  name=name..namepart[flr(rnd(#namepart))+1]
 end

 name=smallcaps(name)

	return name
end

-- fixed sqrt to avoid overflow
-- https://www.lexaloffle.com/bbs/?tid=29528
function dist(x1,y1,x2,y2)
 local a=x1-x2
 local b=y1-y2
 local c=sqrt((a/16)^2+(b/16)^2)*16
 return c
end
-- function dist(x1,y1,x2,y2)
--  local a=x1-x2
--  local b=y1-y2
--  local c=sqrt((a*a)+(b*b))
--  return c
-- end


-->8
-- star system level

sector_size=1000 --3000
astorbit=100

landing=false
wfade=-2

--debug
--srand(0)

function init_system()
 printh("-------- init system -----")

  -- ####################################
 -- debug
 -- if curr_system==nil then
 --  srand(4) --4
 --  pal()
 --  palt()
 --  cls(15)
 --  curr_system={
 --   seed=rnd(32000),--0,
 --   bgcol=1,
 --   num_planets=8,
 --   planets={},
 --   station={}
 --  }
 --  for i=1,curr_system.num_planets do
 --   curr_planet=create_planet(rnd(32000),i)
 --   add(curr_system.planets,curr_planet)
 --  end
 --  -- copy screen to user memory
 --  memcpy(0x4300,0x6000,0x1000)
 --  -- reset sprites
 --  reload()

 --  -- create station
 --  curr_system.station={
 --   obj_type=4,
 --   x=ship.x+rnd(50)+50,
 --   y=ship.y+rnd(50)+50,
 --   rot=0,
 --   col1=rnd(16),
 --   col2=rnd(16)
 --  }

 --  ship.landed=false
 --  player.in_ship=true
 -- end
 -- ####################################

 srand(curr_system.seed)
 create_stars()

 -- create planets/station?
 -- (only on first entry)
 if curr_system.planets == nil then
  curr_system.planets={}
  printh(">>>>>>> create planets <<<<")
  pal()
  palt()
  cls(15)  
  for i=1,curr_system.num_planets do 
   -- add planet
   local p=create_planet(rnd(32000),i)
   add(curr_system.planets,p)
   
   --debug
   printh("planet x,y:"..p.x..","..p.y)
  end
  -- copy screen to user memory
  memcpy(0x4300,0x6000,0x1000)
  -- reset sprites
  reload()

  -- create station
  curr_system.station={
   x=ship.x+rnd(50)+50,
   y=ship.y+rnd(50)+50,
   rot=0,
   col1=rnd(16),
   col2=rnd(16)
  }
 end
end

function update_system()
 --printh("update_system()...")
 -- warping
 if warp_count>0 then
  warp_count+=1
  if warp_count > 100 then
   warp_count=0
  end 
 end
 
 -- landing/takeoff
 if takingoff then
  wfade-=.25
  if wfade <= 0 then
   takingoff=false
   wfade=-2
  end
 elseif landing then
  wfade+=.25
  if (wfade >= 5) curr_mode=3 init_surface() ship.thrust=0
 end
 
 -- update ship
 update_player()
 

 for i=1,#stars do
  local s=stars[i]
  -- update starfield
  update_star(s, ship.dx, ship.dy)
 end

 -- create thrust particles
 local engine_x = -sin(ship.aim)*5
 local engine_y = -cos(ship.aim)*5
 make_particle(ship.x+engine_x+3.5, ship.y+engine_y+3.5,0,0)

 update_particles()
end


function draw_system()	
 --printh("draw_system()...")
	cls(curr_system.bgcol)	
  -- stars
 for i=1,#stars do
  local s=stars[i]
  if (s.d>=2.25) pset(s.x,s.y,s.c)
 end

 camera(ship.x-60,ship.y-60)

  -- copy user mem to sprite
 memcpy(0x0,0x4300,0x1000)

close_object=nil
close_object_dist=9999

 -- draw planets
 -- (from user mem)
 
 for i=1,curr_system.num_planets do
  p=curr_system.planets[i]

  -- if planet is within range (e.g. asteroids)
  -- then draw it
  local planet_dist = abs(dist(p.x,p.y,ship.x,ship.y))
  if planet_dist < 128+(astorbit) then
   draw_planet(p,p.x,p.y,p.size)
   -- draw asteroids
   palt(3,0)
   if (curr_system.bgcol>0) palt(1,true)
   for a=1,#p.asteroids do
    local ast=p.asteroids[a]
    spr(ast.spr,p.x+ast.x,p.y+ast.y,1,1,ast.fx,ast.fy)
    --rspr(88,96,p.x+ast.x,p.y+ast.y,t()+rnd(),1,3)
   end
  end
  -- landable?
  if (planet_dist < (p.size*16)+20 and planet_dist<close_object_dist) close_object=p close_object_dist=planet_dist

 end --# planets

 

 -- restore sprites
 reload()
 --reload(0,0,0x1fff)

 -- draw station
 local st=curr_system.station
 pal()
 palt(0,false)
 pal(1,st.col1)
 pal(13,st.col2)
 rspr(0,64,st.x-20,st.y-20,st.rot,6,3) 
 st.rot+=.0025
 pal()
 palt()
 --spr(128,st.x-20,st.y-20,5,5) 

 -- ui
 for i=1,curr_system.num_planets do
  p=curr_system.planets[i]
  -- debug (collision bounds!)
  --circ(p.x,p.y,(p.size*16),8)
  
 if p.mapped then
  print(p.name,
   p.x,  --p.x-flr((#p.name*4)/2)
   p.y-(p.size*16)-16,7)

   -- print("unmapped",
   --  p.x,
   --  p.y-(p.size*16)-8,9)
 end
 if not p.mapped then
  print("unknown",
   p.x,  --p.x-flr((#p.name*4)/2)
   p.y-(p.size*16)-16,7)

  print("unmapped",
   p.x,
   p.y-(p.size*16)-8,9)
 end

 end --# planets

 draw_particles()


	-- reset/lock camera for fixed drawing
	camera()

 -- draw player's ship
 draw_ship(60,60)

 -- -- 
 -- draw_particles()

 -- stars foreground
 for i=1,#stars do
  local s=stars[i]
  if (s.d<2.25) pset(s.x,s.y,s.c)
 end

 -- ui
 draw_ui()

 -- radar
 draw_radar()

 -- fades
 if (landing or takingoff) fade(wfade, fade_table_white, 7, 1)
end

-- will either be ship or person
function update_player()


 if player.in_ship then
  if not ship.landed and not landing then
   -- todo: flight controls
   local speed=.5--.1 --1
   local acc=0.01
   local rotspeed=.0075
    -- fast turn = .01

   if(btn(2)) ship.thrust+=acc
   if(btn(3)) ship.thrust-=acc    
   if(btn(0)) ship.aim-=rotspeed
   if(btn(1)) ship.aim+=rotspeed   

   if(btnp(4) and wfade<0 and warp_count==0) init_galaxy() update_galaxy() curr_mode=1 return

   if(btnp(5) and close_object and warp_count==0) curr_planet=close_object landing=true wfade=0 sfx(50,3)

   -- cap thrust
   ship.thrust=mid(0.25,ship.thrust,1.75)
   -- calculate thrust vector
   ship.dx=-sin(ship.aim*-1)*ship.thrust
   ship.dy=cos(ship.aim*-1)*ship.thrust

   -- update camera pos
   ship.x+=ship.dx
   ship.y+=ship.dy

   -- todo/debug: this needs work when on planet - not finished!
   -- camx+=ship.dx
   -- camy+=ship.dy

  -- ship.dx=ship.thrust
  else
   -- allow take-off or leave ship
  end
 else
  -- on foot
   local speed=1 --constant!   
   local vx,vy=0,0
   local btn_count=0

   if(btn(0)) vx=-speed btn_count+=1
   if(btn(1)) vx=speed btn_count+=1
   if(btn(2)) vy=-speed btn_count+=1
   if(btn(3)) vy=speed btn_count+=1

   if btnp(5) then
    -- check for close object(s).. 
    if close_object then
     -- ship
     if close_object.obj_type==3 then
      -- take-off!
      --printh("takeoff!!!!!")
      takingoff=true wfade=0 sfx(51,3) banner_count=-2

     -- item to collect
     elseif close_object.obj_type==4 or close_object.obj_type==5 then
      local checkpos=(mapx+11).."."..(mapy+11)
      --printh(">>> deading: "..checkpos)
      curr_planet.dead[checkpos]=true
      close_object.dead=true

      -- add to player inventory
      player.inv[close_object.obj_class]+=1--block.obj_quantity
      -- show message
      collect_item=close_object
      collect_amount=1 -- quantity
      collect_timer=1
      -- sfx
      sfx(54,3)
     end
    end 

   end

   -- speed delay
   if (btn_count>0) then 
    speed_delay_count+=1
    if (player.curr_anim!=player_walk_anim) sfx(52,3) printh("walk!!!")
    player.curr_anim=player_walk_anim
   else
    if (player.curr_anim==player_walk_anim) sfx(-1,3) printh("stop!!!")
    player.curr_anim=player_idle_anim
   end
   if (speed_delay_count>speed_delay) then
    speed_delay_count=0
    -- move camera pos
    -- camx+=vx
    -- camy+=vy
    player.x+=vx
    player.y+=vy 
    camx+=vx
    camy+=vy 
    
    -- printh("player pos: "..player.x..","..player.y)
    -- printh("ship pos: "..ship.x..","..ship.y)
    -- printh("cam1 x="..camx..",y="..camy)
   end
--printh("cam1 x="..camx..",y="..camy)
   

   -- check collisions / close objects
   -- reset state
    close_object=nil

   -- ship
   if dist(player.x,player.y,ship.x,ship.y)<10 then
    close_object=ship

   else
    -- item to collect (flower, cargo drop, etc.)
    local block=mdata["11.11"]
    if block.obj_type and not block.dead then
     close_object=block
    end

   end -- close tests

 end
end

function draw_radar()
 local xoff,yoff=50,0
 local px,py=xoff+13,yoff+13

  rectfill(xoff,yoff,xoff+25,yoff+25,5)
  rectfill(xoff+1,yoff+1,xoff+24,yoff+24,0)
  
 -- in space?
 if curr_mode==2 then
  -- draw dist objects first
  clip(xoff+1,yoff+1,24,24)
  for i=1,#curr_system.planets do
   local dx=px+(curr_system.planets[i].x-ship.x)*.1
   local dy=py+(curr_system.planets[i].y-ship.y)*.1
   dx=mid(xoff+1,dx,xoff+24)
   dy=mid(yoff+1,dy,yoff+24)
   circfill(dx,dy,2,13)
  end
  rectfill(xoff+2,yoff+2,xoff+23,yoff+23,1)
  -- station
  local st=curr_system.station
  dx=px+(st.x-ship.x)*.1
  dy=py+(st.y-ship.y)*.1
  dx=mid(xoff,dx,xoff+24)
  dy=mid(yoff,dy,yoff+24)
  fillp(0X5A5A,dx,dy)
  rectfill(dx,dy,dx+1,dy+1,148)
  fillp()

  -- now draw close objects
  for i=1,#curr_system.planets do
   local dx=px+(curr_system.planets[i].x-ship.x)*.1
   local dy=py+(curr_system.planets[i].y-ship.y)*.1
   circfill(dx,dy,2,13)
  end

 -- on land?
 elseif curr_mode==3 then
  -- draw dist objects first
  clip(xoff+1,yoff+1,24,24)
  rectfill(xoff+2,yoff+2,xoff+23,yoff+23,3)
  -- ship
  dx=px+(ship.x-player.x)*.1
  dy=py+(ship.y-player.y)*.1
  dx=mid(xoff,dx,xoff+24)
  dy=mid(yoff,dy,yoff+24)
  fillp(0X5A5A,dx,dy)
  rectfill(dx,dy,dx+1,dy+1,135)
  fillp()


 end
 


  -- player
  pset(xoff+13,yoff+13,7)

 clip()
end


function draw_ship(x,y)
 pal()
 palt(0,false)
 --printh("a:"..ship.aim)
 rspr(88+8*ship.skin,120,x,y,ship.aim,1,3)
 pal()
 palt()
end


collect_item=nil
collect_amount=0
collect_timer=0

function draw_ui()

 -- todo: draw_healthbar and make real
 palt(3,true)
 -- rectfill(2,2,40,3,1)
 -- rectfill(2,2,35,3,7)
 -- spr(224,2,5)

 -- middle/in-viewport stuff
 if close_object!=nil then
  -- planet?
  if close_object.obj_type==1 then
   outline_text("❎ to land",
    60-10,
    60+12, 7)
  -- ship?
  elseif close_object.obj_type==3 then
   outline_text("❎ to take-off",
    60-20,
    60+5, 7)
  -- collectable?
  elseif close_object.obj_type==4 or close_object.obj_type==5 then
   outline_text("❎ to pick-up",
    60-20,
    60+5, 7)
  end
 end

 -- shared ui sections?

 -- collected items
 if collect_item then
  rectfill(38,31,41,34,collect_item.obj_col1)
  rectfill(39,32,40,33,collect_item.obj_col2)
  outline_text(smallcaps(collect_item.name.." x"..collect_amount),44,30,7)
  collect_timer-=.01
  if (collect_timer<=0) collect_item=nil
 end

 if banner_count>=0 then
  rectfill(24,80,104,98,0)
  print(curr_planet.name, 48,82, 7)
  line(28,89,100,89,5)
  print(curr_system.name..smallcaps(" system"), 34,91, 7)

  banner_count+=.1
  if (banner_count>20) banner_count=-2
 end


 -- todo: show health and actual weapon
 
 if player.in_ship then
  -- top portion
  --print("pos="..flr(ship.x)..","..flr(ship.y),50,30,8)

  -- debug (removed until canon fire done)
  -- rectfill(89,2,125,3,1)
  -- rectfill(89,2,125,3,7)
  -- print("100%",104,6,7,1)
  -- spr(239,120,5)
  -- print(smallcaps("photon"),103,12)

  if not ship.landed then
   print(flr(ship.thrust*100).."\85/\83",2,121,7)
  end

 else -- on foot

  -- top portion
  rectfill(89,2,125,3,1)
  rectfill(89,2,125,3,7)
  outline_text("99%",105,6,7,1)
  spr(238,118,5)
  outline_text(smallcaps("mining"),103,12,7,1)
  
  -- bottom portion
  spr(242,1,103)
  rectfill(9,106,40,107,1)
  rectfill(9,106,40,107,7)
  outline_text(curr_planet.name,2,114,7,1)
  outline_text(curr_planet.temp.." f",2,121,7,1)

  spr(244,110,119)
  spr(245,119,119)
 end
 
 palt()
end

function create_stars()
 stars={}
	for i=1,50 do
		local s={}
		s.x=flr(rnd(128))
		s.y=flr(rnd(128))
		s.d=rnd(10)
  s.c=s.d+5 -- stranger things!
  add(stars,s)
	end
end

function update_star(s, dx, dy)
 -- move star based on depth
 s.x-=dx/s.d*5
 s.y-=dy/s.d*5
 		
 -- wrap star, if needed
 if (s.x<0 or s.x>128) then
	 	s.x=s.x<0 and 128 or 0
	 	s.y=rnd(128)
	elseif (s.y<0 or s.y>128) then
		s.x=rnd(128)
		s.y=s.y<0 and 128 or 0
	end
end

function make_particle(startx,starty,dx,dy,cols,life_time,max_size,min_size)
 local p = {
   --the location of the particle
   x=startx,
   y=starty,
   --what percentage 'dead'is the particle
   t = 0,
   --how long before the particle fades
   life_time=20+rnd(10),
   --how big is the particle,
   --and how large will it grow?
   size = 1,
   max_size = 1+rnd(3),
   min_size = 1+rnd(3),
   
   --'delta x/y' is the movement speed,
   --or the change per update in position
   --randomizing it gives variety to particles
   dy = dy,
   dx = dx,
   -- dy = rnd(0.7) * -1,
   -- dx = rnd(0.4) - 0.2,
   
   --'ddy' is a kind of acceleration
   --increasing speed each step
   --this makes the particle seem to float
   ddy = -0.05,
   --what color is the particle
   col = 7
 }
 --after making the particle, add it to the list 'smoke'   
 add(ship.trail,p)
end

function update_particles()
  --perform actions on every particle
  for p in all(ship.trail) do
    --move the smoke
    p.y += p.dy
    p.x += p.dx
    --p.dy+= p.ddy
    --increase the smoke's life counter
    --so that it lives the correct number of steps
    p.t += 1/p.life_time
    --grow the smoke particle over time
    --(but not smaller than its starting size)
    p.size *=.99
    --p.size = max(p.size, p.max_size * p.t )
    
    --make fading smoke particles a darker color
    --gives the impression of fading
    --change color if over 70% of time passed
    if p.t > 0.1  then
      p.col = 12
    end
    if p.t > 0.7 then
      p.col = 1
    end
    --if the particle has expired,
    --remove it from the 'smoke' list
    if p.t > 1 then
      del(ship.trail,p)
    end
  end
end

function draw_particles()
  for i=1,#ship.trail do
    local p=ship.trail[i]
    --draw a circle to be the smoke
    --replace this with whatever you want
    --your smoke to look like
    circfill(p.x, p.y, p.size, p.col)
  end
end

function draw_planet(p,x,y,scale)
 pal()
 palt(0,false)
 palt(15,true)

   local startx=((p.num-1)%4)*32
 sspr(
  startx,
  flr(p.num/5)*32,
  32,32,
  x-(15*scale),y-(16*scale),
  32*scale,32*scale)
end

function create_planet(seed,num)
 printh(">>> in create_planet()")
 local p={
  obj_type=1,
  seed=rnd(32000),
  num=num,
  name=getsystemname().." "..flr(rnd(8))+1,
  size=rnd(.75)+1,
  x=rnd(sector_size)-sector_size/2,
  y=rnd(sector_size)-sector_size/2,
  res_nums={},
  dead={},
  temp=flr(rnd(200)).."."..flr(rnd(9))+1,
  mapped=false
 }
 -- gen palette
	p.pal={}
 --printh("planet pal:")
 for i=0,14 do
  p.pal[i]=flr(rnd(14)+1)
  --printh(" > "..p.pal[i])
 end
 -- generate planet texture
 gen_texture(seed,p)
 -- render planet once
 render_sphere(
   ((num-1)%4)*32,
   -1 + (flr(num/5)*32),
   1)
 -- generate asteroids
 p.asteroids={}
 local astcount=100
 for i=1,astorbit do
  local a=rnd(1)
  local ast={
   x=(rnd(astorbit/2)+astorbit)*cos(a),
   y=(rnd(astorbit/2)+astorbit)*sin(a),
   spr=204+flr(rnd(4)),
   fx=flr(rnd(2))==0,
   fy=flr(rnd(2))==0
  }
  add(p.asteroids,ast)
 end
 -- generate resources
 for i=1,flr(rnd(4)) do
  local num=flr(rnd(#res)+1)
  add(p.res_nums,num)
  printh("  > res = "..res[num][3])
 end

 return p
end

function gen_texture(seed,p)
 -- set seed
	os2d_noise(seed)
	
	local size=32
	-- fill spr ram with samples
	for y=0,size do
		for x=0,size*4 do
			local c
			-- base noise is strongest
			c =os2d_eval(x/8,y/4)
			--c =os2d_eval(x/32,y/32)

	--[[		
			-- next is weaker
			c+=os2d_eval(x/16,y/16)/2

			-- and so on
			c+=os2d_eval(x/ 8,y/ 8)/4

			-- and so on
			c+=os2d_eval(x/ 4,y/ 4)/8

			-- and so on
			c+=os2d_eval(x/ 2,y/ 2)/16

]]
			-- convert -0.2..+1 to 14 cols
			-- (sea level at -0.2)
			c=mid(0,(c+0.2)/1.2*14,13)

   sset(x,y,p.pal[flr(c)])
		end
	end
end


fade_table_white={
 {1,13,6},
 {5,13,6},
 {13,13,6},
 {3,13,6},
 {4,14,15},
 {13,6,6},
 {6,7,7},
 {7,7,7},
 {8,14,15},
 {10,15,15},
 {10,15,15},
 {11,6,6},
 {12,6,6},
 {13,6,6},
 {14,15,7},
 {15,7,7}
}

fade_table_black={
 {0,0,0},
 {1,0,0},
 {2,1,0},
 {3,1,0},
 {2,2,0},
 {5,1,0},
 {13,5,1},
 {6,13,1},
 {8,2,0},
 {4,4,0},
 {9,4,5},
 {3,3,0},
 {12,1,1},
 {5,1,1},
 {13,2,1},
 {13,5,1}
}


function fade(i,fade_table,target_col,p) -- p=0=draw palette
 for c=0,15 do
  if flr(i+1)>=4 then
   pal(c,target_col,p)
  elseif flr(i+1)<0 then
   -- do nothing
  else
   pal(c,fade_table[c+1][flr(i+1)],p)
  end
 end
end

-->8
-- planet surface level

--------------------------------
-- init phase
--------------------------------
mdata={}
--mdead={} -- the used/dead list
speed_delay=2 -- walk=2,run=1,fly=0 
speed_delay_count=0
res_types={"isotope","silicate","neutral","exotic"}
res={
 --{1,2,"carbon","c",1,.9,7}, --mining/killing animals
 {10,9,"sodium","na",4,.1,41,175}, --1
 {8,10,"oxygen","c",1,.9,7,174},
 {4,9,"marrow bulb","mb",4,.2,41,171}, --caves
 {3,1,"cactus flesh","cc",3,.2,28,170},--on desert worlds
 {3,10,"gamma root","gr",4,16,1.1,174}, --radioactive worlds
 {11,3,"fungal mould","fm",3,.2,16,171},--on toxic worlds
 {12,1,"frost crystal","fc",3,.2,12,175}, --on frozen worlds
 {10,9,"solanium","so",3,.2,70,173}, --on hot worlds
 {7,7,"kelp sac","ke",4,.2,41,174}, --underwater
 {12,7,"star bulb","sb",3,.2,32,173},
 --col1,col2,name,abbrev,group,rarity,value,sprite
-- {6,5,"platinum","pt",2,.5,55}, --mining
-- {9,9,"copper","cu",2,.5,110,172},
-- {8,8,"coprite","cr",3,.2,30}, --feeding animals
-- {3,11,"emeril","em",3,.2,275},
-- {9,10,"gold","au",3,.2,220},
 --{14,2,"mordite","mo",3,.2,40}, --killing animals
-- {2,13,"pugneum","pg",3,.2,138},
}
-- other object classes
-- 20= warp cell


function init_surface()

 -- ####################################
 -- debug
 if curr_system==nil then
  srand(4) --4
  pal()
  palt()
  cls(15)
  curr_system={
   seed=rnd(32000),--0,
   bgcol=1,
   num_planets=8,
   planets={}
  }
  for i=1,curr_system.num_planets do
   curr_planet=create_planet(curr_system.seed,2)
   add(curr_system.planets,curr_planet)
  end
  -- copy screen to user memory
  memcpy(0x4300,0x6000,0x1000)
  -- reset sprites
  reload()

  ship.landed=true
  player.in_ship=false
 end
 -- ####################################




	-- noise params
	_seed=0

	camx=16
 camy=16
 -- map view pos
	mapx=-1--80--10
	mapy=21--90--11

 -- wave ripples
 wave_frame=0
 --wave_cols={7,12,12}
 --wave_delay=10
	
	-- generate initial view
 os2d_noise(curr_planet.seed)--_seed)
	gen_map(mapx,mapy,22,22,1,1)

 -- ----------------------------------
 -- recolour sprites to planet pal
 pal()
 palt()
 cls()
 water_col=curr_planet.pal[0]
 deep_water=fade_table_black[water_col+1][2]
 beach_col=curr_planet.pal[2]
 grass_col=curr_planet.pal[3]
 trees_col=curr_planet.pal[6]
 trees_floor_col=curr_planet.pal[4]
 rock_col=curr_planet.pal[11]

 -- beach (recolor is in update due to anim)
 spr(1,8,0,15,1)

 -- grass
 pal(3,grass_col) 
 pal(11,fade_table_white[grass_col+1][2]) 
 spr(17,8,8,15,1)
 pal()
 -- trees
 pal(5,trees_floor_col)
 pal(11,trees_col)
 pal(3,fade_table_black[trees_col+1][2]) 
 spr(33,8,16,15,1)
 pal()
 -- rock
 pal(6,rock_col)
 pal(7,fade_table_white[rock_col+1][2])
 pal(13,fade_table_black[rock_col+1][2])
 pal(1,fade_table_black[fade_table_black[rock_col+1][2]+1][2])
 spr(49,8,24,15,1)
 pal()
 -- water
 pal(12,water_col)
 palt(0,false)
 pal(0,deep_water)
 spr(65,8,32,15,1)
 pal()

 -- copy screen (5 rows of sprites) to sprite memory
 memcpy(0x0000,0x6000,0x0a00)
 
 -- reset sprites
 --reload()

 -- set player pos
 player.x=mapx*8+70
 player.y=mapy*8+70
 -- put player ship next to them
 ship.x=mapx*8+60
 ship.y=mapy*8+60
 ship.aim=0

 -- mark as mapped
 curr_planet.mapped=true

 -- play music
 srand(curr_planet.seed)
 local song_num=flr(rnd(#playlist))+1
 --printh("song_num:"..song_num)
 --if (song_num!=now_playing) music(playlist[song_num]) now_playing=song_num
end

--------------------------------
-- update phase
--------------------------------

function update_surface()
	 -- landing/takeoff
	if landing then
  wfade-=.25
  if wfade <= 0 then
   landing=false
   wfade=-2
   -- default to landed and out of ship
   ship.landed=true
   player.in_ship=false

   -- show planet name
   banner_count=0
   sfx(59,3)
  end
 elseif takingoff then
  wfade+=.25
  if (wfade >= 5) then
   curr_mode=2
  -- default to flying and out of ship
   ship.landed=false
   player.in_ship=true
   -- pos ship at planet
   ship.x=curr_planet.x
   ship.y=curr_planet.y
   init_system()
  end
 end
	
 -- either ship or person
 update_player()

 -- update player anim
 animate(player)


	-- check for empty map lines

 -- left edge =========================
	if camx<12 then --(16-4)
	 -- need to shift map
	 for y=1,22 do
 		for x=22,1,-1 do
 		 local block=mdata[(x-1).."."..y]
 		 mdata[x.."."..y]=block
 		end
 	end
	 -- generate new lines
	 mapx-=1
	 gen_map(mapx,mapy,0,22,1,1)
	 -- and reposition camera
	 camx=20-(12-camx)

 -- top edge =========================
	elseif camy<12 then --(16-4)
	 -- need to shift map
	 for x=1,22 do
 		for y=22,1,-1 do
 		 local block=mdata[x.."."..(y-1)]
 		 mdata[x.."."..y]=block
 		end
 	end
	 -- generate new lines
	 mapy-=1
	 gen_map(mapx,mapy,22,0,1,1)
	 -- and reposition camera
	 camy=20-(12-camy)

 -- right edge =========================
	elseif camx>=20 then  --(16+4)
	 -- need to shift map
	 for y=1,22 do
 		for x=1,22 do
 		 local block=mdata[(x+1).."."..y]
 		 mdata[x.."."..y]=block
 		end
 	end
	 -- generate new lines
	 mapx+=1
	 gen_map(mapx+21,mapy,0,22,22,0) --target map pos
	 -- and reposition camera
	 camx=12+(20-camx)--+speed

 -- bottom edge =========================
	elseif camy>=20 then --(16+4)
	 -- need to shift map
	 for x=1,22 do
 		for y=1,22 do
 		 local block=mdata[x.."."..(y+1)]
 		 mdata[x.."."..y]=block
 		end
 	end
	 -- generate new lines
	 mapy+=1
	 gen_map(mapx,mapy+21,22,0,1,22) --target map pos

	 -- and reposition camera
	 camy=12+(20-camy)--+speed
	end

 -- debug
 --printh(tostr(player.inv[20]))
end

function gen_map(mx,my,mw,mh,ox,oy)
 --printh("gen_map("..mx..","..my..","..mw..","..mh..","..ox..","..oy..")")
 
 -- set map data with samples
	for y=oy,oy+mh do
		for x=ox,ox+mw do
			local c
			
			local _x=mx-ox+x
			local _y=my-oy+y
			-- v1(orig - slower)
		--[[
			c =os2d_eval(_x/32,_y/32)
			c+=os2d_eval(_x/16,_y/16)/2
			c+=os2d_eval(_x/ 8,_y/ 8)/4
			c+=os2d_eval(_x/ 4,_y/ 4)/8
			c+=os2d_eval(_x/ 2,_y/ 2)/16
			]]
			
			-- v2(faster)
			--[[
			c =os2d_eval(x/1024,y/1024)
			c+=os2d_eval(x/64,y/64)/2
			c+=os2d_eval(x/ 8,y/ 8)/4
			c+=os2d_eval(x/ 4,y/ 4)/8
			]]
			
			-- v3 (faster and looks good)
			--[[
   c =os2d_eval(_x/64,_y/64)
			c+=os2d_eval(_x/32,_y/32)/4
			c+=os2d_eval(_x/ 8,_y/ 8)/8
   ]]
   
   -- v4 (smaller scale - nice landscape, lots of water)
   --printh(">>> gen point <<<")
			-- c =os2d_eval(_x/32,_y/32)
			-- c+=os2d_eval(_x/8,_y/8)/4
			-- --c+=os2d_eval(_x/4,_y/4)/8
			
   -- v5 (bigger land mass, ponds and lakes)
   c =os2d_eval(_x/32,_y/32)
			c+=os2d_eval(_x/16,_y/16)/2
			--c+=os2d_eval(_x/ 8,_y/ 8)/4

			mdata[x.."."..y]={
			 noise=c,
		  col=mid(0,(c+0.2)/1.2*14,13),
    -- x=_x,
    -- y=_y,
    -- each block gets its own random seed
				seed=tonum(mapx+x).."."..(mapy+y) --x.."."..y)
			}

		end
	end

 -- calc (incremental) marching for new blocks
 local sx = mid(2,ox,21)
 local sy = mid(2,oy,21)
 local tx = (mw>2) and ox+mw-1 or sx
 local ty = (mh>2) and oy+mh-1 or sy

 for y=sy,ty do
  for x=sx,tx do

   local block=mdata[x.."."..y]
   block.march_sea = marching_code(x,y,-.75)
   block.march_low = marching_code(x,y,-0.5)
   block.march_mid = marching_code(x,y,-0.25)
   block.march_hi = marching_code(x,y,0.5)
   block.march_top = marching_code(x,y,0.9)

   -- now gen other object types:
   --  1=planet, 2=space station, 3=ship, 4=flower, 
   --  5=collectable, 6=mineable, 7=base?
   -- (each block has own seed)
   srand(block.seed)

   -- static objects...

   -- only if planet has resources
   if #curr_planet.res_nums > 0 then
    if block.noise>.65 and block.noise<.66 then
     -- plant
     block.obj_type=4
     block.obj_class=curr_planet.res_nums[flr(rnd(#curr_planet.res_nums)+1)] --flr(rnd(5)+1)    
     --printh("class="..block.obj_class)
     block.obj_col1=res[block.obj_class][1]
     block.obj_col2=res[block.obj_class][2]
     block.name=res[block.obj_class][3]
    end

    -- other properties    

    -- only used if a "full" tile
    -- (removed for now - kinda slow, not much diff)
    -- block.flipx=flr(rnd(2))==0
    -- block.flipy=flr(rnd(2))==0
   end

   -- collectable (container?)
   srand(block.seed)

   -->> rnd issue!
   if block.noise>-.06 and block.noise<-.05 and rnd()<.1 then
    block.obj_type=5 --5=container
    block.obj_class=20 -- 20=warp cell
    block.obj_col1=11
    block.obj_col2=7
    block.name="warp cell"
   end

   -- is block "dead/used"?
   --printh("dead type: "..type(curr_planet.dead["7.36"]))
   local checkpos=(mapx+x).."."..(mapy+y)
   --printh(">>> cheaking for dead: "..checkpos)
   --if (checkpos=="7.36") printh("checking...7.36")
   if (curr_planet.dead[checkpos]!=nil) block.dead=true 
  end
 end


 
end


--------------------------------
-- draw phase
--------------------------------

function draw_surface()
 pal()
	--cls(1) --water
 cls(deep_water)
	--cls(12)
	camera(camx,camy)
	
  -- wave cols  
  
  wave_cols={7,water_col,water_col}
  --if (time()%1==0) then
    wave_frame = flr(sin(t()/10)*1.5+1)
    if (wave_frame==0) wave_cols={7,water_col,water_col}
    if (wave_frame==1) wave_cols={beach_col,7,water_col}
    if (wave_frame==2) wave_cols={beach_col,beach_col,7}
 --end
 
 for y=2,21 do
		for x=2,21 do

			local block=mdata[x.."."..y]
			local c3col=block.col
			local c4=flr(c3col)

   local dx=x*8-16
   local dy=y*8-16

   -- -- randomise full blocks
   -- fx,fy=false,false
   -- if block.march_top==15 or block.march_hi==15 or block.march_mid==15 or block.march_low==15 or block.march_sea==15) then
   --  fx=rnd(
   -- end

   -- don't draw if hidden by layer above
			if(block.march_top<15 and block.march_hi<15 and block.march_mid<15 and block.march_low<15 and block.march_sea!=0) then spr(block.march_sea+64,dx,dy) end
   pal()

   -- wave palette cycling
   pal(1,wave_cols[1])
   pal(2,wave_cols[2])
   pal(3,wave_cols[3])

   pal(15,beach_col)   
   pal(7,fade_table_white[beach_col+1][2])
   --pal(7,beach_col-1)
   if(block.march_top<15 and block.march_hi<15 and block.march_mid<15 and block.march_low!=0) then spr(block.march_low,dx,dy) end--,1,1,block.march_low==15 and block.flipx or false, block.march_low==15 and block.flipy or false)
			pal()
   
   if(block.march_top<15 and block.march_hi<15 and block.march_mid!=0) then spr(block.march_mid+16,dx,dy) end--,1,1,block.march_mid==15 and block.flipx or false, block.march_mid==15 and block.flipy or false)

   if(block.march_top<15 and block.march_hi!=0) then spr(block.march_hi+32,dx,dy) end
  
   if(block.march_top!=0) then spr(block.march_top+48,dx,dy) end
   
		 
   -- todo: draw other fixed objects (grass, trees, bases, etc..)



   -- each block gets its own random seed
   srand(block.seed)
   
   palt(0,false)
   palt(3,true)

   -- printh("map: "..mapx..","..mapy)
   -- local checkpos=(mapx+x).."."..(mapy+y)
   -- printh("checkpos =  "..checkpos)

   -- plants/minerals
   if block.obj_type==4 then
    pal(8,block.obj_col1)
    pal(10,block.obj_col2)
    -- alive?
    if (not block.dead) then
     local checkpos=(mapx+x).."."..(mapy+y)
     --printh("drawpos =  "..checkpos)
     spr(res[block.obj_class][8],dx,dy)
    else
     spr(res[block.obj_class][8]+16,dx,dy)
    end
    pal()

   -- containers
   elseif block.obj_type==5 then
    palt(0,false)
    palt(3,true)
    -- alive?
    if (not block.dead) then
     spr(143,dx,dy)
    else
     spr(159,dx,dy)
    end
    pal()

   end


		end -- y loop
		 
	
 end

	
 -- todo: draw other fixed objects (grass, trees, bases, etc..)

draw_ship(ship.x-(mapx*8),ship.y-(mapy*8))

--printh("cam="..camx..","..camy)


	-- reset cam for "static" things
	camera()

 -- draw player
	pal()
	palt(3,true)
 local sprnum = player.curr_anim[player.anim_pos]	
 spr(sprnum,59,57)
 --debug
 --pset(60,60,8)
 
 draw_ui()
 
 -- --print("map x="..mapx..",y="..mapy,40,2,7)
 -- palt(3,true)
 -- rectfill(2,2,40,3,1)
 -- rectfill(2,2,35,3,7)
 -- spr(224,2,5)
 
 -- rectfill(89,2,125,3,1)
 -- rectfill(89,2,125,3,7)
 -- outline_text("47%",105,6,7)
 -- spr(238,118,5)
 -- outline_text(smallcaps("mining"),103,12,7,1)
 
 
 -- -- bottom portion
 -- spr(225,1,103)
 -- rectfill(9,106,40,107,1)
 -- rectfill(9,106,35,107,7)
 -- outline_text(smallcaps("veandso 7"),2,114,7,1)
 -- outline_text("149.7 f",2,121,7,1)

 -- spr(244,110,119)
 -- spr(245,119,119)

 draw_radar()
 
 --  -- fades
 if (landing or takingoff) fade(wfade, fade_table_white, 7, 1)
 
 -- debug testing
 -- memcpy(0x0,0x4300,0x0fff)
 -- draw_planet(curr_planet,64,16,1)
 -- reload()

end

-->8
-- ui system

-->8
-- planet objects + life
-->8
-- helper code

function animate(obj)
 -- animate the object
 -- (update frames, looping as req)
 obj.tmr += 1
		if obj.tmr > obj.frame_delay then
			obj.tmr = 1
			obj.anim_pos += 1
			if obj.anim_pos > #obj.curr_anim then obj.anim_pos=1 end
		end
end

function outline_text(str,x,y,c0,c1)
	print(str, x+1, y, c1)
 print(str, x+1, y+1, c1)
 print(str, x, y+1, c1)
 print(str,x,y,c0)
end

-->8
-- public code snippets

-- marching squares
-- by frederic souchu (freds72)
function hk(cq,cr,hl)
return mdata[cq.."."..cr].noise>hl and 1 or 0
end
function marching_code(cl,fy,hl)
return
hk(cl,fy,hl)+
shl(hk(cl,fy+1,hl),1)+
shl(hk(cl+1,fy,hl),2)+
shl(hk(cl+1,fy+1,hl),3)
end

-- opensimplex noise
-- by felice enellen
-- https://www.lexaloffle.com/bbs/?tid=31201
local hm=-0.211324865405187
local hn=0.366025403784439
local ho=hn+1
local hp=hn*2
local hq=hp+1
local hr=hp+2
local hs=47
local ht={}
local hu=
{[0]=
5,2,2,5,
-5,2,-2,5,
5,-2,2,-5,
-5,-2,-2,-5,
}
function os2d_noise(cn)
local hv={}
for cl=0,255 do
hv[cl]=cl
ht[cl]=0
end
srand(cn)
for cl=255,0,-1 do
local hw=flr(rnd(cl+1))
ht[cl]=hv[hw]
hv[hw]=hv[cl]
end
end
function os2d_eval(m,n)
local hx=(m+n)*hm
local hy=m+hx
local hz=n+hx
local ia=flr(hy)
local ib=flr(hz)
local ic=(ia+ib)*hn
local id=ia+ic
local ie=ib+ic
local ig=hy-ia
local ih=hz-ib
local ii=ig+ih
local gv=m-id
local gw=n-ie
local ij,ik,il,im
local io=0
local ip=gv-ho
local iq=gw-hn
local ir=2-ip*ip-iq*iq
if ir>0 then
ir*=ir
local cl=band(ht[(ht[(ia+1)%256]+ib)%256],0x0e)
io+=ir*ir*(hu[cl]*ip+hu[cl+1]*iq)
end
local is=gv-hn
local it=gw-ho
local iu=2-is*is-it*it
if iu>0 then
iu*=iu
local cl=band(ht[(ht[ia%256]+ib+1)%256],0x0e)
io+=iu*iu*(hu[cl]*is+hu[cl+1]*it)
end
if ii<=1 then
local iv=1-ii
if iv>ig or iv>ih then
if ig>ih then
il=ia+1
im=ib-1
ij=gv-1
ik=gw+1
else
il=ia-1
im=ib+1
ij=gv+1
ik=gw-1
end
else
il=ia+1
im=ib+1
ij=gv-hq
ik=gw-hq
end
else
local iv=2-ii
if iv<ig or iv<ih then
if ig>ih then
il=ia+2
im=ib
ij=gv-hr
ik=gw-hp
else
il=ia
im=ib+2
ij=gv-hp
ik=gw-hr
end
else
ij=gv
ik=gw
il=ia
im=ib
end
ia+=1
ib+=1
gv=gv-hq
gw=gw-hq
end
local iw=2-gv*gv-gw*gw
if iw>0 then
iw*=iw
local cl=band(ht[(ht[ia%256]+ib)%256],0x0e)
io+=iw*iw*(hu[cl]*gv+hu[cl+1]*gw)
end
local ix=2-ij*ij-ik*ik
if ix>0 then
ix*=ix
local cl=band(ht[(ht[il%256]+im)%256],0x0e)
io+=ix*ix*(hu[cl]*ij+hu[cl+1]*ik)
end
return io/hs
end

-- rotate sprite
-- by freds72
-- https://www.lexaloffle.com/bbs/?pid=52525#p52541
local rspr_clear_col=0

function rspr(sx,sy,x,y,a,w,trans)
	local ca,sa=cos(a),sin(a)
	local srcx,srcy,addr,pixel_pair
	local ddx0,ddy0=ca,sa
	local mask=shl(0xfff8,(w-1))
	w*=4
	ca*=w-0.5
	sa*=w-0.5
	local dx0,dy0=sa-ca+w,-ca-sa+w
	w=2*w-1
	for ix=0,w do
		srcx,srcy=dx0,dy0
		for iy=0,w do
			if band(bor(srcx,srcy),mask)==0 then
				local c=sget(sx+srcx,sy+srcy)
				if (c!=trans) pset(x+ix,y+iy,c)
			--else
				--pset(x+ix,y+iy,rspr_clear_col)
			end
			srcx-=ddy0
			srcy+=ddx0
		end
		dx0+=ddx0
		dy0+=ddy0
	end
end

--
-- local fill pattern
-- by felice + makke
-- https://www.lexaloffle.com/bbs/?tid=30518
-- 
_fillp_xmask_lo={[0]=0xffff,0x7777,0x3333,0x1111}
_fillp_xmask_hi={[0]=0x0000,0x8888,0xcccc,0xeeee}
_fillp_original=fillp

function fillp(p,x,y)
    if y then
        x=band(x,3)
        local p16=flr(p)
        local p32=rotr(p16+lshr(p16,16),band(y,3)*4+x)
        p+=flr(band(p32,_fillp_xmask_lo[x])+band(rotl(p32,4),_fillp_xmask_hi[x]))-p16
    end
    return _fillp_original(p)
end


-- by felice
function smallcaps(s)
	local d=""
	local l,c,t=false,false
	for i=1,#s do
		local a=sub(s,i,i)
		if a=="^" then
			if c then d=d..a end
				c=not c
			elseif a=="~" then
				if t then d=d..a end
				t,l=not t,not l
			else 
				if c==l and a>="a" and a<="z" then
				for j=1,26 do
					if a==sub("abcdefghijklmnopqrstuvwxyz",j,j) then
						a=sub("\65\66\67\68\69\70\71\72\73\74\75\76\77\78\79\80\81\82\83\84\85\86\87\88\89\90\91\92",j,j)
					break
					end
				end
			end
			d=d..a
			c,t=false,false
		end
	end
	return d
end

-- modified ver of "pico world"
-- by gamax92
-- https://www.lexaloffle.com/bbs/?tid=3140

local mtbl={}
for i=1,32 do
	mtbl[i]={flr(-sqrt(-sin(i/66))*16+64)}
	mtbl[i][2]=(64-mtbl[i][1])*2
end

local cs={}
for i=0,15 do
	cs[i]={(cos(0.5+0.5/16*i)+1)/2}
	cs[i][2]=(cos(0.5+0.5/16*(i+1))+1)/2-cs[i][1]
end
local function ceil(x)
	return -flr(-x)
end

function render_sphere(dx,dy,scale)
 scale=1
	for i=1,32 do
		local a,b=mtbl[i][1],mtbl[i][2]
		pal()
		local lw=ceil(b*cs[15][2])
		for j=15,0,-1 do
		 pal()
   if (j>9) fade(flr(j)/4-1, fade_table_black, 0, 0)
			if (j<15) lw=flr(a+b*cs[j+1][1])-flr(a+b*cs[j][1])

   sspr(j*7,i-1,
         7,2,
          flr(a+b*cs[j][1])*scale-48+dx,
          i*scale+dy,
         lw*scale,scale)
  end
  
	end
end
__gfx__
00000000f7fff12333000000fff712300321ff7fff7fff7f3217ffffffffffff00000033fff7123333333333ffff71233217ffffffffffff3321ffffffffffff
00000000fff7123023330000f7fff13003217fffffffffff33217ffffff7ffff00003322f7fff12321221212ffffff1233217ffffff7ffff327fffffffffffff
00700700fff1233012233000fff7123003321f7fffffffff33217ff7ffffffff00032211fff712331f1171f1fffff71133217ff7ffffffff11fff7ffffff7fff
00077000f712330071123300fffff13000322117f7fff7f73217fffffffffff70032217ffffff1237f7fff7ffffffff73217ffff7ffffff77fffffffffffffff
0007700011233000ff712330ffff1230003332211f1711f133217ffffffff7f103221fffffff1233ffffffffff7fffff33217fff117fffffffffffffffffffff
0070070022330000ffff1233fff71230000033322121221233217ffff7ffff1203217ff7fff71233ffffffffffffffff33217fff211fffffffff7fffff7fff7f
0000000033000000f7ff7123f7fff12300000033323233233217fff7fffff712321ffffff7fff123f7fff7fffffff7ff3217fff73217fffff7ffffffffffffff
0000000000000000fffff123ffff7123000000003333333332117fffffff71233217ff7fffff7123fffffffffff7ffff33217fff0321ffffffffffffffffffff
000000003b30000000000000333000000000033333333b3300003333333333b30000000033300000000000003303000000000333333333330000303333333333
0000000033000000000000003b330000000033b3330333330000303333b3333300000000333300000000000033330000000033b3333b33330000333333333333
00000000b0300000000000003330000000000303033330030000003b3333b3300000000033b0000000300000333303000003033333333333003033333333b333
0000000000000000000000003330300000000000003003030003033333333330000000003330300000003000333333000000033b3030333b0030333333333333
00000000000000000300000033b030000000000000000300000333333b33300000000303333030003030300333b3330300003b330033333330333b3333333333
00000000000000003b30000033333000000000000000000000033b33333030300000003b3b333000333033303333333300003333003033333333333333b333b3
0000000000000000330000003b30300000000000000000000003033b3330300000000333333030003333333033333b33000303b3000033333b33b33333333333
000000000000000033b300003330000000000000000000000000333333300000000033b33330000033333333333b333300003333000030333333333333333333
000000005b550000000000005b550000000555b55b5555550005b5555555b550000000005b550000000000005b5000000000055555b5555500000055555515b5
00000000b3b5000000000000b3b5000000055b3bb3b55b55005b3b55555b3b5000000000b3b5000000000000b3b50000000005b55b3b5555000005b55b555b3b
00000000333500005500000033350000000053333335b3b50053335555533350000000553335000000000b003335550000005b3b533355b500505b3bb3b55333
00000000545000005b50000054b550000000054554553335000545b55b554500000005b554b550005b55b3b054555b500000533305455b3b05b5533333355545
0000000051500000b3b500005b3b5000000005155155545000051b3bb3b5150000005b3b5b3b5000b3b533355155b3b500005545051553335b3b55455455b515
000000005500000033350000533350000000055505555150000053333335500000005333533350003335545555553335000005150050554553335515515b3b55
00000000000000005455000055450000000000050000555000005545545500000005554555455000545551555555545500000555000005155545555555533355
00000000000000005155000055150000000000000000000000005515515000000055551555150000515555555555515500000555000000555515555555554555
0000000066d00000000000006667d00000000d66666666660000d66666666666000000006667d000000000006667d0000000d6666666666600dd766666666666
000000006d100000000000006667d000000001d6666666660000d66666666666000000006667d0000000000066667d000000d666666666660d77666666666666
00000000d1000000000000006667d0000000001d666666660000d66666666666000000006667d00000000000666667d00000d66666666666d766666666666666
0000000010000000000000006667d00000000001dddddddd0000d66666666666000000006667d000dddddddd6666667d0000d666666666667666666666666666
0000000000000000dd0000006667d00000000000111111110000d6666666666d0000000d6667d00077777777666666670000d666d66666666666666666666666
000000000000000077d000006667d00000000000000000000000d666666666d1000000d76667d00066666666666666660000d6661d6666666666666666666666
0000000000000000667d00006667d00000000000000000000000d66666666dd000000d766667d00066666666666666660000d66611d666666666666666666666
0000000000000000667d00006667d00000000000000000000000d6666666d1100000d7666667d00066666666666666660000d666011d66666666666666666666
00000000cccc000000000000cc00000000cccccccccccccc000ccccccccccccc00000000cccccc0000000000cccccc000c0ccccccc0ccccc00000ccccccccccc
00000000cccccc0000000000ccc0000000000cc0cccccccc0ccccccccccccc0c00000000c0cc00000cc0c000cccc00000000cccccccc00ccc0cccc0ccccccccc
00000000c0c0000000000000ccccc00000c0ccccc0cc000c00c0cccccccccccc00000000ccccccc000000000cccccc0c00ccc0cc00cccccc000ccccccccccccc
00000000ccccc0c0000000000ccc000000000000ccccccccccccccccccc00c00000cc000ccc0c000cccccccccc00c000000cccccc000cccc0ccccccccccccccc
0000000000000000cccc0000cccccc00000000000000000000ccc00cccccccc0000000cccccccc00c0cc000ccccccccc0ccc00cc00cccccc00cc0ccccccccccc
0000000000000000ccc00000c00c00000000000000cc00c00ccccccccc0cc0000c0ccccccc00c000ccccccccccccc00c000ccccc00000ccccccccccccccccccc
0000000000000000c0ccc0c0ccccc0c00000000000000000000c0ccccccccc0c0000cc0cccccc0c0cccccccccccccccc00cccc0ccc00cc0cc000cccccccccccc
0000000000000000cccc0000cccc0000000000000000000000ccccccccc0000000cccccccccc0000ccccccccccccccccc000cccc000ccccccccccccccccccccc
70000000000000000000000000000000000007000000000700000000000000000000000000000000000777000070000000000000000000000000000000000000
70000000000000000000000000000000000007700000007700000000000000000000000000000000007000700070000000000000000000000000000000000000
70000000000000000000000000000000000007700000007700000000000000000000000000000000070000000070000000000000000000000000000000000000
70000000000000000000000000000000000007070000070700000000000000000000000000000000070000000070000000000000000000000000000000000000
70000000000000000000000000000000000070070000070070000000000000000000000000000000070000000070000000000000000000000000000000000000
70000000000000000000000000000000000070070000070070000000000000000000000000000000007000000070000000000000000000000000000000000000
70000000777700007000000000700000000070007000700070000077777000707700777000000000000770000070000707000007000000000000000000000000
70000007000070007000070000700000000070007000700070000700000700770077000700000000000007000070007007000007000000000000000000000000
70000070000007000700070007000000000700000707000007007000000070700007000070000000000000700070070000700070000000000000000000000000
70000070000007000700070007000000000700000707000007007777777770700007000070000000000000070077700000700070000000000000000000000000
70000070000007000070707070000000000700000707000007007000000000700007000070000000000000070077000000700070000000000000000000000000
70000070000007000070707070000000000700000070000007007000000000700007000070000000000000070070700000070700000000000000000000000000
70000070000007000070707070000000007000000070000000700700000070700007000070000000000000070070070000070700000000000000000000000000
70000007000070000007000700000000007000000000000000700770000700700007000070000000000000700070007000007000000000000000000000000000
77770000777700000007000700000000007000000000000000700077777000700007000070000000000077000070000700007000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333333333333333333333333333333333333333333333333333330000000000000000000000000000000000000000000000000000000033dddd33
33333333333333333333333333333333333333333333333333333333333333330000000000000000000000000000000000000000000000000000000034888843
33333333333333333333333333333333333333333333333333333333333333330000000000000000000000000000000000000000000000000000000032499423
33333333333333333333333333333333333333333333333333333333333333330000000000000000000000000000000000000000000000000000000032488423
33333333333333333333333333355333333333333333333333333333333333330000000000000000000000000000000000000000000000000000000034488443
33333333333333333333333333355333333333333333333333333333333333330000000000000000000000000000000000000000000000000000000032499423
33333333333333333333333333511533333333333333333333333333333333330000000000000000000000000000000000000000000000000000000035488453
33333333333333333333333333511533333333333333333333333333333333330000000000000000000000000000000000000000000000000000000033555533
33333333333333333333333335111153333333333333333333333333333333330000000000000000000000000000000000000000000000000000000033dddd33
33333333333333333333333335111153333333333333333333333333333333330000000000000000000000000000000000000000000000000000000034000043
33333333333333333333333351111115333333333333333333333333333333330000000000000000000000000000000000000000000000000000000032555523
33333333333333333333333511111111533333333333333333333333333333330000000000000000000000000000000000000000000000000000000032488423
33333333333333333333333511111111533333333333333333333333333333330000000000000000000000000000000000000000000000000000000034488443
33333333333333333333335111111111153333333333333333333333333333330000000000000000000000000000000000000000000000000000000032499423
33333333333333333333335dddddddddd53333333333333333333333333333330000000000000000000000000000000000000000000000000000000035488453
333333333333333333333511d1111111115333333333333333333333333333330000000000000000000000000000000000000000000000000000000033555533
33333333333333333333351d11111111115333333333333333333333333333330000000000000000333333333333333333333333333333333333333333333333
33333333333333333333511d11111111111533333333333333333333333333330000000000000000333aa3333333383333888833333003333888333333833333
3333333333333333333511d111111111111153333333333333333333333333330000000000000000338aa333333aa833388888833303303338a8333338883833
3333333333333333333511d11111111111115333333333333333333333333333000000000000000033883333333a883338888853388330333888388833838883
333333333333333333511d11111111111111153333333333333333333333333300000000000000003388833333888333388888533a833033330038a833003833
333333333333333333511d1111111111111115333333333333333333333333330000000000000000333883333333033338888553333303333330088833300333
33333333333333333511d111cccccccc111111533333333333333333333333330000000000000000333888333330333333555533333003333330333333303333
3333333333333333511d1111c777777c111dddd53333333333333333333333330000000000000000333333333333333333333333333333333333333333333333
3333333333333333511d1111cccccccc111d11153333333333333333333333333333833300000000333333333333333333333333333333333333333333333333
333333333333333511d1111111111111111d11115333333333333333333333333333833300000000333333333333333333333333333333333333333333333333
333333333333333511d11111111111111111d1115333333333333333333333333333883300000000333333333333333333333333333333333333333333333333
33333333333333511d111111111111111111d1111533333333333333333333333338883300000000333388333333333333333333333303333333333333333333
33333333333333511d1111111111111111111d111533333333333333333333333338883300000000333888333333033333333333333030333300333333003333
33333333333335ddddddddddddd1111111111d111153333333333333333333333838888300000000333883333333033333333333333330333330033333300333
333333333333511111111111111d1111111111d11115333333333333333333333838888300000000333888333330333333333333333003333330333333303333
3333333333335111111111111111d111111111d11115333333333333333333333333333300000000333333333333333333333333333333333333333333333333
33333333333511111111111111111ddddddddddddddd533333333333333333333333333335555553333333330000000033311133333155333333333333315133
333333333335111111111111111111111111111111115333333333333333333333333333d755557d3357753300000000315d6d1333155513333316d131dd6d13
333333333351111111111111111111111111111111111533333333333333333333335555dd7777dd357dd753000000001d66d55131d5651333156d6515556653
3333333333555555555555555555555555555555555555333333333333333333333d7777dd7557dd67d77d7300000000566dd6753d6dd5533365d5d1555dd6d1
3333333333333333333333333333333333333333333333333333333333333333333d7777dd7557dd67677673000000006d5d555531d6d653356ddd531555dd61
333333333333333333333333333333333333333333333333333333333333333333336666dd7777dd36766763000000005d55511333d67653315d661315556771
333333333333333333333333333333333333333333333333333333333333333333333333d766667d336776330000000015513333331d6d1333d6d53335567713
3333333333333333333333333333333333333333333333333333333333333333333333333660066b333333330000000033333333333113333331133331156133
33333333333333333333333333333333333333333333333333333333333333330000000033377333000000000000000000000000000000000000000000000000
33333333333333333333333333333333333333333333333333333333333333330000000033366333000000000000000000000000000000000000000000000000
33333333333333333333333333333333333333333333333333333333333333330000000033355333000000000000000000000000000000000000000000000000
33333333333333333333333333333333333333333333333333333333333333330000000033333333000000000000000000000000000000000000000000000000
33333333333333333333333333333333333333333333333333333333333333330000000033333333000000000000000000000000000000000000000000000000
33333333333333333333333333333333333333333333333333333333333333330000000033333333000000000000000000000000000000000000000000000000
33333333333333333333333333333333333333333333333333333333333333330000000033333333000000000000000000000000000000000000000000000000
33333333333333333333333333333333333333333333333333333333333333330000000033333333000000000000000000000000000000000000000000000000
33333333333333333333333333333333333333333333333333333333333333330000000000000000000000000000000000000000000000003333333333333333
33333333333333333333333333333333333333333333333333333333333333330000000000000000000000000000000000000000000000003767671333337713
33333333333333333333333333333333333333333333333333333333333333330000000000000000000000000000000000000000000000007677767133377713
33333333333333333333333333333333333333333333333333333333333333330000000000000000000000000000000000000000000000003767671333377133
33333333333333333333333333333333333333333333333333333333333333330000000000000000000000000000000000000000000000003367613333713333
33333333333333333333333333333333333333333333333333333333333333330000000000000000000000000000000000000000000000003336133337133333
33333333333333333333333333333333333333333333333333333333333333330000000000000000000000000000000000000000000000003333333333333333
33333333333333333333333333333333333333333333333333333333333333330000000000000000000000000000000000000000000000003333333333333333
333833333333333333333333333333333337713333777133333333333f3333333f33333300000000000000000000000033367333333673333336733300080000
332823333337133333333333333333333337713337163713333333333d3333333d333333000000000000000000000000433493342332e3322332833200080000
338083333777771337717713333333333777171371676371333333333933333339333333000000000000000000000000499669942ee66ee22886688200000000
3280823337575713377777133333333337177133767676713333333335333333539333330000000000000000000000003490794332e07e233280782388000880
38888833377577133777771333333333337713337167637133333333333333333333333300000000000000000000000033350333333503333335033300000000
28808823337771333377713333333333771371333716371333333333333333333333333300000000000000000000000033366333333663333336633300080000
88888883333713333337133333333333333371333377713333333333333333333333333300000000000000000000000033399333333ee3333338833300080000
33333333333333333333333333333333333333333333333333333333333333333333333300000000000000000000000033344333333223333332233300000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000c000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000007000000000000000000000000000000000000700000000070000000000000000000000000000000000077700007000000000000000000000000
00000000000007000000000000000000000000000000000000770000000770000000000000000000000000000000000700070007000000000000000000000000
00000000000007000000000000000000000000000000000000770000000770000000000000000000000000000005007000000007000000000000000000000000
00000000000607000000000000000000000000000000000000707000007070000000000000000000000000000000007000000007000000000000000000000000
00000000000007000000000000000000000000000000000007007000007007000000000000000000000000000000007000000007000000000000000000000000
00000000000007000000000000000000000000000000000007007000007007000000000000000000000000000000000700000007000000000000000000000000
00000000000007000000077770000700000000070000000007000700070007000007777700070770077700000000000077000007000070700000700000000000
00000000000007000000700007000700007000070000000007000700070007000070000070077007700070000000000000700007000700700000700000000000
00000000000007000007000000700070007000700000000070010070700000700700000007070000700007000000000000070007007000070007000000000000
00000000000007000007000000700070007000700000000070000070700000700777777777070000700007000000000000007007770000070007000000000000
00000000000007000007000000700007070707000000000070000070700000700700000000070000700007000000000000007007700000070007000000000000
00000000000007000007000000700007070707000000000070000007000000700700000000070000700007000000000000007067070000007070000000000000
00000000000007000007000000700007070707000000000700000007000000070070000007070000700007000000000000007007007000007070000000000000
00000000000007000000700007020000700070000000000700000000000000070077000070070000700007000000000000070007000700000700000000000000
00000000000007777000077770000000700070000000000700000000000000070007777700070000700007000000000007700007000070000700000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000
00000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000
00000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000050000000000000000000000001000000000000700000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000
00000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000050000000000000000000000000100000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000066616161000066616661616161000000661066610661616106616100666106610000000000000000000000000000000
00000000000000000000000000000000061616161000061616161616161000000616116116111616161616100616161110000000000000000000000000000000
00000000000000000000000000000000066116661000066616661616161000000616106106100666161616100666166610000000000000000000000000000000
00000000000000000000000000000000061611161000061116161616161000000616106106100616161616100616111610000000000000000000000000000000
00000000000000000000000000000000066616661000061006161166166610000616166611661616166116661616166110000000000000000000000000000000
00000000000000000000000000000000011111111000011001111011111110000111111110111111111101111111111100000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000c10c100ccc10c10c1c1ccc1cc10ccc1ccc1ccc1ccc10000000000000000000000000000000000000000000
00000000000000000000000000000000000000000c1c1c1001c11c1c1c1c11c11c1c1c1c1c111c1c1ccc10000000000000000000000000000000000000000000
00000000000000000000000000000000000000000c1c1c1000c10c1c1c1c10c10c1c1cc11cc10ccc1c1c10000000000000000000000000000000000000000000
00000000000000000000000000000000000000000c111c1000c10cc11c1c10c10c1c1c1c1c110c1c1c1c10000000000000000000000000000000000000000000
000000000000000000000000000000000000000001cc1ccc1ccc11cc11cc1ccc1ccc1c1c1ccc1c1c1c1c10000000000000000000000000000000000000000200
00000000000000000000000000000000000000000011111111111011101111111111111111111111111110000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000002000020000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000600000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__sfx__
0149010d0c1100c1210c1310c1410c1510c1610c1710c1610c1510c1410c1310c1210c11118100181001810000100001000010000100001000010000100001000010000100001000010000100001000010000100
0147010d0c5140c5210c5310c5410c5510c5610c5710c5610c5510c5410c5310c5210c51118500185001850000500005000050000500005000050000500005000050000500005000050000500005000050000500
010b070818070180511804118031180211801118011180100c7000c7010c7010c7010c70118700187001870000700007000070000700007000070000700007000070000700007000070000700007000070000700
01050c0d0070018770187711875118751187411874118731187301872018720187101871018700187001870018700007000070000700007000070000700007000070000700007000070000700007000070000700
01080020187171f727180271f017187171f027187171f527180271f517187271f127180171f527180171f527187271f527180171f027185171f727181171f027185171f727185171f017187271f517180271f017
010500001804418030187201871500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500001804018030187201871000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01050f101807018071180611806118051180511804118041187311873118721187211871118711187111871100701007010070100701007010070100701007010070100701007010070100701007010070100701
01c800000482004820048200482004820048200482004820048200482004820048200482004820048200482004820048220482004820048200482004820048200482004820048200482004820048200482004115
01c800001080423920239202391123915219242192021920219202192021911219152392023920239202392023911239151d9201d9201d9252192021920219202192021920219112191518930189211891118915
01c800001f9241f9201f9111f915199241992019911199152492024920249202491124915139201392013911139152692026920269202691126915199101991019911199151d9201d9201d9201d9111d9121d915
015a00002bb402bb312bb212bb1124b4024b3124b2124b1121b4021b3121b2121b112ab402ab312ab212ab112bb402bb312bb212bb112fb402fb312fb212fb112db402db312db212db112ab402ab312ab212ab11
015a0000108401083110821108110c8400c8310c8210c811138401383113821138110e8400e8310e8210e811108401083110821108110c8400c8310c8210c811138401383113821138110e8400e8310e8210e811
017000201771417015177141701517714170151701417015170141771517714177151701417715170141701517714170151701417715170141701517714170151701417715170141771517014177151701417015
015a000010c1010c1010c1010c200cc200cc100cc100cc2013c2013c1013c1013c200ec200ec100ec100ec2010c2010c1010c1010c200cc200cc200cc200cc1013c1013c2013c2013c200ec200ec100ec100ec20
017000200b7140b0150b7140b0150b7140b0150b0140b0150b0140b7150b7140b7150b0140b7150b0140b0150b7140b0150b0140b7150b0140b0150b7140b0150b0140b7150b0140b7150b0140b7150b0140b015
013c000028b4028b3128b2128b1128b1028b1526b4026b3126b2126b1126b1126b1110b2010b1110b2010b1128b4028b3128b2128b1128b1128b1126b4026b3126b2126b1126b1126b1110b2010b1110b2010b11
013c00000c8400c8310c8210c8110c8120c81110840108311082110811108121081109a2009a110ba200ba110c8300c8210c8210c8110c8120c81110840108311082110811108121081109a2009a110ba200ba11
013c00000c0140c7150c7140c7150c7140c0150b7140b0150b7140b0150b0140b71509014090150b7140b0150c0140c7150c7140c7150c7140c0150b7140b0150b7140b0150b0140b71509014090150b7140b015
013c00000cc100cc100cc100cc200cc200cc1010c1010c2010c2010c1010c1010c2009c2009c1010c1010c200cc100cc100cc100cc200cc200cc1010c1010c2010c2010c1010c1010c2009c2009c1010c1010c20
013c00000ca400ca310ca210ca110ca120ca1110a4010a3110a2110a1110a1210a1109a2009a110ba200ba110ca300ca210ca210ca110ca120ca1110a4010a3110a2110a1110a1210a1109a2009a110ba200ba11
015a000010a4010a3110a2110a110ca400ca310ca210ca1113a4013a3113a2113a110ea400ea310ea210ea1110a4010a3110a2110a110ca400ca310ca210ca1113a4013a3113a2113a110ea400ea310ea210ea11
0114000026d4525d4523d451ed4526d4525d4523d451ed4526d4525d4523d451ed4526d4525d4523d451ed4526d4525d4521d451ed4526d4525d4521d451ed4526d4525d4521d451ed4526d4525d4521d451ed45
0114000025d4523d4521d451cd4525d4523d4521d451cd4525d4523d4521d451cd4525d4523d4521d451cd4525d4523d4520d451cd4525d4523d4520d451cd4525d4523d4520d451cd4525d4523d4520d451cd45
011400001a0101a7111a715260051a0101a7111a715260051a0101a7111a715260051a0101a7111a715260051a0101a7111a715260051a0101a7111a715260051a0101a7111a715260051a0101a7111a71526005
011400001901019711197152500519010197111971525005190101971119715250051901019711197152500517010177111771523005170101771117715230051701017711177152300517010177111771524005
011400001cd1526d1725d1523d101ed1726d1025d1523d101ed1526d1025d1523d171ed1526d1025d1523d101ed1526d1025d1521d141ed1726d1025d1521d101ed1526d1725d1521d141ed1526d1025d1721d10
011400001ed1525d1723d1521d101cd1725d1023d1521d101cd1525d1023d1521d171cd1525d1023d1521d101cd1525d1023d1520d101cd1725d1023d1520d101cd1525d1723d1520d101cd1525d1023d1720d10
0114000034f2034f1134f1034f1034f1034f1034f1034f1034f1134f1034f1034f1234f1234f1234f1528f0134f2034f1134f1034f1034f1034f1034f1034f1034f1134f1034f1034f1234f1234f1234f1528f01
0114000034f2034f1134f1034f1039f2039f1139f1039f103ef203ef113ef103ef103df203df113df103df1032f2032f1132f1032f1032f1032f1032f1032f1032f1132f1032f1032f1232f1232f1232f1532f11
011400000b8500b8500b8200b8200b8500b8500b8200b8200b8500b8500b8200b8200b8500b8500b8200b8200e8500e8500e8200e8200e8500e8500e8200e8200e8500e8500e8200e8200e8500e8500e8200e820
011400000985009850098200982009850098500982009820098500985009820098200985009850098200982004850048500482004820048500485004820048200485004850048200482004850048500482004820
011800202cb402cb212db402db212fb402f7152fb402fb212fb202fb112fb122fb1134b4034b3134b2134b1132b4032b3132b2132b112fb402fb312fb212fb112fb122fb122fb1200a0000a0000a0000a0000a00
011500002cb002cb012db002db012fb002f7052fb002fb012fb002fb012fb022fb0134b0034b0134b0134b0136b0036b0136b0136b0132b0032b0132b0132b0132b0232b0232b0200a0000a0000a0000a0000a00
0118002020a4020a3120a2120a1120a1020a1518a4018a3118a2118a1018a1018a1018a1018a1018a1018a1018a1018a1018a1018a1018a1018a1018a1018a1018a1018a1018a1000a0000a0000a0000a0000a00
011800201cb101cb101cb101cb101cb101cb101fb101fb101fb101fb101fb101fb101fb101fb101fb101fb101fb101fb101fb101fb101fb101fb101fb101fb101fb101fb101fb101fb101fb101fb1000a0000a00
011800202cb402cb212db402db212fb402f7152fb402fb212fb202fb112fb122fb1128b4028b3128b2128b1128b1028b1028b1028b1028b1028b1228b1228b1228b1228b1228b1228a0500a0000a0000a0000a00
011800202cb402cb212db402db212fb402f7152fb402fb212fb202fb112fb122fb1134b4034b3134b2134b1136b4036b3136b2136b1132b4032b3132b2132b1132b1232b1232b1200a0000a0000a0000a0000a00
0118002020b4020b2121b4021b2123b402371523b4023b2123b2023b1123b1223b111cb401cb311cb211cb111cb101cb101cb101cb101cb101cb121cb121cb121cb121cb121cb121cb121cb121cb1200a0000a00
011800201085010850108501085010850108500c8400c8400c8400c8400c8400c8400c8310c8300c8300c8300c8210c8200c8200c8200c8110c8100c8100c8100c8100c8100c8100c8100c8100c8100000000000
0118002020b4020b2121b4021b2123b402371523b4023b2123b2023b1123b1223b1128b4028b3128b2128b1126b4026b3126b2126b1123b4023b3123b2123b1123b1223b1223b1223b1223b1223b1200a0000a00
0118002020b4020b2121b4021b2123b402371523b4023b2123b2023b1123b1223b1128b4028b3128b2128b112ab402ab312ab212ab1126b4026b3126b2126b1126b1226b1226b1228a0000a0000a0000a0000a00
0121002024b4024b4024b4024b4024b4024b3124b2124b1123b4023b4023b4023b4023b4023b3123b2123b1124b4024b4024b4024b4024b4024b3124b2124b1123b4023b4023b4023b401fb401fb411fb411fb41
012100001ca201ca201ca201ca201ca201ca221ca2210a151ca201ca201ca201ca201ca201ca221ca2210a151ca201ca201ca201ca201ca201ca221ca2210a151ca201ca201ca201ca201ca201ca221ca2210a15
0121000009840098400984009840098400984009840098400b8400b8400b8400b8400b8400b8400b8400b8400c8400c8400c8400c8400c8400c8400c8400c8400b8400b8400b8400b8400b8400b8400b8400b840
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010302200073403721007310171100721037310071103721007310171100721027310071103721007310371100721027310071103721007310371100721037310071101721007310371100721037310071102721
0105000000610076100c61113610186101f611246102b61030611376103c6103c6103c6103c6153c634307333a6242d523396242a7233762429523356142771332614245132f614207132b6141d5132661418513
010200003f6142644525341242312343122321212213f6041f3050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006000001713026140472306624097330d634147431f6443d62135753146232b743096231b733046231172300613097130071103711007110371100711037110071103711007110371100711037110071103711
01050000147540f553137540e553127540d553117540c553107540b5530f7540a5530e754095530d754085530c744075430b744065430a7340553309734045330872403523077240252306714015130571400513
0105000000514057130151406713025240772303524087230453409733055340a733065440b743075440c743085540d753095540e7530b554107530d554127530c5030c5030c5030450404505045040450504504
010200210014300105001000000000000000000000000000011050110500100001000010000100001000010001143011050010000100001000010000100001000010000100001000010000100001000010000100
0103001329323244131d3130c30028323232131c4130c30029323244131d3130c3002a323257131e3130c30028323234131c4130c3000c3000c3000c3000c3000030000300003000030000300000000000000000
010200003001501615300153551531015016153201537515330150161534015395153501501615360153b51537015016153000531505320053100534005310053500531005350053100535005310053500531005
01020000334153161531615296152d205316152a41521615316151a61527205316152541517615316150f61530515316143071531614325153161434715316143571531614355153161435715316143551531614
010200000c475152740f474186651646515264114540e6550d4550b24408445066440443502234014340062500424002240041500615000040000400004000040000400004000040000400004000040000400004
010100200a4133b2110a1133b4110b013302110b313302210a1133b2110a4133b2110a0133b2210a1133b211091133a211091133a6110a4133b2210a1133b2110a7133b2210a3133b2110a1133b2110a6133b411
010700002615727547261372752726117275172611727517326112c61128611226111e6111a61114611116110c2110c2110c2110f4110d227104270e227114270f22712427102271342711217144171221715417
01050000026100461106621086210b6310f631136411664136050360403671036710367003604036030367103671036700360303602036710367103670036020360103671036710300000c0000c0000c0000c000
010300003013300100241230010018113001001f100001001d100001001d100001001b100001001b1000010018100001001610000100161000010013100001001310000100001000010000100001000010000100
01010000287770c700257770c700257670c700237570c700237570c700217470c700217370c7001e7370c7001c7270c7001c7170c70019717127050c700127050070000700007000070000700007000070000700
01010000197770c700197770c7001c7670c7001c7570c7001e7570c700217470c700217370c700237370c700237270c700257170c700287170c7000c7000c700135000c600135000c600135050c605135050c605
01010000285402861524540246151f5301f61515530156150e5200e6151850020505275002c50500000000001b5601b6152955029615305403061539530396150050500505005050050500505005050050500505
__music__
03 08090a57
01 0b150d57
00 0b150f0e
00 10141213
00 0b0c0d0e
00 0b0c0f0e
02 10111213
01 16181a5a
00 17191b5b
00 16181a5a
00 17191b5b
00 16181c1a
00 17191c1b
00 16181c1a
00 17191c1b
00 16181d1a
00 17191c1b
00 16181d1a
00 17191c1b
00 161e1d18
00 171f1c19
00 161e1d18
02 171f1c19
01 24222321
00 20222321
00 24222321
00 25222321
01 26272321
00 28272321
00 26272321
00 28272321
00 2a2b2c44
02 2a2b2c44

