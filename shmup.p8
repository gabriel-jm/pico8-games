pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
-- init

function _init()
 upd=update_start
 drw=draw_start
 
 blinkt=1
end

function _draw()
	drw()
end

function _update()
	blinkt+=1
	upd()
end

function startgame()
	upd=update_game
	drw=draw_game
	
	ship_x=64
	ship_y=64
	ship_sx=0
	ship_sy=0
	ship_spr=2
	
	flame_spr=5
	
	bullets={}
	bullet_spr=16
	
	muzzle=0
	
	stars={}
	for i=1,100 do
		add(stars,{
			x=flr(rnd(128)),
			y=flr(rnd(128)),
			spd=rnd(1.5)+0.5
		})
	end
end
-->8
-- tools

function create_starfield()
	foreach(stars,function(s)
		pset(
			s.x,
			s.y,
			get_star_col(s.spd)
		)
	end)
end

function get_star_col(spd)
	if spd<1 then
		return 1
	end
	
	if spd<1.5 then
		return 13
	end

	return 6
end

function update_stars()
	foreach(stars,function(s)
		s.y+=s.spd
		
		if s.y>127 then
			s.y=-1
		end
	end)
end

function blink()
	local blink_colors=split"5,6,7,6,5"
	return blink_colors[
		flr((blinkt/7)%5+1)
	]
end
-->8
-- update

function update_start()
	if btnp(4) or btnp(5) then
		startgame()
	end
end

function update_game()
	ship_sx,ship_sy,ship_spr=0,0,2
	
	if btn(⬅️) then
		ship_sx=-2
		ship_spr=1
	end
	if (btn(➡️)) then
		ship_sx=2
		ship_spr=3
	end
	if (btn(⬆️)) ship_sy=-2
	if (btn(⬇️)) ship_sy=2
	if btnp(🅾️) then
		add(
			bullets,
			{x=ship_x,y=ship_y-4}
		)
		sfx(0)
		muzzle=6
	end
	
	ship_x+=ship_sx
	ship_y+=ship_sy
	
	foreach(bullets,function(b)
		b.y-=4
		
		if b.y<-4 then
			del(bullets,b)
		end
	end)
	
	flame_spr+=1
	
	if flame_spr>9 then
		flame_spr=5
	end
	
	muzzle=max(0,muzzle-1)
	
	ship_x=mid(0,ship_x,127-8)
	ship_y=mid(0,ship_y,127-8)
	update_stars()
end
-->8
-- draw

function draw_start()
	cls(1)
	print(
		"shoot them up!",
		36,
		40,
		7
	)
	print(
		"press any key to start",
		20,
		80,
		blink()
	)
end

function draw_game()
	cls()
	create_starfield()
	
	spr(ship_spr,ship_x,ship_y)
	spr(flame_spr,ship_x,ship_y+8)
	
	foreach(bullets,function(b)
		spr(bullet_spr,b.x,b.y)
	end)
	
	if muzzle>0 then
		circfill(
			ship_x+3,
			ship_y-2,
			muzzle,
			7
		)
	end
end
__gfx__
00000000000220000002200000022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000028820000288200002882000000000000077000000770000007700000c77c0000077000000000000000000000000000000000000000000000000000
007007000028820000288200002882000000000000c77c000007700000c77c000cccccc000c77c00000000000000000000000000000000000000000000000000
000770000028882002888820028882000000000000cccc00000cc00000cccc0000cccc0000cccc00000000000000000000000000000000000000000000000000
0007700002cc8820288cc8820288cc2000000000000cc000000cc000000cc00000000000000cc000000000000000000000000000000000000000000000000000
0070070002c68820288c688202886c200000000000000000000cc000000000000000000000000000000000000000000000000000000000000000000000000000
00000000025588200285582002885520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000002992000029920000299200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
009aa900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
009aa900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000035540305402855024550205501c550185501555011550105500e5500c5500954007530055200152000510000000000000000000000000000000000000000000000000000000000000000000000000000
