pico-8 cartridge // http://www.pico-8.com
version 38
__lua__
-- init

function _init()
 t=0
 blinkt=1
 btn_lockout=0
 
 enemy_types={
		{ -- green alien
			hp=3,
			spr=21,
			ani=split"21,22,23,24",
			atk=function(self)
				self.sy=1.7
				self.sx=sin(t/45)
				
				if self.x<32 then
					self.sx+=1-self.x/32
				end
				
				if self.x>88 then
					self.sx-=(self.x-88)/32
				end
			end
		},
		{ -- red flame guy
			hp=5,
			spr=148,
			ani=split"148,149",
			atk=function(self)
				self.sy=2.5
				self.sx=sin(t/20)
				
				if self.x<32 then
					self.sx+=1-self.x/32
				end
				
				if self.x>88 then
					self.sx-=(self.x-88)/32
				end
			end
		},
		{ -- spinning ship
			hp=5,
			spr=184,
			ani=split"184,185,186,187",
			atk=function(self)
				if self.sx==0 then
					self.sy=1.8
					
					if ship.y<=self.y then
						self.sy=0
						self.sx=ship.x<self.x
							and -1.8 or 1.8
					end
				end
			end
		},
		{ -- yellow ship
			hp=5,
			spr=208,
			ani=split"208,210",
			spr_width=2,
			col_width=16,
			atk=function(self)
				self.sy=0.4
				
				if self.y<110 then
					self.sy=1
				end
			end
		}
	}
	
	wave_patterns={
		{
			freq=20,
			pattern={
				split"1,1,1,1,1,1,1,1,1,1",
				split"1,1,1,1,1,1,1,1,1,1",
				split"1,1,1,1,1,1,1,1,1,1",
				split"1,1,1,1,1,1,1,1,1,1"
			}
		},
		{
			freq=50,
			pattern={
				split"1,1,2,2,3,3,2,2,1,1",
				split"0,1,2,1,0,0,1,2,1,0",
				split"0,1,2,1,0,0,1,2,1,0",
				split"1,1,2,2,3,3,2,2,1,1"
			}
		},
		{
			freq=45,
			pattern={
				split"1,1,2,2,3,3,2,2,1,1",
				split"3,1,2,1,3,3,1,2,1,3",
				split"3,1,2,1,3,3,1,2,1,3",
				split"1,1,2,2,3,3,2,2,1,1"
			}
		},
		{
			freq=40,
			pattern={
				split"1,1,2,2,3,3,2,2,1,1",
				split"0,1,2,1,4,0,1,2,1,0",
				split"0,1,2,1,0,0,1,2,1,0",
				split"1,1,2,2,3,3,2,2,1,1"
			}
		}
	}
 
 modes={
 	start={update_start,draw_start},
 	game={update_game,draw_game},
 	wave_text={update_wave_text,draw_wave_text},
 	gameover={update_gameover,draw_gameover},
 	win={update_win,draw_win}
 }
 
 start_screen()
end

function _draw()
	drw()
end

function _update()
	t+=1
	blinkt+=1
	upd()
end

function start_screen()
	mode"start"
	music(7)
end

function startgame()
--	music(-1,1000)
	t=0
	wave=0
	next_wave()
	
	ship=make_obj {
		x=64,
		y=64,
		sx=0,
		sy=0,
		spr=2,
		spr_width=1
	}
	
	lives=4
	invul=0
	muzzle=0
	
	flame_spr=5
	
	bullets={}
	bullet_timer=0
	
	stars={}
	for i=1,100 do
		add(stars,{
			x=flr(rnd(128)),
			y=flr(rnd(128)),
			spd=rnd(1.5)+0.5
		})
	end
	
	enemies={}
	en_bullets={}
	
	explosions={}
	
	shock_waves={}
	
	particles={}
end

function mode(target_mode)
	m=target_mode
	upd,drw=unpack(
		modes[target_mode]
	)
end
-->8
-- tools

function create_starfield()
	foreach(stars,function(s)
		pset(
			s.x,
			s.y,
			get_star_color(s.spd)
		)
	end)
end

function get_star_color(spd)
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

function has_collision(a,b)
	if a.y>b.y+b.col_width-1 then
		return false
	end
	if b.y>a.y+a.col_width-1 then
		return false
	end
	if a.x>b.x+b.col_width-1 then
		return false
	end
	if b.x>a.x+a.col_width-1 then
		return false
	end
	
	return true
end

function explode(x,y,is_blue)
	add(particles,{
		x=x,
		y=y,
		sx=0,
		sy=0,
		age=0,
		size=10,
		max_age=0,
		blue=is_blue
	})

	for i=1,30 do
		add(particles,{
			x=x,
			y=y,
			sx=(rnd()-0.5)*6,
			sy=(rnd()-0.5)*6,
			age=rnd(2),
			size=1+rnd(4),
			max_age=10+rnd(10),
			blue=is_blue
		})
	end
	
	for i=1,20 do
		add(particles,{
			x=x,
			y=y,
			sx=(rnd()-0.5)*10,
			sy=(rnd()-0.5)*10,
			age=rnd(2),
			size=1+rnd(4),
			max_age=10+rnd(10),
			spark=true
		})
	end
	
	big_shwave(x,y)
end

function small_sparks(x,y)
	add(particles,{
		x=x,
		y=y,
		sx=(rnd()-0.5)*8,
		sy=(rnd()-1)*3,
		age=rnd(2),
		size=1+rnd(4),
		max_age=10+rnd(10),
		spark=true
	})
end

red_age_colors={
	{15,5},
	{12,2},
	{10,8},
	{7,9},
	{5,10},
	{0,7}
}

blue_age_colors={
	{12,1},
	{10,13},
	{7,12},
	{5,6},
	{0,7}
}
function age_particle(
	age,
	is_blue
)
	local age_colors=is_blue
		and blue_age_colors
		or red_age_colors
	
	for
		age_col in all(age_colors)
	do
		if age>age_col[1] then
			return age_col[2]
		end
	end
end

function small_shwave(x,y)
	add(shock_waves,{
		x=x,
		y=y,
		color=9,
		r=3,
		speed=1,
		target_r=6
	})
end

function big_shwave(x,y)
	add(shock_waves,{
		x=x,
		y=y,
		color=7,
		r=3,
		speed=3.5,
		target_r=25
	})
end

function make_obj(val)
	local obj=val
	
	obj.sx=val.sx or 0
	obj.sy=val.sy or 0
	obj.flash=0
	obj.shake=0
	obj.hp=val.hp or 5
	obj.spr_width=val.spr_width
		or 1
	obj.ani_frame=1
	obj.ani_spd=0.4
	obj.col_width=val.col_width
		or 8
	
	return obj
end

function animate(obj)
	obj.ani_frame+=obj.ani_spd
		
	if 
		flr(obj.ani_frame)>#obj.ani
	then
		obj.ani_frame=1
	end
	
	obj.spr=obj.ani[
		flr(obj.ani_frame)
	]
end
-->8
-- update

function update_start()
	if not btn(4)
		and not btn(5)
	then
		btn_released=true
	end
	
	if btn_released and
		(btnp(4) or btnp(5))
	then
		startgame()
		btn_released=false
	end
end

function update_game()
	ship.sx,ship.sy,ship.spr=0,0,2

	if btn(⬅️) then
		ship.sx=-2
		ship.spr=1
	end
	if (btn(➡️)) then
		ship.sx=2
		ship.spr=3
	end
	if (btn(⬆️)) ship.sy=-2
	if (btn(⬇️)) ship.sy=2
	if btn(🅾️) then
		if bullet_timer<=0 then
			add(bullets,make_obj {
				x=ship.x+2,
				y=ship.y-4,
				spr=16,
				col_width=5
			})
			sfx(0)
			muzzle=5
			bullet_timer=4
		end
	end
	
	bullet_timer-=1
	
	foreach(bullets,function(b)
		b.y-=4
		
		foreach(enemies,function(e)
			if has_collision(e,b) then
				del(bullets,b)
				e.hp-=1
				sfx(3)
				e.flash=2
				small_sparks(b.x+4,b.y+4)
				small_shwave(b.x+4,b.y+4)
				
				if e.hp<=0 then
					kill_enemy(e)
				end
			end
		end)
		
		if b.y<-4 then
			del(bullets,b)
		end
	end)
	
	foreach(en_bullets,function(b)
		move(b)
		animate(b)
		
		if b.y>128
			or b.x<-8
			or b.x>128
			or b.y<-8
		then
			del(en_bullets,b)
		end
		
		if invul==0
			and has_collision(b,ship)
		then
			explode(
				ship.x+4,
				ship.y+4,
				true
			)
			lives-=1
			invul=60
			sfx(1)
			del(en_bullets,b)
		end
	end)
	
	foreach(enemies,function(e)
		if e.wait>0 then
			e.wait-=1
		else
			e:mission()
		end
	
--		e.ani_frame+=e.ani_spd
--		
--		if 
--			flr(e.ani_frame) > #e.ani
--		then
--			e.ani_frame=1
--		end
--		
--		e.spr=e.ani[
--			flr(e.ani_frame)
--		]
		animate(e)
		
		if
			(
				e.mission!=fly_in
				and e.mission!=waiting
			)
			and (
				e.y>128
				or e.x<-8
				or e.x>128
			)
		then
			del(enemies,e)
		end
		
		if
			invul==0
		 and has_collision(e,ship)
		then
			explode(
				ship.x+4,
				ship.y+4,
				true
			)
			lives-=1
			invul=60
			sfx(1)
		end
	end)
	
	invul=max(0,invul-1)
	
	ship.x+=ship.sx
	ship.y+=ship.sy
	
	ship.x=mid(0,ship.x,127-8)
	ship.y=mid(0,ship.y,127-8)
	
	flame_spr+=1
	
	if flame_spr>9 then
		flame_spr=5
	end
	
	muzzle=max(0,muzzle-1)
	
	update_stars()
	
	if lives<=0 then
		mode"gameover"
		btn_lockout=t+30
		music(6)
	end
	
	pick_enemy()
	
	if
		m=="game" and #enemies==0
	then
		next_wave()
	end
end

function update_wave_text()
	update_game()
	wavetime-=1
	
	if wavetime<=0 then
		mode"game"
		spawn_wave()
	end
end

function update_gameover()
	if(t<btn_lockout) return
	
	if not btn(4)
		and not btn(5)
	then
		btn_released=true
	end
	
	if btn_released and
		(btnp(4) or btnp(5))
	then
		start_screen()
		btn_released=false
	end
end

update_win=update_gameover
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
	
	if
		lives>0
		and (
			invul<=0
			or sin(t/5)<0.1
		)
	then
		draw_sprite(ship)
		spr(flame_spr,ship.x,ship.y+8)
	end
	
	foreach(enemies,function(e)
		if e.flash>0 then
			e.flash-=1
			for i=1,15 do
				pal(i,7)
			end
		end
		
		draw_sprite(e)
		pal()
	end)

	draw_sprites(bullets)
	
	if muzzle>0 then
		circfill(
			ship.x+3,
			ship.y-2,
			muzzle,
			7
		)
		circfill(
			ship.x+4,
			ship.y-2,
			muzzle,
			7
		)
	end
	
	foreach(shock_waves,function(s)
		circ(s.x,s.y,s.r,s.color)
		s.r+=s.speed
		
		if s.r>s.target_r then
			del(shock_waves,s)
		end
	end)
	
	foreach(particles,function(p)
		local p_color=age_particle(
			p.age,p.blue
		)
		
		if p.spark then
			pset(p.x,p.y,7)
		else
			circfill(
				p.x,
				p.y,
				p.size,
				p_color
			)
		end
		
		p.x+=p.sx
		p.y+=p.sy
		p.age+=1
		
		p.sx*=0.85
		p.sy*=0.85
		
		if p.age>p.max_age then
			p.size-=0.5
		end
		
		if p.size<0 then
			del(particles,p)
		end
	end)
	
	foreach(en_bullets,draw_sprite)
	
	for i=1,4 do
		spr(
			lives<i and 14 or 13,
			(i-1)*10,
			1
		)
	end
end

function draw_sprites(list)
	foreach(list,draw_sprite)
end

function draw_sprite(item)
	local spr_x,spr_y=item.x,item.y
	
	if item.shake>0 then
		item.shake-=1
		if t%4<2 then
			spr_x+=1
		end
	end

	spr(
		item.spr,
		spr_x,
		spr_y,
		item.spr_width,
		item.spr_width
	)
end

function draw_gameover()
	draw_game()
	print(
		"game over!",
		47,
		40,
		8
	)
	print(
		"press any key to restart",
		20,
		80,
		blink()
	)
end

function draw_wave_text()
	draw_game()
	print(
		"wave "..wave,
		56,
		40,
		blink()
	)
end

function draw_win()
	draw_game()
	print(
		"congratulations",
		35,
		40,
		12
	)
	print(
		"press any key to restart",
		20,
		80,
		blink()
	)
end
-->8
-- waves and enemies

function spawn_enemy(t,x,y,wait)
	local typ=t or 1
	local stats=enemy_types[typ]

	add(enemies,make_obj {
		x=x*1.2-16,
		y=y-62,
		hp=stats.hp,
		spr=stats.spr,
		ani=stats.ani,
		spr_width=stats.spr_width,
		col_width=stats.col_width,
		pos_x=x,
		pos_y=y,
		mission=fly_in,
		wait=wait,
		atk=stats.atk
	})
end

function place_enemies(
	pattern
)
	for y=1,#pattern do
		for x=1,#pattern[y] do
			if pattern[y][x]!=0 then
				spawn_enemy(
					pattern[y][x],
					x*12-6,
					2+y*12,
					x*1.7
				)
			end
		end
	end
end

function spawn_wave()
	sfx(28)
	place_enemies(
		wave_patterns[wave].pattern
	)
end

function next_wave()
	wave+=1
	
	if wave>4 then
		music(4)
		btn_lockout=t+30
		return mode("win")
	end
	
	music(wave==1 and 0 or 3)
	
	mode("wave_text")
	wavetime=80
end
-->8
-- behavior

function fly_in(en)
	en.x+=(en.pos_x-en.x)/6
	en.y+=(en.pos_y-en.y)/7
	
	if abs(en.y-en.pos_y)<0.5 then
		en.mission=protec
	end
end

function protec()
end

function attac(en)
	en:atk()
	move(en)
end

function pick_enemy()
	local freq=
		wave_patterns[wave].freq
	
	if m!="game" or t%freq!=0 then
		return
	end
	
	pick_attac()
end

function pick_attac()
	local index=flr(rnd(
		min(10,#enemies)
	))
	index=#enemies-index

	local enemy=enemies[index]
	if
		enemy
		and enemy.mission==protec
	then
--		enemy.ani_spd*=2
--		enemy.wait=20
--		enemy.shake=60
--		enemy.mission=attac
		fire(enemy)
	end
end

function move(obj)
	obj.x+=obj.sx
	obj.y+=obj.sy
end

function kill_enemy(en)
	sfx(1)
	del(enemies,en)
	explode(en.x+4,en.y+4)
	
	if en.mission==attac then
		if (rnd()<0.5) pick_attac()
	end
end
-->8
-- bullets

function fire(en)
	add(en_bullets,make_obj{
		x=en.x+2,
		y=en.y+8,
		sy=1,
		spr=32,
		ani={32,33,34,33},
		ani_spd=0.5,
		col_width=2
	})
end
__gfx__
00000000000220000002200000022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000028820000288200002882000000000000077000000770000007700000c77c0000077000000000000000000000000000088008800880088000000000
007007000028820000288200002882000000000000c77c000007700000c77c000cccccc000c77c00000000000000000000000000888888888008800800000000
000770000028882002888820028882000000000000cccc00000cc00000cccc0000cccc0000cccc00000000000000000000000000888888888000000800000000
0007700002cc8820288cc8820288cc2000000000000cc000000cc000000cc00000000000000cc000000000000000000000000000088888800800008000000000
0070070002c68820288c688202886c200000000000000000000cc000000000000000000000000000000000000000000000000000008888000080080000000000
00000000025588200285582002885520000000000000000000000000000000000000000000000000000000000000000000000000000880000008800000000000
00000000002992000029920000299200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09900000000000000000000000000000000000000330033003300330033003300330033000000000000000000000000000000000000000000000000000000000
97790000000000000000000000000000000000003bb33bb33bb33bb33bb33bb33bb33bb300000000000000000000000000000000000000000000000000000000
97790000000000000000000000000000000000003bbbbbb33bbbbbb33bbbbbb33bbbbbb300000000000000000000000000000000000000000000000000000000
9aa90000000000000000000000000000000000003b7717b33b7717b33b7717b33b7717b300000000000000000000000000000000000000000000000000000000
9aa90000000000000000000000000000000000000b7117b00b7117b00b7117b00b7117b000000000000000000000000000000000000000000000000000000000
9aa90000000000000000000000000000000000000037730000377300003773000037730000000000000000000000000000000000000000000000000000000000
09900000000000000000000000000000000000000303303003033030030330300303303000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000300003033000033300000030330033000000000000000000000000000000000000000000000000000000000
00ee000000ee00000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e22e0000e88e00007aa700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e2e82e00e8e28e007a79a70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e2882e00e8228e007a99a70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e22e0000e88e00007aa700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ee000000ee00000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000500000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000880088999900000055505555555005005055550000555000500050055550050000000000000000000000000000000000000000000000000
00000000990000000800999999990800500059998885550050005588555555500000000055050500000000000000000000000000000000000000000000000000
000000aaaaa000000009999aaa99980005588a989999855050588585558885000555005050000050000000000000000000000000000000000000000000000000
0090aaaaaaaa090000999aaaaaaa90000888a99999a9855000555595555985000050555000005050000000000000000000000000000000000000000000000000
0000aa77777aa0000999aaaaaaaa99000899999aa9aa850000555555895985050500050000000000000000000000000000000000000000000000000000000000
000aa777777aa0000999aa777aaa99000899aaaaaa99950008505958895595000000000000055000000000000000000000000000000000000000000000000000
000aa7777777a00009aaaa7777aaa9000589aa777a99a95050005555559598000000550000555000000000000000000000000000000000000000000000000000
0009aa77777aa000099aaa777aaa990055899aa7aaa9990005555555559599050005550005555500000000000000000000000000000000000000000000000000
000aaa77777aa9000999aaa77aaa990055889aaaaaa9850005589589955585000000555005550000000000000000000000000000000000000000000000000000
0000aaaaaaaaa00008999aaaaaaa9980058899999aa9850000889588558585000000055500000000000000000000000000000000000000000000000000000000
0000000aaaaa0000008999aaaaa990000558889999a9850005588599988585500500055505550500000000000000000000000000000000000000000000000000
00000000000000900809999999999000005559aa9998855005555555855885550050555005500550000000000000000000000000000000000000000000000000
00000900000900000088009999908800500055888885550050005588558550050500500005005555000000000000000000000000000000000000000000000000
00000000000000000000000000008000055005555550050055000555555000550550000000000050000000000000000000000000000000000000000000000000
00000000000000000000000000000000050000050000005005055550000000500500000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000070000020000200200002002000020020000205555555555555555555555555555555502222220022222200222222002222220
000bb000000bb0000007700000077000022ff220022ff220022ff220022ff2200578875005788750d562465d0578875022e66e2222e66e2222e66e2222e66e22
0066660000666600606666066066660602ffff2002ffff2002ffff2002ffff2005624650d562465d05177150d562465d27761772277617722776177227716772
0566665065666656b566665bb566665b0077d7000077d700007d77000077d700d517715d051771500566865005177150261aa172216aa162261aa612261aa162
65637656b563765b056376500563765008577580085775800857758008577580056686500566865005d24d50056686502ee99ee22ee99ee22ee99ee22ee99ee2
b063360b006336000063360000633600080550800805508008055080080550805d5245d505d24d500505505005d24d5022299222229999222229922222299222
006336000063360000633600006336000c0000c007c007c007c00c7007c007c05005500505055050050000500505505020999902020000202099990202999920
0006600000066000000660000006600000c7c7000007c0000077cc000007c000dd0000dd0dd00dd005dddd500dd00dd022000022022002202200002202200220
00ff880000ff88000000000000000000200000020200002000000000000000003350053303500530000000000000000000000000000000000000000000000000
0888888008888880000000000000000022000022220000220000000000000000330dd033030dd030005005000350053000000000000000000000000000000000
06555560076665500000000000000000222222222222222200000000000000003b8dd8b3338dd833030dd030030dd03003e33e300e33e330033e333003e333e0
6566665576555565000000000000000028222282282222820000000000000000032dd2300b2dd2b0038dd830338dd833e33e33e333e33e333e33e333e33e333e
57655576555776550000000000000000288888822888888200000000000000003b3553b33b3553b3033dd3300b2dd2b033300333333003333330033333300333
0655766005765550000000000000000028788782287887820000000000000000333dd333333dd33303b55b303b3553b3e3e3333bbe33333ebe3e333be3e3333b
0057650000655700000000000000000028888882080000800000000000000000330550330305503003bddb30333dd3334bbbbeb44bbbebb44bbbbeb44bbbebe4
00065000000570000000000000000000080000800000000000000000000000000000000000000000003553000305503004444440044444400444444004444440
0066600000666000006660000068600000888000002222000022220000222200002222000cccccc00c0000c00000000000000000000000000000000000000000
055556000555560005585600058886000882880002eeee2002eeee2002eeee2002eeee20c0c0c0ccc000000c0000000000000000000000000000000000000000
55555560555855605588856058828860882228802ee77ee22ee77ee22eeeeee22ee77ee2c022220ccc2c2c0cc022220c00222200000000000000000000000000
55555550558885505882885088222880822222802ee77ee22ee77ee22ee77ee22ee77ee2cc2cac0cc02aa20cc0cac2ccc02aa20c000000000000000000000000
15555550155855501588855018828850882228802eeeeee22eeeeee22eeeeee22eeeeee2c02aa20cc0cac2ccc02aa20ccc2cac0c000000000000000000000000
01555500015555000158550001888500088288002222222222222222222222222222222200222200c022220ccc2c2c0cc022220c000000000000000000000000
0011100000111000001110000018100000888000202020200202020220202020020202020000000000000000c000000cc0c0c0cc000000000000000000000000
00000000000000000000000000000000000000002000200002000200002000200002000200000000000000000c0000c00cccccc0000000000000000000000000
000880000009900000089000000890000000000001111110011111100000000000d89d0000189100001891000019810000005500000050000005000000550000
706666050766665000676600006656000000000001cccc1001cccc10000000000d5115d000d515000011110000515d0000055000000550000005500000055000
1661c6610161661000666600001666000000000001cccc1001cccc1000000000d51aa15d0151a11000155100011a151005555550055555500555555005555550
7066660507666650006766000066560000000000017cc710017cc71000000000d51aa15d0d51a15000d55d00051a15d022222222222222222222222222222222
0076650000766500007665000076650000000000017cc710017cc710000000006d5005d6065005d0006dd6000d50056026060602260606022666666226060602
000750000007500000075000000750000000000001111110011111100000000066d00d60006d0d600066660006d0d60020000002206060622222222020606062
00075000000750000007500000075000000000001100001101100110000000000760067000660600000660000060660020606062222222200000000022222220
00060000000600000006000000060000000000001100001101100110000000000070070000070700000770000070700022222220000000000000000000000000
0007033000700000007d330003330333000000000022220000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d3300000d33000028833003bb3bb3000000000888882000000000000000000000000000000000000000000000000000000000000000000000000000000000
0778827000288330071ffd1000884200002882000888882000288200000000000000000000000000000000000000000000000000000000000000000000000000
071ffd10077ffd700778827008ee8e800333e33308ee8e80088ee883000000000000000000000000000000000000000000000000000000000000000000000000
00288200071882100028820008ee8e8003bb4bb308ee8e8008eeee83000000000000000000000000000000000000000000000000000000000000000000000000
07d882d00028820007d882d00888882008eeee800088420008eeee80000000000000000000000000000000000000000000000000000000000000000000000000
0028820007d882d000dffd0008888820088ee88003bb3bb3088ee880000000000000000000000000000000000000000000000000000000000000000000000000
00dffd0000dffd000000000000222200002882000333033300288200000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000149aa94100000000012222100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00019777aa921000000029aaaa920000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d09a77a949920d00d0497777aa920d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0619aaa9422441600619a77944294160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07149a922249417006149a9442244160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07d249aaa9942d7006d249aa99442d60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
067d22444422d760077d22244222d770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d666224422666d00d776249942677d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
066d51499415d66001d1529749251d10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0041519749151400066151944a151660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00a001944a100a0000400149a4100400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000049a400090000a0000000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100003455032550305502e5502b550285502555022550205501b55018550165501355011550010000f5500c5500a5500855006550055500455003550015500055000000000000000000000000000100000000
000100002b650366402d65025650206301d6201762015620116200f6100d6100a6100761005610046100361002610026000160000600006000060000600006000000000000000000000000000000000000000000
00010000377500865032550206300d620085200862007620056100465004610026000260001600006200070000700006300060001600016200160001600016200070000700007000070000700007000070000700
000100000961025620006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
01050000010501605019050160501905001050160501905016050190601b0611b0611b061290001d0001700026000350002d000250001f0002900030000000000000000000000000000000000000000000000000
01050000205401d540205401d540205401d540205401d540225402255022550225502255000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500001972020720227201b730207301973020740227401b7402074022740227402274000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001f5501f5501b5501d5501d550205501f5501f5501b5501a5501b5501d5501f5501f5501b5501d5501d550205501f5501b5501a5501b5501d5501f5502755027550255502355023550225502055020550
011000000f5500f5500a5500f5501b530165501b5501b550165500f5500f5500a5500f5500f5500a550055500a5500e5500f5500f550165501b5501b550165501755017550125500f5500f550125501055010550
011000001e5501c5501c550175501e5501b550205501d550225501e55023550205501c55026550265500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000017550145501455010550175500b550195500d5501b5500f5501c550105500455016550165500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090d00001b0301b0001b0201d0201e0302003020040200401b7001d700227001a7001b7001b700227001b7001b7001d7001b7001b7001b7001d700227001a7001b7001b700167001b7001b7001b7001c7001c700
050d00001f5301f0001f52021520225302453024530245301e7001e70020700237002070022700227001670000000000000000000000000000000000000000000000000000000000000000000000000000000000
010d000022030220002203024030250302703027030270301b0001b0001b0001d0001e00020000200002000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4d1000002b0202b0202b0202b0202b0202b0202b0202b0202b020290202b0202c0202b0202b0202b0202602026020260202702027020270202b0202b0202b0202a0302a0302a0302703027030270302003020030
4d1000002003028030280302c0302a0302a0302a0302703027030270302c0302a030290302e0302e0300000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010f00001e050000001e0501d0501b0501a0601a0621a062000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
050f00001b540070001b5401a54018540175501755217562075000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001b50018500185001b5001f5002250022500225001f5001d5001b5001b5001b5001d50024500295001b50018500185001b5002b50029500245001f5001b50018500185001b50000500005000050000500
001000000a5030000000000000000a5030a50000000000000a5030000009500000000a5030000000000075000a5030000000000000000a5030000000000000000a5030000000000000000a503000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5803000033552305522e5522b5522755227542245421f5421d5421b54218542165421654213532115320f5320f5320c5320c5320a5320a5220752207522055220352203522005220851206512045120251200512
__music__
04 04050644
00 07084749
04 090a484a
04 0b0c0d44
00 0e084344
04 0f0a4344
04 10114e44

