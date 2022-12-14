pico-8 cartridge // http://www.pico-8.com
version 38
__lua__
-- init

function _init()
 t=0
 blinkt=1
 btn_lockout=0
 shake=0
 
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
			hp=2,
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
			end,
			shoot=function(self)
				aim_fire(self,2)
			end
		},
		{ -- spinning ship
			hp=4,
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
			hp=20,
			spr=208,
			ani=split"208,210",
			spr_width=2,
			col_width=16,
			atk=function(self)
				self.sy=0.4
				
				if self.y>110 then
					self.sy=1
					return
				end
				
				if t%30==0 then
					fire_spread(
						self,
						12,
						2,
						rnd()
					)
				end
			end,
			shoot=function(self)
				fire_spread(
					self,
					12,
					2,
					rnd()
				)
			end
		},
		boss
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
				split"1,1,2,2,2,2,2,2,1,1",
				split"1,1,2,2,2,2,2,2,1,1",
				split"1,1,2,2,1,1,2,2,1,1",
				split"1,1,1,1,1,1,1,1,1,1"
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
				split"0,0,0,0,4,0,0,0,0,0",
				split"0,0,0,0,0,0,0,0,0,0"
			}
		},
		{
			freq=40,
			pattern={
				split"0,0,0,0,5,0,0,0,0,0"
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
	shake_screen()
	drw()
	camera()
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
	wave=4
	next_wave()
	
	ship=make_obj{
		x=64,
		y=64,
		sx=0,
		sy=0,
		spr=2,
		spr_width=1
	}
	
	lives=3
	score=0
	invul=0
	muzzle=0
	cherry=8
	
	flame_spr=5
	
	bullets={}
	bullet_timer=0
	
	next_fire=0
	
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
	
	pick_ups={}
	
	floaters={}
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
	if a.y>b.y+b.col_height-1 then
		return false
	end
	if b.y>a.y+a.col_height-1 then
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

function small_shwave(x,y,col)
	add(shock_waves,{
		x=x,
		y=y,
		color=col or 9,
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
	obj.spr_height=val.spr_height
		or obj.spr_width
	obj.ani_frame=1
	obj.ani_spd=0.4
	obj.col_width=val.col_width
		or 8
	obj.col_height=val.col_height
		or obj.col_width
	
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

function shake_screen()
	local x=rnd(shake)-(shake/2)
	local y=rnd(shake)-(shake/2)
	
	camera(x,y)
	
	shake=shake<1
		and 0
		or shake*0.9
end

function pop_floater(txt,x,y)
	add(floaters,{
		x=x,
		y=y,
		txt=txt,
		age=0
	})
end

function center_print(txt,x,y,c)
	print(txt,x-#txt*2,y,c)
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
	if btnp(❎) then
		if cherry>0 then
			cherry_bomb()
			cherry=0
		else
			sfx(32)
		end
	end
	if btn(🅾️) then
		if bullet_timer<=0 then
			add(bullets,make_obj{
				x=ship.x+2,
				y=ship.y-4,
				sy=-4,
				spr=16,
				col_width=5,
				dmg=1
			})
			sfx(0)
			muzzle=5
			bullet_timer=4
		end
	end
	
	bullet_timer-=1
	
	foreach(bullets,function(b)
		move(b)
		
		foreach(enemies,function(e)
			if has_collision(e,b) then
				del(bullets,b)
				e.hp-=b.dmg
				sfx(3)
				e.flash=e.hit_flash or 2
				small_sparks(b.x+2,b.y+2)
				small_shwave(b.x+2,b.y+2)
				
				if e.hp<=0 then
					kill_enemy(e)
					score+=1
				end
			end
		end)
		
		if b.y<-8 then
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
	
	foreach(pick_ups,function(p)
		move(p)
		if p.y>128 then
			del(pick_ups,p)
		end
		
		if has_collision(p,ship) then
			del(pick_ups,p)
			pick_up(p)
		end
	end)
	
	foreach(enemies,function(e)
		if e.wait>0 then
			e.wait-=1
		else
			e:mission()
		end
	
		animate(e)
		
		if
			(
				e.mission!=e.fly_in
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
	
	foreach(floaters,function(f)
		
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
		shake=8
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
	center_print(
		"shoot them up!",
		64,
		40,
		7
	)
	center_print(
		"press any key to start",
		64,
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
	
	foreach(pick_ups,function(p)	
		for i=1,15 do
			pal(i,t%4<2 and 14 or 7)
		end
		draw_outline(p)
		pal()
		draw_sprite(p)
	end)
	
	foreach(enemies,function(e)
		if e.flash>0 then
			if e.flashing then
				e:flashing()
			else
				for i=1,15 do
					pal(i,7)
				end
			end
			
			e.flash-=1
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
	
	foreach(floaters,function(f)
		center_print(
			f.txt,
			f.x,
			f.y,
			t%4<2 and 7 or 8
		)
		
		f.y-=0.5
		f.age+=1
		
		if f.age>60 then
			del(floaters,f)
		end
	end)
	
	for i=1,4 do
		spr(
			lives<i and 14 or 13,
			(i-1)*10,
			1
		)
	end
	
	print("score:"..score,46,2,1)
	
	spr(48,110,1)
	print(cherry,120,2,14)
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
	
	if item.bullet_mode then
		spr_x-=2
		spr_y-=2
	end

	spr(
		item.spr,
		spr_x,
		spr_y,
		item.spr_width,
		item.spr_height
	)
end

function draw_gameover()
	draw_game()
	center_print(
		"game over!",
		64,
		40,
		8
	)
	center_print(
		"press any key to restart",
		64,
		80,
		blink()
	)
end

function draw_wave_text()
	draw_game()
	center_print(
		"wave "..wave,
		64,
		40,
		blink()
	)
end

function draw_win()
	draw_game()
	center_print(
		"congratulations",
		64,
		40,
		12
	)
	center_print(
		"press any key to restart",
		64,
		80,
		blink()
	)
end

function draw_outline(sprite)
	local mods={
		{1,0},{-1,0},{0,1},{0,-1}
	}
	
	foreach(mods,function(mod)
		local mx,my=mod[1],mod[2]
		
		spr(
			sprite.spr,
			sprite.x+mx,
			sprite.y+my,
			sprite.spr_width,
			sprite.spr_height
		)
	end)
end
-->8
-- waves and enemies

function spawn_enemy(t,x,y,wait)
	local typ=t or 1
	local stats=enemy_types[typ]

	add(enemies,make_obj {
		x=stats.x or x*1.2-16,
		y=stats.y or y-62,
		hp=stats.hp,
		spr=stats.spr,
		ani=stats.ani,
		spr_width=stats.spr_width,
		spr_height=stats.spr_height,
		col_width=stats.col_width,
		col_height=stats.col_height,
		pos_x=stats.pos_x or x,
		pos_y=stats.pos_y or y,
		mission=stats.fly_in or fly_in,
		wait=wait,
		atk=stats.atk,
		shoot=stats.shoot or shot,
		hit_flash=stats.hit_flash,
		fire_flash=stats.fire_flash,
		flashing=stats.flashing
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
	
	if wave>#wave_patterns then
		music(4)
		btn_lockout=t+30
		return mode"win"
	end
	
	music(wave==1 and 0 or 3)
	
	mode"wave_text"
	wavetime=80
end
-->8
-- behavior

function fly_in(en)
	en.x+=(en.pos_x-en.x)/6
	en.y+=(en.pos_y-en.y)/7
	
	if abs(en.y-en.pos_y)<0.5 then
		en.y=en.pos_y
		en.x=en.pos_x
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
	
	if(m!="game") return
	
	if t>next_fire then
		pick_shooter()
		next_fire=t+20+rnd(20)
	end
	
	if(t%freq==0) pick_attac()
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
		enemy.ani_spd*=2
		enemy.wait=20
		enemy.shake=60
		enemy.mission=attac
	end
end

function pick_shooter()
	local index=flr(rnd(
		min(10,#enemies)
	))
	index=#enemies-index

	local enemy=enemies[index]
	if
		enemy
		and enemy.mission==protec
	then
		enemy:shoot()
	end
end

function move(obj)
	obj.x+=obj.sx
	obj.y+=obj.sy
end

function shot(en)
	fire(en,1,2)
end

function kill_enemy(en)
	sfx(1)
	del(enemies,en)
	explode(en.x+4,en.y+4)
	
	local drop_chance=0.09
	
	if en.mission==attac then
		if (rnd()<0.5) pick_attac()
		
		drop_chance=0.18
	end
	
	if rnd()<drop_chance then
		drop_pick_up(en.x,en.y)
	end
end

function drop_pick_up(x,y)
	add(pick_ups,make_obj{
		x=x,
		y=y,
		sy=0.75,
		spr=48
	})
end

function pick_up(p)
	cherry+=1
	small_shwave(
		p.x+4,
		p.y+4,
		14
	)
	
	if cherry<10 then
		sfx(30)
		return
	end
	
	cherry=0
	if lives<4 then
		lives+=1
		sfx(31)
		pop_floater(
			"1up!",
			p.x+4,
			p.y+4
		)
	else
		score+=10
	end
end
-->8
-- bullets

function fire(en,ang,spd)
	en.flash=en.fire_flash or 4
	
	sfx(29)
	return add(
		en_bullets,
		make_obj{
			x=en.x+(en.col_width/2)-1,
			y=en.y+en.col_width-2,
			sx=sin(ang)*spd,
			sy=cos(ang)*spd,
			spr=32,
			ani={32,33,34,33},
			ani_spd=0.5,
			col_width=2,
			bullet_mode=true
		}
	)
end

function fire_spread(
	en,num,spd,base
)
	base=base or 0
	for i=1,num do
		fire(en,1/num*i+base,spd)
	end
end

function aim_fire(en,spd)
	local bult=fire(en,ang,spd)
	
	local ang=atan2(
		(ship.y+4)-bult.y,
		(ship.x+4)-bult.x
	)
	
	bult.sx=sin(ang)*spd
	bult.sy=cos(ang)*spd
end

function cherry_bomb()
	local spacing=0.25/(cherry*2)

	for i=0,cherry*2 do
		local ang=0.375+spacing*i
		
		add(bullets,make_obj{
			x=ship.x+2,
			y=ship.y-4,
			sx=sin(ang)*4,
			sy=cos(ang)*4,
			spr=17,
			dmg=3
		})
	end
	
	big_shwave(ship.x+3,ship.y+3)
	shake=5
	muzzle=5
	invul=30
	sfx(33)
end
-->8
-- boss

boss={
	x=48,
	y=-24,
	pos_x=48,
	pos_y=25,
	
	hp=200,
	spr=68,
	ani=split"68,72,76,72",
	spr_width=4,
	spr_height=3,
	col_width=32,
	col_height=24,
	hit_flash=6,
	fire_flash=0
}

function boss.fly_in(en)
	local dx=(en.pos_x-en.x)/6
	local dy=(en.pos_y-en.y)/7

	en.y+=min(dy,1.5)
	
	if
		abs(en.y-en.pos_y)<0.5
	then
		en.y=en.pos_y
		en.x=en.pos_x
		en.mission=boss.phase_1
	end
end

function boss.atk()
	
end

function boss.shoot(self)
	fire_spread(
		self,
		12,
		2,
		rnd()
	)
end

function boss.flashing(self)
	if t%4<2 then
		pal(3,8)
		pal(11,14)
	end
	
	self.spr=64
end

function boss.phase_1(self)
	if t%15==0 then
		fire(self,0,2)
	end
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
09900000002222000000000000000000000000000330033003300330033003300330033000000000000000000000000000000000000000000000000000000000
97790000029999200000000000000000000000003bb33bb33bb33bb33bb33bb33bb33bb300000000000000000000000000000000000000000000000000000000
9779000029aaaa920000000000000000000000003bbbbbb33bbbbbb33bbbbbb33bbbbbb300000000000000000000000000000000000000000000000000000000
9aa9000029a77a920000000000000000000000003b7717b33b7717b33b7717b33b7717b300000000000000000000000000000000000000000000000000000000
9aa9000029a77a920000000000000000000000000b7117b00b7117b00b7117b00b7117b000000000000000000000000000000000000000000000000000000000
9aa9000029aaaa920000000000000000000000000037730000377300003773000037730000000000000000000000000000000000000000000000000000000000
09900000029999200000000000000000000000000303303003033030030330300303303000000000000000000000000000000000000000000000000000000000
00000000002222000000000000000000000000000300003033000033300000030330033000000000000000000000000000000000000000000000000000000000
00ee000000ee00000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e22e0000e88e00007aa700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e2e82e00e8e28e007a79a70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e2882e00e8228e007a99a70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e22e0000e88e00007aa700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ee000000ee00000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00033330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00300300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00300880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08808788000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
87880888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88880880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000ee00000bbbbbbbb00000ee0000000000ee00000bbbbbbbb00000ee0000000000ee00000bbbbbbbb00000ee0000000000ee00000bbbbbbbb00000ee00000
ee0008e7e1bbbbbaabbbbb1e7e8000eeee0008e7e1bbbbbaabbbbb1e7e8000eeee0008e7e1bbbbbaabbbbb1e7e8000eeee0008e7e1bbbbbaabbbbb1e7e8000ee
e7e0138873bbbaa77aabbb3788310e7ee7e0138873bbbaa77aabbb3788310e7ee7e0138873bbbaa77aabbb3788310e7ee7e0138873bbbaa77aabbb3788310e7e
8e783b333bbabaa77aababb333b387e88e783b333bbabaa77aababb333b387e88e783b333bbabaa77aababb333b387e88e783b333bbabaa77aababb333b387e8
08e813bbbbbbbba77abbbbbbbb318e8008e813bbbbbbbbbaabbbbbbbbb318e8008e813bbbbbbbbbaabbbbbbbbb318e8008e813bbbbbbbbbaabbbbbbbbb318e80
088811bbbbbbbbbaabbbbbbbbb11888008881133b33bbbbbbbbbb33b3311888008881133b33bbbbbbbbbb33b3311888008881133b33bbbbbbbbbb33b33118880
0011133bbbbb33bbbb33bbbbb331110000113b11bbb3333333333bbb11b3110000113b11bbb3333333333bbb11b3110000113b11bbb3333333333bbb11b31100
00bb113bbabbb33bb33bbbabb311bb0000bb13bb13bbb333333bbb31bb31bb0000bb13bb13bbb333333bbb31bb31bb0000bb13bb13bbb333333bbb31bb31bb00
bb333113bbabbbbbbbbbbabb311333bbbb3331333333bba77abb3333331333bbbb3331333333bba77abb3333331333bbbb3331333333bba77abb3333331333bb
bbbb31333bbaa7bbbb7aabb33313bbbbb7713ee6633333bbbb3333366ee3177bb7713ee6633333bbbb3333366ee3177bb7713ee6633333bbbb3333366ee3177b
3b333313333bbb7777bbb333313333b337113eefff663333333366fffee3117337113eefff663333333366fffee3117337113eefff663333333366fffee31173
c333333bb33333bbbb33333bb333333cc3773efff77f17711111f77fffe3773cc3773efff77f17711111f77fffe3773cc3773efff77f17711111f77fffe3773c
0c3bb3b3bbb3333333333bbb3b3bb3c00c3b3eff777717711c717777ffe3b3c00c3b3eff777717711c717777ffe3b3c00c3b3eff777717711c717777ffe3b3c0
00c1bb3b33bbbb3333bbbb33b3bb1c0000c1b3ef7777711cc7177777fe3b1c0000c1b3ef7777711cc7177777fe3b1c0000c1b3ef7777711cc7177777fe3b1c00
00013bb3bb333bbbbbb333bb3bb3100000013b3eff777711117777ffe3b3100000013b3eff777711117777ffe3b3100000013b3eff777711117777ffe3b31000
0331c3bb33aaa333333aaa33bb3c13300331c3b3eef7777777777fee3b3c13300031c3b3eef7777777777fee3b3c13000031c3b3eef7777777777fee3b3c1300
3bb31c3bbb333a7777a333bbb3c13bb33bb31c3b33eee777777eee33b3c13bb303b31c3b33eee777777eee33b3c13b30003b1c3b33eee777777eee33b3c1b300
3ccc13c3bbbbb333333bbbbb3c31ccc33ccc13c3bb333eeeeee333bb3c31ccc33bcc13c3bb333eeeeee333bb3c313cb303bc13c3bb333eeeeee333bb3c31cb30
00003b3c33bbbba77abbbb33c3b3000000003b3c33bbb333333bbb33c3b300003c003b3c33bbb333333bbb33c3b300cc03c0333c33bbb333333bbb33c3330c30
0003b3ccc333bbbbbbbb333ccc3b30000003b3ccc333bba77abb333ccc3b300000003b3cc333bba77abb333cc3b3000000003b3cc333bba77abb333cc3b30000
00033c003bc33bbbbbb33cb300c3300000033c003bc33bbbbbb33cb300c33000000033c03bc33bbbbbb33cb30c33000000003bc03bc33bbbbbb33cb30cb30000
0003c0003b3c3cb22bc3c3b3000c30000003c0003b3c3cb22bc3c3b3000c300000003c003b3c3cb22bc3c3b300c30000000003c0c3bc3cb22bc3cb3c0c300000
0000000033c0cc2112cc0c33000000000000000033c0cc2112cc0c330000000000000000c330cc2112cc033c00000000000000000c30cc2112cc03c000000000
00000000cc0000c33c0000cc0000000000000000cc0000c33c0000cc00000000000000000cc000c33c000cc0000000000000000000cc00c33c00cc0000000000
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
000100003453032530305302e5302b530285302553022530205301b53018530165301353011530010000f5300c5300a5300853006520055200452003520015200052000000000000000000000000000100000000
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
980200001235200302123520533205332053320032204302063020430200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000095660a5760c5460e5460f5560f5561255615556175361b5561d5561e5661f57600500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000800001b55519555115551655515545295352c5652e575305752b50535505305052c505135051b5052250524505005050050500505005050050500505005050050500505005050050500505005050050500505
000400000446003440034400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02020000376673766737667376673866738667386673c6573c6473c6473c6473b64739647386373663733637316372e6372b6372663723637206371c62717627166271262711617106170f6170c6170b61708617
__music__
04 04050644
00 07084749
04 090a484a
04 0b0c0d44
00 0e084344
04 0f0a4344
04 10114e44

