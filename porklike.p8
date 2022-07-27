pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
-- initialization

s=split
function _init()
	-- directions
	dirs_x=s"-1,1,0,0,1,1,-1,-1"
	dirs_y=s"0,0,-1,1,-1,1,1,-1"
	
	dpal=s"0,1,1,2,1,13,6,4,4,9,3,13,1,13,14"
	
	item_name=s"butter knife,cheese knife,paring knife,utility knife,chef's knife,meat cleaver,paper apron,cotton apron,rubber apron,leather apron,chef's apron,butcher's apron,food 1,food 2,food 3,food 4,food 5,food 6,spork,salad fork,fish fork,dinner fork"
	item_type=s"wep,wep,wep,wep,wep,wep,arm,arm,arm,arm,arm,arm,fud,fud,fud,fud,fud,fud,thr,thr,thr,thr"
	item_stat1=s"1,2,3,4,5,6,0,0,0,1,1,2,1,2,3,4,5,6,1,2,3,4"
	item_stat2=s"0,0,0,0,0,0,1,2,3,3,4,3,0,0,0,0,0,0,0,0,0,0"
	item_minf=s"1,2,4,5,7,8,1,2,3,4,5,6,1,1,1,1,1,1,1,2,4,5"
	item_maxf=s"4,5,7,8,10,11,3,4,5,6,7,11,11,11,11,11,11,11,4,7,8,10"
	item_desc=s",,,,,,,,,,,,heals,heals a lot,increases hp,stuns,is cursed,is blessed,,,,"
	
	mob_name=s"player,slime,melt,shoggoth,mantis-man,giant scorpion,ghost,golem,drake"
	mob_sprs=s"240,192,196,200,204,208,212,216,220"
	mob_atk=s"1,1,1,2,2,3,3,4,5"
	mob_hp=s"6,1,2,3,3,4,5,14,8"
	mob_los=s"4,4,4,4,4,4,4,4,4"
	mob_minf=s"0,1,2,4,5,7,7,10,10"
	mob_maxf=s"0,4,5,7,7,10,10,11,11"
	mob_gold=s"0,1,1,2,2,3,5,6,6"
	mob_spec=s",,,spawn,fast,stun,ghost,slow,"	
		
	crv_sigs=s"255,214,124,179,233"
	crv_msks=s"0,9,3,12,6"
	
	free_sig=s"0,0,0,0,16,64,32,128,161,104,84,146"
 free_msk=s"8,4,2,1,6,12,9,3,10,5,10,5"

	wall_sig=s"251,233,253,84,146,80,16,144,112,208,241,248,210,177,225,120,179,0,124,104,161,64,240,128,224,176,242,244,116,232,178,212,247,214,254,192,48,96,32,160,245,250,243,249,246,252"
 wall_msk=s"0,6,0,11,13,11,15,13,3,9,0,0,9,12,6,3,12,15,3,7,14,15,0,15,6,12,0,0,3,6,12,9,0,9,0,15,15,7,15,14,0,0,0,0,0,0"

	final_floor=12
	frames=0
	shake=0
	
	startgame()
end

function _draw()
	shake_screen()
	_drw()
	draw_windows()
	draw_logo()
	check_fade()
end

function _update60()
	frames+=1
	_upd()
	anim_floaters()
	upd_hp_box()
end

function startgame()
	poke(0x3101,194)
	music(0)
	
	tile_ani=0
	fadeperc=1
	
	gold=0
	
	btn_buffer=-1
	
	logo_timer=240
	logo_y=35
	
	skip_ai=false
	win=false
	
	thr_dx,thr_dy=0,-1
	
	--[[
		inventory and equipments
		inv size = 1 to 6
	 eqp[1] = weapon
	 eqp[2] = armor
	]]
	inv,eqp={},{}
	
	-- monsters lists
	mobs={}
	dead_mobs={}

	-- player
	plyr=add_mob(1,1,1)
	anim_timer=0
	
	mk_item_pool()
	
	windows={}
	talk_window=nil
	hp_box=add_window(
		5,5,
		plyr.max_hp<10 and 28 or 32,
		13,{"♥"}
	)

	-- list of floating text
	floaters={}

	_upd=update_game
	_drw=draw_game
	
	st_steps,st_kills,st_meals=0,0,0
	st_killer=""
	
	food_names()
	gen_floor(0)
		
	food_effects={
		function(mob)
			heal_mob(mob,1)
		end,
		
		function(mob)
			heal_mob(mob,3)
		end,
		
		function(mob)
			mob.max_hp+=1
			heal_mob(mob,1)
		end,
		
		stun_mob,
		
		function(mob)
			bless_mob(mob,-1)
		end,
		
		function(mob)
			bless_mob(mob,1)
		end
	}
end
-->8
-- updates

function update_game()
	if talk_window then
		if get_btn()==5 then
			if talk_window.onclose then
				talk_window:onclose()
			end
		
			sfx(53)
			talk_window:close()
			talk_window=nil
		end
		
		return
	end
	
	do_btn_buff()
	
	btn_action()
	btn_buffer=-1
end

function update_inv()
	if
		menu_action(actv_wind)
		and actv_wind==inv_wind
	then
		show_hint()
	end

	if btnp(4) then
		sfx(53)
		actv_wind:cancel()
	elseif btnp(5) then
		sfx(54)
		actv_wind:confirm()
	end
end

function menu_action(wnd)
	local has_moved=false

	if btnp(2) then
		sfx(56)
		wnd.cursor-=1
		has_moved=true
	elseif btnp(3) then
		sfx(56)
		wnd.cursor+=1
		has_moved=true
	end
	wnd.cursor=
		(wnd.cursor-1)%#wnd.text+1

	if (wnd.on_move) wnd:on_move()
		
	return has_moved
end

function update_player_turn()
	do_btn_buff()

	anim_timer=min(
		anim_timer+0.125,1
	)
	
	if (plyr.anim)	plyr:anim()
	
	if anim_timer==1 then
		_upd=update_game
		
		if (trigger_step()) return

		if
			check_end()
			and not skip_ai
	 then
			do_ai()
		end
		
		skip_ai=false
	end
end

function update_throw()
	local bt=get_btn()
	
	if bt>=0 and bt<=3 then
		thr_dx=dirs_x[bt+1]
		thr_dy=dirs_y[bt+1]
	end
	
	if bt==4 then
		_upd=update_game
	elseif bt==5 then
		throw()
	end
end

function update_ai_turn()
	do_btn_buff()

	anim_timer=min(
		anim_timer+0.125,1
	)
	
	foreach(mobs,function(mob)
		if
			mob!=plyr and mob.anim
		then
			mob:anim()
		end	
	end)
	
	if anim_timer==1 then
		_upd=update_game
		if check_end() then
			if plyr.stun then
				plyr.stun=false
				do_ai()
			end
		end
	end
end

function update_gameover()
	if btnp(❎) then
		sfx(54)
		fadeout()
		startgame()
	end
end

function do_btn_buff()
	if btn_buffer==-1 then
		btn_buffer=get_btn()
	end
end

function get_btn()
	for i=0,5 do
		if btnp(i) then
			return i
		end
	end
	return -1
end

function btn_action()
	if (btn_buffer<0) return
	
	if logo_timer>0 then
		logo_timer=0
	end
	
	if btn_buffer<4 then
		move_player(
			dirs_x[btn_buffer+1],
			dirs_y[btn_buffer+1]
		)
	elseif btn_buffer==5 then
		sfx(54)
		show_inv()
	end
end
-->8
-- draws

function draw_game()
	cls(0)
	
	if (fadeperc==1) return
	
	anim_map()
	map()
	
	foreach(dead_mobs,
		function (m)
			if
				sin(time()*8)>0
				or m==plyr
			then
				draw_mob(m)
			end
			
			m.dur-=1
			
			if m.dur<=0 and m!=plyr then
				del(dead_mobs,m)
			end
		end
	)
	
	for i=#mobs,1,-1 do
		draw_mob(mobs[i])
	end
	
	if _upd==update_throw then
		local tx,ty=throw_tile()
		local lx1,ly1=
			plyr.x*8+3+thr_dx*4,
			plyr.y*8+3+thr_dy*4
		local lx2,ly2=
			mid(0,tx*8+3,127),
			mid(0,ty*8+3,127)
		
		rectfill(
			lx1+thr_dy,ly1+thr_dx,
			lx2-thr_dy,ly2-thr_dx,0
		)
		
		local thrani=flr(frames/7)%2==0
		fillp(thrani
			and 0b1010010110100101
			or 0b0101101001011010
		)

		line(lx1,ly1,lx2,ly2,7)
		
		fillp()
		
		outline_print(
			"+",lx2-1,ly2-2,7,0
		)
		
		local mb=get_mob(tx,ty)
		
		if mb and thrani then
			mb.flash=1
		end
	end
	
	for x=0,15 do
		for y=0,15 do
			if fog[x][y]==1 then
				draw_rect(x*8,y*8,8,8,0)
			end
		end
	end
	
	foreach(floaters,function(fl)
		outline_print(
			fl.txt,fl.x,fl.y,fl.clr,0
		)
	end)
end

function draw_logo()
	if logo_y>-24 then
		logo_timer-=1
		
		if logo_timer<=0 then
			logo_y+=logo_timer/20
		end
		
		palt(12,true)
		palt(0,false)
		spr(144,7,logo_y,14,3)
		palt()
		
		outline_print(
			"the quest for kielbasa",
			19,logo_y+20,7,0
		)
	end
end

function draw_mob(mob)
	local clr=10
		
	if mob.flash>0 then
		mob.flash-=1
		clr=7
	end

	draw_sprite(
		get_frame(mob.sprt),
		mob.x*8+mob.ox,
		mob.y*8+mob.oy,
		clr,mob.flipped
	)
end

function draw_win()
	cls(2)
	print("u win",50,50,7)
end

function draw_gameover()
	cls()
	
	palt(12,true)
	spr(
		gameover_spr,gameover_x,
		30,gameover_w,2
	)
	palt()
	
	if not win then
		print(
			"killed by a "..st_killer,
			28,43,6
		)
	end
	
	color(5)
	cursor(40,56)
	
	if not win then
		print("floor: "..floor)
	end
	
	print("steps: "..st_steps)
	print("kills: "..st_kills)
	print("meals: "..st_meals)
	
	print(
		"press ❎",40,90,
		5+abs(sin(time()/3)*2)
	)
end

function anim_map()
	tile_ani+=1
	
	if (tile_ani<15) return
	
	tile_ani=0
	
	in_xy_pairs(function(x,y)
		local tile=mget(x,y)
		
		if tile>=64 and tile<=67 then
			tile=tile%2==0
				and tile+1
				or tile-1
		end
		
		mset(x,y,tile)
	end)
end
-->8
-- tools

function get_frame(start)
	return start+(flr(frames/15)%4)
end

function draw_sprite(
	sprt,x,y,clr,flipped
)
	--makes black not transparent
	palt(0,false)
	
	--turn gray to another color
	pal(6,clr)
	spr(sprt,x,y,1,1,flipped)
	pal()
end

function draw_rect(x,y,w,h,c)
	rectfill(
		x,y,
		x+max(w-1,0),
		y+max(h-1,0),
		c
	)
end

function in_xy_pairs(cb)
	for x=0,15 do
		for y=0,15 do
			cb(x,y)
		end
	end
end

function outline_print(
	txt,x,y,clr1,clr2
)
	for i=1,8 do
		print(
			txt,
			x+dirs_x[i],
			y+dirs_y[i],
			clr2
		)
	end
	print(txt,x,y,clr1)
end

function dist(f_x,f_y,t_x,t_y)
	local dx,dy=f_x-t_x,f_y-t_y
	return sqrt(dx*dx+dy*dy)
end

function fade()
	local p,kmax,col,k=flr(
		mid(0,fadeperc,1)*100
	)
	for j=1,15 do
		col=j
		kmax=flr((p+j*1.46)/22)
		for k=1,kmax do
			col=dpal[col]
		end
		pal(j,col,1)
	end
end

function check_fade()
	if fadeperc>0 then
		fadeperc=max(fadeperc-0.04,0)
		fade()
	end
end

function wait(t)
	repeat
		t-=1
		flip()
	until t<0
end

function fadeout(spd,t)
	spd=spd or 0.04
	t=t or 0
	repeat
		fadeperc=min(fadeperc+spd,1)
		fade()
		flip()
	until fadeperc==1
	wait(t)
end

function blank_map(dflt)
	local ret={}
	dflt=dflt or 0
	
	for x=0,15 do
		ret[x]={}
		for y=0,15 do
			ret[x][y]=dflt
		end
	end
	
	return ret
end

function get_rnd(arr)
	return arr[1+flr(rnd(#arr))]
end

function copy_map(x,y)
	local tile
	
	in_xy_pairs(function(_x,_y)
		tile=mget(_x+x,_y+y)
		mset(_x,_y,tile)
		
		if tile==15 then
			plyr.x,plyr.y=_x,_y
		end
	end)
end

function shake_screen()
	local shake_x,shake_y=16-rnd(32),
		16-rnd(32)
		
	camera(
		shake_x*shake,shake_y*shake
	)
	shake*=0.95
	
	if (shake<0.05) shake=0
end
-->8
-- gameplay

function move_player(dx,dy)
	local dest_x,dest_y=plyr.x+dx,
		plyr.y+dy
	local tile=mget(dest_x,dest_y)
	
	if
		is_walkable(
			dest_x,dest_y,"checkmobs"
		)
	then
		sfx(63)
		mob_walk(plyr,dx,dy)
		st_steps+=1
		
		anim_timer=0
		_upd=update_player_turn
	else
		-- not walkable
		mob_bump(plyr,dx,dy)
		
		anim_timer=0
		_upd=update_player_turn
		
		local mob=get_mob(dest_x,dest_y)
		
		if mob then
			sfx(58)
			hit_mob(plyr,mob)
		else
			if fget(tile,1) then
				trigger_bump(
					tile,dest_x,dest_y
				)
			else
				skip_ai=true
			end		
		end
	end
	
	unfog()
end

function trigger_bump(
	tile,d_x,d_y
)
	if tile==7 or tile==8 then
		-- vase
		sfx(59)
		mset(d_x,d_y,76)
	
		if rnd(3)<1 and floor>0 then
			if not has_inv_slot() then
				show_msg(
					"inventory full",120
				)
				sfx(60)
				
				return
			end
			
			local itm=get_rnd(fipool_com)
			
			sfx(61)
			take_item(itm)
			show_msg(item_name[itm],60)
			
			return
		end
		
		if rnd(3)<1 then
			sfx(61)
			add_gold(1)
			add_floater(
				"+1 gold",
				plyr.x*8-10,
				plyr.y*8,
				7
			)
		end
	elseif tile==10 or tile==12 then
		-- chest
		if not has_inv_slot() then
			show_msg("inventory full",120)
			skip_ai=true
			sfx(60)
			
			return
		end
		
		local itm=get_rnd(fipool_com)
		
		if tile==12 then
			itm=get_rare_item()
		end
		
		sfx(61)
		mset(d_x,d_y,tile-1)
		take_item(itm)
		show_msg(item_name[itm],60)
	elseif tile==13 then
		-- door
		sfx(62)
		mset(d_x,d_y,1)
	elseif tile==6 then
		-- stone tablet
		if floor==0 then
			sfx(54)
			show_talk({
				" welcome to porklike!",
				"",
				" climb this sausage",
				" tower to obtain the",
				" ultimate power of",
				" the golden kielbasa",
				""
			})
			return
		end
		
		if floor%3==0 then
			sfx(54)
			show_talk({
				" offer your money to",
				" the power stone!"
			})
			talk_window.onclose=function()
				show_shop()
			end
		end
	elseif tile==110 then
		-- kielbasa
		win=true
	end
end

function trigger_step()
	local tile=mget(plyr.x,plyr.y)

	if tile==14 then
		sfx(55)
		plyr.bless=0
		fadeout()
		gen_floor(floor+1)
		floor_msg()
		
		return true
	end
	
	return false
end

function get_mob(x,y)
	for m in all(mobs) do
  if m.x==x and m.y==y then
   return m
  end
 end
end

function is_walkable(x,y,mode)
	mode=mode or ""
	if in_bounds(x,y) then
		local tile=mget(x,y)
		
		if mode=="sight" then
			return not fget(tile,2)
		else
			local no_wall=not fget(tile,0)
			
			if
				no_wall
				and mode=="checkmobs"
			then
				return not get_mob(x,y)
			end
			
			return no_wall
		end
	end
end

function in_bounds(x,y)
	return not (x<0 or y<0
		or x>15 or y>15
	)
end

function hit_mob(atk_m,trgt)
	local dmg=atk_m.atk
	
	-- add curse/bless
	if trgt.bless<0 then
		dmg*=2
	elseif trgt.bless>0 then
		dmg=flr(dmg/2)
	end
	
	trgt.bless=0
	
	local def=trgt.defmin+flr(rnd(trgt.defmax-trgt.defmin+1))
	dmg-=min(def,dmg)
	
	trgt.hp-=dmg
	trgt.flash=10
	
	add_floater(
		"-"..dmg,trgt.x*8,trgt.y*8,9
	)
	
	if trgt==plyr then
		shake=0.07
	end
	
	if trgt.hp<=0 then
		if trgt!=plyr then
			st_kills+=1
			add_gold(trgt.gold)
		else
			st_killer=atk_m.name
		end
		
		trgt.dur=13
		add(dead_mobs,trgt)
		del(mobs,trgt)
	end	
end

function add_gold(value)
	gold=min(gold+value,99)
end

function heal_mob(mb,heal)	
	heal=min(mb.max_hp-mb.hp,heal)
	mb.hp+=heal
	mb.flash=10
	
	add_floater(
		"+"..heal,mb.x*8,mb.y*8,7
	)
	sfx(51)
end

function stun_mob(mob)
	mob.stun=true
	mob.charge=mob!=plyr and 1 or 0
	mob.flash=10
	
	add_floater(
		"stun",mob.x*8-3,mob.y*8,7
	)
	
	sfx(51)
end

function bless_mob(mob,value)
	mob.bless=mid(
		-1,1,mob.bless+value
	)
	mob.flash=10
	
	local txt=value<0
		and "curse" or "bless"
	
	add_floater(
		txt,mob.x*8-5,mob.y*8,7
	)
	
	if
		mob.spec=="ghost"
		and value>0
	then
		mob.dur=13
		add(dead_mobs,mob)
		del(mobs,mob)
	end
	
	sfx(51)
end

function check_end()
	if win then
		music(24)
		gameover_spr=112
		gameover_x=15
		gameover_w=13
		show_end()
		
		return false
	end
	
	if (plyr.hp>0) return true

	music(22)
	gameover_spr=80
	gameover_x=28
	gameover_w=9
	show_end()
end

function show_end()
	windows={}
	_upd=update_gameover
	_drw=draw_gameover
	fadeout(0.02)
end

function los(x1,y1,x2,y2)
	local frst,sx,sy,dx,dy=true
	
	if dist(x1,y1,x2,y2)==1 then
		return true
	end
	
	if y1>y2 then
		x1,x2,y1,y2=x2,x1,y2,y1
	end
	
	sy,dy=1,y2-y1
	
	if x1<x2 then
		sx,dx=1,x2-x1
	else
		sx,dx=-1,x1-x2
	end

	local err,e2=dx-dy
	
	while not(x1==x2 and y1==y2) do
		if	
			not frst
			and not is_walkable(
				x1,y1,"sight"
			)
		then return false end
		
		e2,frst=err+err
		
		if e2>-dy then
			err-=dy
			x1+=sx
		end
		
		if e2<dx then
			err+=dx
			y1+=sy
		end
	end
	return true
end

function unfog()
	local px,py=plyr.x,plyr.y

	for x=0,15 do
		for y=0,15 do
			if
				fog[x][y]==1
				and dist(px,py,x,y)<=plyr.los
				and los(px,py,x,y)
			then
				unfog_tile(x,y)
			end
		end
	end
end

function unfog_tile(x,y)
	fog[x][y]=0
	if 
		is_walkable(x,y,"sight")
	then
		for i=1,4 do
			local t_x,t_y=x+dirs_x[i],
				y+dirs_y[i]
		
			if
				in_bounds(t_x,t_y)
				and not is_walkable(
					t_x,t_y,"sight"
				) 
			then
				fog[t_x][t_y]=0
			end
		end	
	end
end

function calc_dist(tx,ty)
	local candits,step,cand_new=
		{},0
	
	dist_map=blank_map(-1)
	add(candits,{tx,ty})
	
	dist_map[tx][ty]=0
	
	repeat
		step+=1
		cand_new={}
		
		foreach(candits,function(c)
			for d=1,4 do
				local dx=c[1]+dirs_x[d]
				local dy=c[2]+dirs_y[d]
				
				if
					in_bounds(dx,dy)
					and dist_map[dx][dy]==-1
				then
					dist_map[dx][dy]=step
					if is_walkable(dx,dy) then
						add(cand_new,{dx,dy})
					end
				end
				
			end
		end)
		
		candits=cand_new
	until #candits==0
end

function upd_stats()
	local atk,dmin,dmax=
		item_stat1[eqp[1]] or 0,
		item_stat1[eqp[2]] or 0,
		item_stat2[eqp[2]] or 0

	plyr.atk=plyr.base_atk+atk
	plyr.defmin=dmin
	plyr.defmax=dmax
end

function eat(item,mob)
	local effect=item_stat1[item]
	
	if mob==plyr then
		st_meals+=1
	end
	
	if not item_known[item] then
		item_known[item]=true
		show_msg(
			item_name[item].." "..
			item_desc[item],
			120
		)
	end

	food_effects[effect](mob)
end

function throw()
	local itm,tx,ty=inv[thrslt],
		throw_tile()

	if in_bounds(tx,ty) then
		local mb=get_mob(tx,ty)
		
		sfx(52)
		
		if mb then
			if item_type[itm]=="fud" then
				eat(itm,mb)
			else
				hit_mob({
					atk=item_stat1[itm]
				},mb)
				sfx(58)
			end
		end
	end

	mob_bump(plyr,thr_dx,thr_dy)

	inv[thrslt]=nil
	anim_timer=0
	_upd=update_player_turn
end

function throw_tile()
	local tx,ty=plyr.x,plyr.y
	
	repeat
		tx+=thr_dx
		ty+=thr_dy
	until not is_walkable(
		tx,ty,"checkmobs"
	)
	
	return tx,ty
end
-->8
-- ui

item_type_name={
	wep="weapon",
	arm="armor",
	fud="food",
	thr="throwable"
}

item_type_value={
	wep=8,
	arm=8,
	fud=4,
	thr=6
}

function item_type_value
	.from_inv(pos)
	return item_type_value[
		item_type[inv[pos]]
	]
end

function add_window(
	x,y,width,height,txt,cur
)
	return add(windows,{
		x=x,
		y=y,
		width=width,
		height=height,
		text=txt,
		cursor=cur or nil,
		close=function(w)
			w.dur=0
		end
	})
end

function draw_windows()
	foreach(windows,
		function(w)
			local w_x,w_y,w_w,w_h=
				w.x,w.y,w.width,w.height
			
			draw_rect(
				w_x,w_y,w_w,w_h,0
			)
			rect(
				w_x+1,w_y+1,w_x+w_w-2,
				w_y+w_h-2,6
			)
			
			w_x+=4
			w_y+=4
			
			clip(w_x,w_y,w_w-8,w_h-8)
			
			if w.cursor then
				w_x+=6
			end
			
			for i=1,#w.text do
				local txt,clr=w.text[i],6
				
				if w.col and w.col[i] then
					clr=w.col[i]
				end
			
				print(txt,w_x,w_y,clr)
				
				if i==w.cursor then
					spr(
						255,w_x-4.1+sin(time()),
						w_y
					)
				end
				
				w_y+=6
			end
			
			clip()
			
			if w.dur then
				w.dur-=1
				
				if w.dur<=0 then
					local diff=w_h/4
					w.y+=diff/2
					w.height-=diff
					
					if w_h<3 then
						del(windows,w)
					end
				end
			else
				if w.btn then
					outline_print(
						"❎",w_x+w_w-15,
						w_y-0.9+sin(time()),6,0
					)
				end
			end
		end
	)
end

function show_msg(txt,dur)
	local width=(#txt+2)*4+7
	local wind=add_window(
		63-width/2,50,width,
		13,{" "..txt}
	)
	wind.dur=dur
end

function show_talk(txt)
	talk_window=add_window(
		16,50,94,#txt*6+7,txt
	)
	talk_window.btn=true
end

function add_floater(
	txt,x,y,clr
)
	add(floaters,{
		txt=txt,
		x=x,
		y=y,
		clr=clr,
		trg_y=y-10,
		timer=0
	})
end

function anim_floaters()
	foreach(floaters,function(flt)
		flt.y+=(flt.trg_y-flt.y)/10
		flt.timer+=1
		if flt.timer>70 then
			del(floaters,flt)
		end
	end)
end

function upd_hp_box()
	hp_box.text[1]=
		"♥"..plyr.hp.."/"
		..plyr.max_hp
	local y=5
	if plyr.y<8 then
		y=110
	end
	hp_box.y+=(y-hp_box.y)/5
end

shop_prices=s"15,25,25"
shop_buy_events={
	function()
		heal_mob(plyr,1)
		show_msg("healed 1 hp!",60)
	end,
	function()
		shop_prices[2]+=5
		sfx(51)
		plyr.max_hp+=1
		show_msg("hp upgrade!",60)
	end,
	function()
		shop_prices[3]+=5
		sfx(51)
		plyr.base_atk+=1
		show_msg("base atk upgrade",60)
	end,
	function()
		shop_wind:set_state(
			shop_sell_state
		)
	end
}

h_by_item_amount=s"13,19,25,31"

shop_sell_state={}

function shop_sell_state.enter()
	shop_title.text[2]="[selling]"
	shop_wind.height=49

	shop_wind:on_move()
end

function shop_sell_state.on_move()
	show_gold()
	shop_wind.text={}

	for i=1,6 do
		add(
			shop_wind.text,
			inv[i]
				and item_name[inv[i]]
				or "..."
		)
	end
	
	add(shop_wind.text,"[back]")
	
	if sell_item_wind then
		sell_item_wind:close()
	end
	
	if inv[shop_wind.cursor] then
		sell_item_wind=add_window(
			26,shop_wind.height+39,
			74,13,{
				"sell price: "..
				item_type_value.from_inv(
					shop_wind.cursor
				)
		})
	end
end

function shop_sell_state.confirm()
	local cur=shop_wind.cursor
		
	if cur==7 then
		return shop_wind:cancel()
	end
	
	if inv[cur] then
		show_confirm(function()
			gold+=item_type_value
				.from_inv(cur)
			inv[cur]=nil
		end)
	end
end

function shop_sell_state.cancel()
	shop_wind:set_state(
		shop_buy_state
	)
	if sell_item_wind then
		sell_item_wind:close()
	end
end

function show_confirm(
	on_confirm
)
	del(windows,confirm_wind)
	
	confirm_wind=add_window(
		80,40,43,19,
		{"confirm","cancel"},
		1
	)
	
	function confirm_wind.confirm()
		if confirm_wind.cursor==1 then
			on_confirm()
		end
		
		confirm_wind:cancel()
	end
	
	function confirm_wind.cancel()
		confirm_wind:close()
		actv_wind=shop_wind
	end
	
	actv_wind=confirm_wind
end

shop_buy_state={}

function shop_buy_state.enter()
	shop_title.text[2]="[buying]"
	shop_wind.height=31
	shop_wind.text={
		"heals : "..shop_prices[1]..
			" gold",
		"hp up : "..shop_prices[2]..
			" gold",
		"atk up: "..shop_prices[3]..
			" gold",
		"[sell items]"
	}
end

function shop_buy_state.on_move()
end

function shop_buy_state.confirm()
	local price=shop_prices[
		shop_wind.cursor
	]
	
	if not price then
		return shop_buy_events[
			shop_wind.cursor
		]()
	end

	if gold<price then
		return show_msg(
			"not enough gold!",60
		)
	end
	
	show_confirm(function()
		if gold>=price then
			gold=max(gold-price,0)
			show_gold()
			
			shop_buy_events[
				shop_wind.cursor
			]()
		end
	end)
end

function shop_buy_state.cancel()
	shop_title:close()
	shop_wind:close()
	gold_wind:close()
	_upd=update_game
end

function show_shop()
	del(windows,shop_wind)
	
	shop_title=add_window(
		26,21,74,19,{"power stone"}
	)
	shop_wind=add_window(
		26,40,74,31,{},1
	)

	function shop_wind.set_state(
		self,new_state
	)
		self.state=new_state
		self.state:enter()
	end
	
	function shop_wind.on_move()
		shop_wind.state:on_move()
	end
	
	function shop_wind.confirm()
		shop_wind.state:confirm()
	end
	
	function shop_wind.cancel()
		shop_wind.state:cancel()	
	end
	
	shop_wind:set_state(
		shop_buy_state
	)
	
	show_gold()
	
	actv_wind=shop_wind
	_upd=update_inv
end

function show_gold()
	del(windows,gold_wind)
	gold_wind=add_window(
		88,5,36,13,{"gold:"..gold}
	)
end

function show_inv()
	local txt,col={},{}
	
	for i=1,2 do
		local item,eqtxt=eqp[i]
		if item then
			eqtxt=item_name[item]
		else
			eqtxt=i==1
				and "[weapon]"
				or "[armor]"
		end
		add(txt,eqtxt)
		add(col,item and 6 or 5)
	end
	
	add(txt,"…………………")
	add(col,6)
	
	for i=1,6 do
		local item=inv[i]
		add(txt,item
			and item_name[item]
			or "..."
		)
		add(col,item and 6 or 5)
	end
	
	del(windows,inv_wind)
	del(windows,stat_wind)

	show_gold()
	inv_wind=add_window(
		5,17,84,62,txt,3
	)
	inv_wind.col=col
	
	txt="ok    "
	
	if plyr.bless<0 then
		txt="curse "
	elseif plyr.bless>0 then
		txt="bless "
	end
	
	stat_wind=add_window(
		5,5,84,13,{
			txt..
			"atk:"..plyr.atk..
			" def:"..plyr.defmin..
			"-"..plyr.defmax
		}
	)
	inv_wind.confirm=show_use
	
	function inv_wind.cancel()
		_upd=update_game
		inv_wind:close()
		stat_wind:close()
		gold_wind:close()
		if (hint_wind) hint_wind:close()
	end
	
	actv_wind=inv_wind
	_upd=update_inv
	
	show_hint()
end

typ_map={
	wep="equip,throw",
	arm="equip",
	fud="eat,throw",
	thr="throw"
}

function show_use()
	local txt,i={},inv_wind.cursor
	local item=i<3
		and eqp[i] or inv[i-3]
		
	if (not item) return	

	local typ=item_type[item]
	
	foreach(
		split(typ_map[typ]),
		function(act)
			add(txt,act)
		end
	)
	
	add(txt,"trash")

	use_menu=add_window(
		84,i*6+11,36,7+#txt*6,txt,1
	)
	
	use_menu.confirm=trigger_use
	function use_menu.cancel()
		use_menu:close()
		actv_wind=inv_wind
	end

	actv_wind=use_menu
end

function trigger_use()
	local cur,action,back=
		inv_wind.cursor,
		use_menu.text[use_menu.cursor],
		true
	local i=cur-3
	local item=cur<3
		and eqp[cur] or inv[i]
	
	if action=="trash" then
		if cur<3 then
			eqp[cur]=nil
		else
			inv[i]=nil
		end
	elseif action=="equip" then
		local id=item_type[item]=="wep"
			and 1 or 2
		
		inv[i]=eqp[id]
		eqp[id]=item
	elseif action=="eat" then
		eat(item,plyr)
		inv[i]=nil
		plyr.anim=nil
		back=false
		anim_timer=0
		_upd=update_player_turn
	elseif action=="throw" then
		thrslt=i
		back=false
		_upd=update_throw
	end

	upd_stats()
	use_menu:close()

	if back then
		show_inv()
		inv_wind.cursor=cur
	else
		inv_wind:close()
		stat_wind:close()
		gold_wind:close()
		if hint_wind then
			hint_wind:close()
		end
	end
end

function floor_msg()
	show_msg("floor "..floor,120)
end

function show_hint()
	if hint_wind then
		hint_wind:close()
		hint_wind=nil
	end
	
	local cur=inv_wind.cursor
	local item=cur<3
		and eqp[cur] or inv[cur-3]
	local typ=item_type[item]
	
	if item then
		local item_hint_type={
			wep="damage of "..
				item_stat1[item],
			arm="defense range of "..
				item_stat1[item].." to "..
				item_stat2[item],
			thr="damage of "..
				item_stat1[item],
		}
		
		local txt=item_hint_type[typ]
	
		if typ=="fud" then
			txt=item_known[item]
				and "it "..item_desc[item]
				or "???"
		end
			
		hint_wind=add_window(
			5,78,max(#txt*4+7,50),
			20,{
				item_type_name[typ],
				txt
		})
	end
end
-->8
-- monsters and items

function add_mob(typ,x,y)
	return add(mobs,{
		x=x,
		y=y,
		ox=0,
		oy=0,
		sprt=mob_sprs[typ],
		name=mob_name[typ],
		flash=0,
		flipped=false,
		hp=mob_hp[typ],
		max_hp=mob_hp[typ],
		atk=mob_atk[typ],
		base_atk=1,
		defmin=0,
		defmax=0,
		bless=0,
		stun=false,
		charge=1,
		spec=mob_spec[typ],
		gold=mob_gold[typ],
		los=mob_los[typ],
		task=ai_wait
	})
end

function mob_walk(mob,d_x,d_y)
	mob.x+=d_x
	mob.y+=d_y
			
	mob_flip(mob,d_x)
	mob.sox,mob.soy=-d_x*8,-d_y*8
	mob.ox,mob.oy=mob.sox,mob.soy
	
	mob.anim=walk_anim
end

function mob_bump(mob,d_x,d_y)
	mob_flip(mob,d_x)
	mob.sox,mob.soy=d_x*8,d_y*8
	mob.ox,mob.oy=0,0
					
	mob.anim=bump_anim
end

function mob_flip(mob,d_x)
	mob.flipped=d_x==0
		and mob.flipped
		or d_x<0
end

function walk_anim(self)
	local t=1-anim_timer
	self.ox=self.sox*t
	self.oy=self.soy*t
end

function bump_anim(self)
	local t=anim_timer>0.5
		and 1-anim_timer
		or anim_timer
	
	self.ox=self.sox*t
	self.oy=self.soy*t
end

function do_ai()
	local moving
	foreach(mobs,function(m)
		if (m==plyr) return
		
		m.anim=nil
		
		if m.stun then
			if m.charge>0 then
				m.charge-=1
				return
			end
			
			m.stun=false
			m.charge=1
		else
			m.lastmoved=m:task()
			moving=m.lastmoved or moving
		end
	end)
	
	if moving then
		_upd=update_ai_turn
		anim_timer=0
	end
end

function ai_wait(m)
	if can_see(m,plyr)	then
		-- aggro
		m.task=ai_attack
		m.tx,m.ty=plyr.x,plyr.y
		add_floater(
			"!",m.x*8+2,m.y*8,10
		)
		return true
	end
end

function ai_attack(m)
	if dist(
			m.x,m.y,plyr.x,plyr.y
		)==1
	then
		-- attack player
		local dx,dy=plyr.x-m.x,
			plyr.y-m.y
			
		mob_bump(m,dx,dy)

		if
			m.spec=="stun"
			and m.charge>0
		then
			m.charge-=1
			stun_mob(plyr)
		elseif
			m.spec=="ghost"
			and m.charge>0
		then
			hit_mob(m,plyr)
			m.charge-=1
			bless_mob(plyr,-1)
		else
			hit_mob(m,plyr)
		end
		
		sfx(57)
		return true
	else
		-- move to player
		if can_see(m,plyr) then
			m.tx,m.ty=plyr.x,plyr.y
		end
		
		if m.x==m.tx and m.y==m.ty then
			-- de aggro
			m.task=ai_wait
			add_floater(
				"?",m.x*8+2,m.y*8,10
			)
		else
			if
				m.spec=="slow"
				and m.lastmoved
			then				
				return
			end
		
			local best_dst=99
			local best_cand={}
			
			calc_dist(m.tx,m.ty)
			
			for i=1,4 do
				local dx,dy=dirs_x[i],dirs_y[i]
				local t_x,t_y=m.x+dx,m.y+dy
			
				if is_walkable(
					t_x,t_y,"checkmobs"
				) then
					local dst=dist_map[t_x][t_y]
					
					if dst<best_dst then
						best_cand={}
						best_dst=dst
					end
					
					if dst==best_dst then
						add(best_cand,i)
					end
				end
			end
			
			if #best_cand>0 then
				local c=get_rnd(best_cand)
				mob_walk(
					m,dirs_x[c],dirs_y[c]
				)
								
				return true
			end
		end
	end
end

function can_see(m1,m2)
	return dist(
		m1.x,m1.y,m2.x,m2.y
	)<=m1.los
	and los(m1.x,m1.y,m2.x,m2.y)
end

function spawn_mobs()
	mobs_pool={}
	
	for i=2,#mob_name do
		if mob_minf[i]<=floor
			and mob_maxf[i]>=floor
		then
			add(mobs_pool,i)
		end
	end
	
	if (#mobs_pool==0) return
	
	local min_mobs=split"3,5,0,7,9,0,10,11,0,12,13,0"
	local max_mobs=split"6,10,0,14,18,0,20,22,0,24,26,0"
	local placed,roompot=0,{}
	
	foreach(rooms,function(r)
		add(roompot,r)
	end)
	
	repeat
		local r=get_rnd(roompot)
		
		placed+=infest_room(r)
		del(roompot,r)
	until #roompot==0
		or placed>max_mobs[floor]
	
	if placed<min_mobs[floor] then
		repeat
			local x,y
			
			repeat
				x,y=flr(rnd(16)),flr(rnd(16))
			until is_walkable(
				x,y,"checkmobs"
			) and (
				mget(x,y)==1
				or mget(x,y)==4
			)
			
			add_mob(
				get_rnd(mobs_pool),x,y
			)
			placed+=1
		until placed>=min_mobs[floor]
	end
end

function infest_room(room)
	if room.no_spawn then
		return 0
	end
	
	local total=2+flr(rnd(
		(room.w*room.h)/6-1
	))
	total=min(5,total)
	local x,y
	
	for i=1,total do
		repeat
			x=room.x+flr(rnd(room.w))
			y=room.y+flr(rnd(room.h))
		until is_walkable(
			x,y,"checkmobs"
		) and (
			mget(x,y)==1
			or mget(x,y)==4
		)
		
		add_mob(
			get_rnd(mobs_pool),x,y
		)
	end
	
	return total
end

-- items

function take_item(item_id)
	local slot=has_inv_slot()
	
	if (not slot) return
	
	inv[slot]=item_id
	
	return true
end

function has_inv_slot()
	for i=1,6 do
		if not inv[i] then
			return i
		end
	end
end

function mk_item_pool()
	ipool_rar={}
	ipool_com={}
	
	for i=1,#item_name do
		local t=item_type[i]
		
		add(
			(t=="wep" or t=="arm")
				and ipool_rar
				or ipool_com,
				i
		)
	end
end

function mk_floor_ipool()
	fipool_rar={}
	fipool_com={}
	
	foreach(
		ipool_rar,
		add_floor_items(fipool_rar)
	)
	
	foreach(
		ipool_com,
		add_floor_items(fipool_com)
	)
end

function add_floor_items(table)
	return function(i)
		if
			item_minf[i]<=floor
			and item_maxf[i]>=floor
		then
			add(table,i)
		end
	end
end

function get_rare_item()
	if #fipool_rar>0 then
		local itm=get_rnd(fipool_rar)
		del(fipool_rar,itm)
		del(ipool_rar,itm)
		
		return itm
	end
	
	return get_rnd(fipool_com)
end

function food_names()
	local foods,fu=split"jerky,schnitzel,steak,gyros,fricassee,haggis,mett,kebab,burger,meatball,pizza,calzone,pasticio,chops,hams,ribs,roast,meatloaf,chili,stew,pie,wrap,taco,burrito,rolls,filet,salami,sandwich,casserole,spam,souvlaki"
 local adjs,ad=split"yellow,green,blue,purple,black,sweet,salty,spicy,strange,old,dry,wet,smooth,soft,crusty,pickled,sour,leftover,mom's,steamed,hairy,smoked,mini,stuffed,classic,marinated,bbq,savory,baked,juicy,sloppy,cheesy,hot,cold,zesty"

	item_known={}
	
	for i=1,#item_name do
		if item_type[i]=="fud" then
			fu,ad=get_rnd(foods),
				get_rnd(adjs)
				
			del(foods,fu)
			del(adjs,ad)
			
			item_name[i]=ad.." "..fu
			item_known[i]=false
		end
	end
end
-->8
-- level generation

function gen_floor(num)
	floor=num
	
	mk_floor_ipool()
	mobs={}
	add(mobs,plyr)
	
	fog=blank_map()
	
	if floor==1 then
		st_steeps=0
		poke(0x3101,66)
	end
	
	if floor==0 then
		return copy_map(16,0)
	end
	
	if floor==final_floor then
		return copy_map(32,0)
	end
	
	if floor%3==0 then
		return copy_map(48,0)
	end
	
	fog=blank_map(1)
	map_gen()
	unfog()
end

function map_gen()
	repeat
		in_xy_pairs(function(x,y)
			mset(x,y,2)
		end)
	
		doors={}
		rooms={}
		room_map=blank_map()
		
		gen_rooms()
		mazeworm()
		placeflags()
		carvedoors()
	until #flags_lib==1
	
	carvescuts()
	start_end()
	fill_ends()
	pretty_walls()
	installdoors()

	spawn_chests()
	spawn_mobs()
	decorate_rooms()
end

-- rooms

function gen_rooms()
	local fmax,rmax=5,4
	local mw,mh=10,10

	repeat
		local r=rnd_room(mw,mh)
		
		if place_room(r) then
			if #rooms==1 then
				mw/=2
				mh/=2
			end
			
			rmax-=1
		else
			fmax-=1
			
			if r.w>r.h then
				mw=max(mw-1,3)
			else
				mh=max(mh-1,3)
			end
		end
	until fmax<=0 or rmax<=0 
end

function rnd_room(mw,mh)
	local w=3+flr(rnd(mw-2))
	mh=mid(35/w,3,mh)
	local h=3+flr(rnd(mh-2))
	
	return {
		x=0,
		y=0,
		w=w,
		h=h
	}
end

function place_room(r)
	local cand,c={}
	
	for _x=0,16-r.w do
		for _y=0,16-r.h do
			if doesroomfit(r,_x,_y) then
				add(cand,{x=_x,y=_y})
			end
		end
	end
	
	if #cand==0 then return false end
	
	c=get_rnd(cand)
	r.x=c.x
	r.y=c.y
	add(rooms,r)
	
	for _x=0,r.w-1 do
		for _y=0,r.h-1 do
			mset(_x+r.x,_y+r.y,1)
			room_map[_x+r.x][_y+r.y]=#rooms
		end
	end
	
	return true
end

function doesroomfit(r,x,y)
	for _x=-1,r.w do
		for _y=-1,r.h do
			if is_walkable(_x+x,_y+y) then
				return false
			end
		end
	end
	
	return true
end

-- maze

function mazeworm()
	repeat
		local cands={}
	
		in_xy_pairs(function(x,y)
			if
				can_carv(x,y,false)
				and not next_to_room(x,y)
			then
				add(cands,{x,y})
			end
		end)
		
		if #cands>0 then
			local c=get_rnd(cands)
		
			digworm(unpack(c))
		end
	until #cands<=1
end

function digworm(x,y)
	local step,dr=0,1+flr(rnd(4))
	
	repeat
		mset(x,y,1)
		
		if
			not can_carv(
				x+dirs_x[dr],y+dirs_y[dr],
				false
			)
			or (rnd()<0.5 and step>2)
		then
			local cands={}
			step=0
		
			for i=1,4 do
				if 
					can_carv(
						x+dirs_x[i],y+dirs_y[i],
						false
					)
				then
					add(cands,i)
				end
			end
			
			dr=#cands==0
				and 8 or get_rnd(cands)
		end
		
		x+=dirs_x[dr]
		y+=dirs_y[dr]
		step+=1
	until dr==8
end

function can_carv(x,y,walk)
	if not in_bounds(x,y) then
		return false
	end
	
	walk=walk==nil
		and is_walkable(x,y)
		or walk

	if	is_walkable(x,y)==walk then
		return sig_array(
			get_sig(x,y),crv_sigs,crv_msks
		)!=0
	end
	
	return false
end

function bcomp(sig,match,mask)
	local mask=mask or 0
	
	return bor(sig,mask)==bor(
		match,mask
	)
end

function get_sig(x,y)
	local sig,digit=0
	for i=1,8 do
		local dx,dy=x+dirs_x[i],
			y+dirs_y[i]
			
		digit=is_walkable(dx,dy)
			and 0 or 1
		
		sig=bor(sig,shl(digit,8-i))
	end
	
	return sig
end

function sig_array(sig,arr,marr)
	for i=1,#arr do
		if
			bcomp(sig,arr[i],marr[i])
		then
			return i
		end
	end
	
	return 0
end

-- doorways

function placeflags()
	local curf=1
	flags,flags_lib=blank_map(),{}
	
	in_xy_pairs(function(x,y)
		if is_walkable(x,y)
			and flags[x][y]==0
		then
			grow_flag(x,y,curf)
			add(flags_lib,curf)
			curf+=1
		end
	end)
end

function grow_flag(x,y,flg)
	local cand,candnew={{x=x,y=y}}
	flags[x][y]=flg
	
	repeat
		candnew={}
		
		foreach(cand,function(c)
			for d=1,4 do
				local dx,dy=c.x+dirs_x[d],
					c.y+dirs_y[d]
					
				if
					is_walkable(dx,dy)
					and flags[dx][dy]!=flg
				then
					flags[dx][dy]=flg
					add(candnew,{x=dx,y=dy})
				end
			end
		end)
		
		cand=candnew
	until #cand==0
end

function carvescuts()
	local x1,y1,x2,y2,cuts,found,drs=
		1,1,1,1,0
	
	repeat
		drs={}
		
		for x=0,15 do
			for y=0,15 do
				if not is_walkable(x,y) then
					local sig=get_sig(x,y)
					
					found=false
					if bcomp(
						sig,0b11000000,0b00001111
					) then
						x1,y1,x2,y2,found=
							x,y-1,x,y+1,true
					elseif bcomp(
						sig,0b00110000,0b00001111
					) then
						x1,y1,x2,y2,found=
							x+1,y,x-1,y,true
					end
				
					if found then
						calc_dist(x1,y1)
						if dist_map[x2][y2]>20 then
							add(drs,{x=x,y=y})
						end
					end
				end
			end
		end
	
		if #drs>0 then
			local d=get_rnd(drs)
			add(doors,d)
			mset(d.x,d.y,1)
			cuts+=1
		end
	until #drs==0 or cuts>=3
end

function carvedoors()
	local x1,y1,x2,y2,found,f1,f2,drs=
		1,1,1,1
	
	repeat
		drs={}
		
		in_xy_pairs(function(x,y)
			if not is_walkable(x,y) then
				local sig=get_sig(x,y)
				
				found=false
				if bcomp(
					sig,0b11000000,0b00001111
				) then
					x1,y1,x2,y2,found=
						x,y-1,x,y+1,true
				elseif bcomp(
					sig,0b00110000,0b00001111
				) then
					x1,y1,x2,y2,found=
						x+1,y,x-1,y,true
				end
	
				f1=flags[x1][y1]
				f2=flags[x2][y2]
				
				if found and f1!=f2 then
					add(
						drs,{x=x,y=y,f1=f1,f2=f2}
					)
				end
			end
		end)
	
		if #drs>0 then
			local d=get_rnd(drs)
			add(doors,d)
			mset(d.x,d.y,1)
		
			grow_flag(d.x,d.y,d.f1)
			del(flags_lib,d.f2)
		end
	until #drs==0
end

function fill_ends()
	local filled,tile

	repeat
		filled=false

		in_xy_pairs(function(x,y)
			tile=mget(x,y)
			
			if
				can_carv(x,y,true)
				and tile!=14
				and tile!=15
			then
				mset(x,y,2)
			end
		end)
	until not filled
end

function is_door(x,y)
	local sig=get_sig(x,y)
	
	if
		bcomp(
			sig,0b11000000,0b00001111
		)
		or bcomp(
			sig,0b00110000,0b00001111
		)
	then

		return next_to_room(x,y)
		
	end
end

function next_to_room(x,y,dirs)
	local dirs=dirs or 4

	for i=1,dirs do
		if
			in_bounds(x+dirs_x[i],y+dirs_y[i])
			and room_map[x+dirs_x[i]][y+dirs_y[i]]!=0
		then
			return true
		end
	end
end

function installdoors()
	foreach(doors,function(d)
		local dx,dy=d.x,d.y
		local tile=mget(dx,dy)
	
		if
			(tile==1 or tile==4)
			and is_door(dx,dy)
			and not next2tile(dx,dy,13)
		then
			mset(dx,dy,13)
		end
	end)
end

-- decoration

function start_end()
	local high,low,px,py=0,9999
	
	repeat
		px,py=flr(rnd(16)),flr(rnd(16))	
	until is_walkable(px,py)
	
	calc_dist(px,py)
	
	in_xy_pairs(function(x,y)
		local dist=dist_map[x][y]
			
		if is_walkable(x,y)
			and dist>high
		then
			px,py=x,y
			high=dist
		end
	end)
	
	calc_dist(px,py)
	high=0
	low=9999
	
	in_xy_pairs(function(x,y)
		local dist=dist_map[x][y]
			
		if dist>high
			and can_carv(x,y)
		then
			ex,ey=x,y
			high=dist
		end
	end)
	
	mset(ex,ey,14)
	
	in_xy_pairs(function(x,y)
		local dist=dist_map[x][y]
			
		if dist>=0 then
			local score=star_score(x,y)
			
			dist=dist-score
			
			if dist<low and score>=0 then
				px,py,low=x,y,dist
			end
		end
	end)
	
	if room_map[px][py]>0 then
		rooms[room_map[px][py]].no_spawn=true
	end
	
	mset(px,py,15)
	plyr.x=px
	plyr.y=py
end

function star_score(x,y)
	if room_map[x][y]==0 then
		if next_to_room(x,y,8) then
			return -1
		end
		
		if freestanding(x,y)>0 then
			return 5
		end
			
		if can_carv(x,y) then
			return 0
		end
	end
	
	local scr=freestanding(x,y)
	
	if scr>0 then
		return scr<=8 and 3 or 0
	end
	
	return -1
end

function next2tile(x,y,tile)
	for i=1,4 do
		if
			in_bounds(
				x+dirs_x[i],y+dirs_y[i]
			)
			and mget(
				x+dirs_x[i],y+dirs_y[i]
			)==tile
		then
			return true
		end 
	end
end

function pretty_walls()
	in_xy_pairs(function(x,y)
		local tile=mget(x,y)
	
		if tile==2 then
			local tle=3
			local ntle=sig_array(
				get_sig(x,y),
				wall_sig,
				wall_msk
			)
			
			if ntle!=0 then
				tle=15+ntle
			end
			
			mset(x,y,tle)
		elseif tile==1 then
			if
				not is_walkable(x,y-1)
			then
				mset(x,y,4)
			end
		end
	end)
end

function decorate_rooms()
	tarr_dirt=split"1,74,75,76"
	tarr_farn=split"1,70,70,70,71,71,71,72,73,74"
	tarr_vase=split"1,1,7,8"
	
	local decor_funcs,decor_func={
		deco_carpet,
		deco_torch,
		deco_dirt,
		deco_farn,
		deco_vase
	},deco_vase
	
	local room_pot={}
	
	foreach(rooms,function(r)
		add(room_pot,r)
	end)

	repeat
		local r=get_rnd(room_pot)
		del(room_pot,r)
	
		for x=0,r.w-1 do
			for y=r.h-1,1,-1 do
				if mget(r.x+x,r.y+y)==1 then
					decor_func(
						r,r.x+x,r.y+y,x,y
					)
				end
			end
			
			decor_func=get_rnd(
				decor_funcs
			)
		end
	until #room_pot==0
end

function deco_carpet(
	r,tx,ty,x,y
)
	deco_torch(r,tx,ty,x,y)

	if
		x>0 and x<r.w-1 and y<r.h-1
	then
		mset(tx,ty,68)
	end
end

function deco_dirt(r,tx,ty,x,y)
	mset(tx,ty,get_rnd(tarr_dirt))
end

function deco_torch(r,tx,ty,x,y)
	if
		rnd(3)>1 and y%2==1
		and not next2tile(tx,ty,13)
	then
		if x==0 then
			mset(tx,ty,64)
		elseif x==r.w-1 then
			mset(tx,ty,66)
		end
	end
end

function deco_farn(r,tx,ty,x,y)
	mset(tx,ty,get_rnd(tarr_farn))
end

function deco_vase(r,tx,ty,x,y)
	if
		is_walkable(tx,ty,"checkmobs")
		and not next2tile(tx,ty,13)
		and not bcomp(
			get_sig(tx,ty),0,0b00001111
		)
	then
		mset(tx,ty,get_rnd(tarr_vase))
	end
end

function spawn_chests()
	local room_pot,chestdice,rare=
		{},split"0,1,1,1,2,3",true
	local amount=get_rnd(chestdice)

	foreach(rooms,function(r)
		add(room_pot,r)
	end)
	
	while
		amount>0 and #room_pot>0
	do
		local r=get_rnd(room_pot)
		place_chest(r,rare)
		rare=false
		amount-=1
		del(room_pot,r)
	end
end

function place_chest(r,rare)
	local x,y
	
	repeat
		x=r.x+flr(rnd(r.w-2))+1
		y=r.y+flr(rnd(r.h-2))+1
	until mget(x,y)==1
	
	mset(x,y,rare and 12 or 10)
end

function freestanding(x,y)
	return sig_array(
		get_sig(x,y),
		free_sig,
		free_msk
	)
end
__gfx__
000000000000000066606660000000006660666066606660aaaaaaaa00aaa00000aaa00000000000000000000000000000aaa000a0aaa0a0a000000055555550
000000000000000000000000000000000000000000000000aaaaaaaa0a000a000a000a00066666600aaaaaa066666660a0aaa0a000000000a0aa000000000000
007007000000000060666060000000006066606060000060a000000a0a000a000a000a00060000600a0000a060000060a00000a0a0aaa0a0a0aa0aa055000000
00077000000000000000000000000000000000000000000000aa0a0000aaa000a0aaa0a0060000600a0aa0a060000060a00a00a000aaa00000aa0aa055055000
000770000000000066606660000000000000000060000060a000000a0a00aa00aa00aaa0066666600aaaaaa066666660aaa0aaa0a0aaa0a0a0000aa055055050
007007000005000000000000000000000005000000000000a0a0aa0a0aaaaa000aaaaa000000000000000000000000000000000000aaa000a0aa000055055050
000000000000000060666060000000000000000060666060a000000a00aaa00000aaa000066666600aaaaaa066666660aaaaaaa0a0aaa0a0a0aa0aa055055050
000000000000000000000000000000000000000000000000aaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000006666660666666000666666006666600666666006660666066666660000066606660000066666660000066600000666066600000
00000000000000000000000066666660666666606666666066666660666666606660666066666660000066606660000066666660000066600000666066600000
00000000000000000000000066666660666666606666666066666660666666606660066066666660000006606600000066666660000066600000066066600000
00000000000000000000000066600000000066606660000066606660000066606660000000000000000000000000000000000000000066600000000066600000
00000660666666606600000066600000000066606660666066606660666066606660066066000660660006606600066000000660660066606666666066600660
00006660666666606660000066600000000066606660666066606660666066606660666066606660666066606660666000006660666066606666666066606660
00006660666666606660000066600000000066606660666066606660666066606660666066606660666066606660666000006660666066606666666066606660
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006660066666006660000066600000000066600666666066606660666666006660666066606660666066606660666066606660666000006660666066666660
00006660666666606660000066600000000066606666666066606660666666606660666066606660666066606660666066606660666000006660666066666660
00006660666666606660000066600000000066606666666066000660666666606600066066006660660006606600066066600660660000006600666066666660
00006660666066606660000066600000000066606660000000000000000066600000000000006660000000000000000066600000000000000000666000000000
00006660666666606660000066666660666666606666666066000660666666606666666066006660000006606600000066600000666666600000666066000000
00006660666666606660000066666660666666606666666066606660666666606666666066606660000066606660000066600000666666600000666066600000
00006660066666006660000006666660666666000666666066606660666666006666666066606660000066606660000066600000666666600000666066600000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006660666666606660000066666660666066606660666066606660666066600000666066600000000066600000000066606660666000005000000088000088
00006660666666606660000066666660666066606660666066606660666066600000666066600000000066600000000066606660666000005055000080000008
00000660666666606600000066666660666066606660666066606660666066600000066066000000000006600000000066000660660000005055055000000000
00000000000000000000000000000000666066606660000066606660000066600000000000000000000000000000000000000000000000000055055000000000
00000000000000000000000066666660666066606666666066666660666666606600000000000660000006606600066000000000660000005000055000000000
00000000000000000000000066666660666066606666666066666660666666606660000000006660000066606660666000000000666000005055000000000000
00000000000000000000000066666660666066600666666006666600666666006660000000006660000066606660666000000000666000005055055080000008
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088000088
06000000000000000000060000000000505050506660666000000000000550000000000000000000000000000000000000000000000000000000000000000000
60000000060000000000006000000600000000000000000000500500000000500500005005050050005000000000005000500000000000000000000000000000
66000000660000000000066000000660505050506066606000050000055005000500005005000000000005000050055000000500000000000000000000000000
00000000000000000000000000000000000000000000000005050000555050000005000000005000000000000000000005000000000000000000000000000000
66000000660000000000066000000660505050505050505000005050000050500005050000005050000000000000000000055000000000000000000000000000
0005000000050000000500000005000000000000000000000050500000050000050505000500005000050000005500500050050000aaaaa00000000000000000
600000006000000000000060000000605050505050505050000050000005000005000000050500500000000005555000005550000aaaaaaaa000000000aaaa00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa0aaaaaaaa00000aaaaaaa0
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000a00aaaaaaaaaaaaaaaaaaaaa
cc7777cc7777ccccccccccccccccccccc77777777cccccccccccccccccccccc77ccccccc00000000000000000000000000000000aaaaaaaaaaaaaaaaaaaaaaaa
ccc77cccc77ccccccccccccccccccccccc77cccc77ccccccccccccccccccccc77ccccccc00000000000000000000000000000000aaaaaaaaaaaaaaaaaaaaaa0a
cccc77cc77cc77777cc7777cc7777ccccc77ccccc77cc777777c7777777cccc77ccccccc00000000000000000000000000000000aaaaaaaaaaaaaaaaaaaaa0aa
ccccc7777cc77ccc77cc77cccc77cccccc77cccccc77cc77cc7cc77ccc77ccc77ccccccc000000000000000000000000000000000aaaaaaaaaaaaaaaaaaa0aa0
ccccc7777c77ccccc77c77cccc77cccccc77cccccc77cc77ccccc77cccc77cc77ccccccc0000000000000000000000000000000000aaaaaaaaaaaaaaa0a0a0a0
cccccc77cc77ccccc77c77cccc77cccccc77cccccc77cc7777ccc77cccc77cc77ccccccc00000000000000000000000000000000a00aaa0a0a0a0a0a0a0a0a0a
cccccc77cc77ccccc77c77cccc77cccccc77cccccc77cc77ccccc77cccc77cc77ccccccc00000000000000000000000000000000a0000aaaa0a0a0a0a0aaa00a
cccccc77cc77ccccc77c77cccc77cccccc77ccccc77ccc77ccccc77cccc77cc77ccccccc00000000000000000000000000000000aa000000aaaaaaaaaaa000aa
cccccc77ccc77ccc77ccc77cc77ccccccc77cccc77cccc77cc7cc77ccc77cccccccccccc00000000000000000000000000000000aa000aa000000000000000aa
ccccc7777ccc77777ccccc7777ccccccc77777777cccc777777c7777777cccc77ccccccc000000000000000000000000000000000aa0000aaaaaaaaaa0000aa0
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000000000000a0aa00000000000000aa0a0
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000000000000000000000a00aa0000000000aa00a00
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000000aa00aaaaaaaaaa00aa000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000000000000000000000000aa0000000000aa00000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000000000000000000aaaaaaaaaa0000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000
cc7777cc777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777ccccccccccccccccccc77ccccccc000000000000000000000000
ccc77cc77cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777ccc77cccccccccccccccccc77ccccccc000000000000000000000000
ccc77c77cccc7777c777777c7777ccc777777ccccc77cccccc7777cccc77ccccccccc77cccc77c777777c77777777cc77ccccccc000000000000000000000000
ccc7777cccccc77ccc77cc7cc77ccccc77cc77ccc7777cccc77c77ccc7777ccccccc77ccccccccc77cc7cccc77cc7cc77ccccccc000000000000000000000000
ccc777ccccccc77ccc77ccccc77ccccc77cc77ccc7cc7cccc77cccccc7cc7ccccccc77ccccccccc77ccccccc77ccccc77ccccccc000000000000000000000000
ccc7777cccccc77ccc7777ccc777cccc77777ccc77cc7ccccc77cccc77cc7ccccccc77cccc7777c7777ccccc77ccccc77ccccccc000000000000000000000000
ccc77777ccccc77ccc77cccc777ccccc77cc77cc777777ccccc77ccc777777cccccc77ccccc77cc77ccccccc77ccccc77ccccccc000000000000000000000000
ccc77c777cccc77ccc77ccccc77ccccc77cc77cc77cc77cccccc77cc77cc77ccccccc77cccc77cc77ccccccc77ccccc77ccccccc000000000000000000000000
ccc77cc777ccc77ccc77cc7cc77cc7cc77cc77c77ccc77cc77cc77c77ccc77cccccccc77ccc77cc77cc7cccc77cccccccccccccc000000000000000000000000
cc7777cc777c7777c777777c777777c777777c7777cc777cc7777c7777cc777cccccccc77777cc777777ccc7777cccc77ccccccc000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000
c0000000000000ccccccc000000000cc00000000000ccc0000000000000000000000000000000000000000000000000000000000000000cc0000000000000000
0000000000000000ccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0000000000000000
00777777777770000c000077777770000777777777700007777777700777777077777777000077777707777777007777707777777777700c0000000000000000
0007777777777770000077777777777000777777777770007777770007777700077777700c0007777707777770007777707777777777700c0000000000000000
c00000777000777000077770000077770000777000777000007770000777000000077700ccc000777000077700007770000077700007700c0000000000000000
cc0000777000077700777000000000777000777000077700007770007770000c00077700cccc00777000077700077700000077700000700c0000000000000000
cccc007770000777007770000000007770007770000777000077700777000cccc0077700cccc00777000077700777000cc0077700000000c0000000000000000
cccc00777000077700770000000000077700777000077700007770777000ccccc0077700cccc0077700007770777000ccc007770007000cc0000000000000000
cccc0077700007700777007700077007770077700007700c00777777000cccccc0077700cccc007770000777777000cccc00777777700ccc0000000000000000
cccc0077700777700777007700077007770077700077700c0077777000ccccccc0077700cccc00777000077777000ccccc00777777700ccc0000000000000000
cccc007777777700077700770007700777007777777700cc00777777000cccccc0077700cccc007770000777777000cccc00777000700ccc0000000000000000
cccc0077777770000777000700070007770077777777000c007777777000ccccc0077700cccc0077700007777777000ccc007770000000cc0000000000000000
cccc007770000000077700000000000770007770077770000077707777000cccc0077700ccc000777000077707777000cc0077700000000c0000000000000000
cccc0077700000c000777000000000777000777000777700007770077770000cc0077700cc00007770000777007777000c0077700000700c0000000000000000
ccc000777000cccc00777000000000777000777000077770007770007777000000077700000700777000077700077770000077700007700c0000000000000000
cc00007770000ccc00077770000077770000777000007777007770000777770000077700007700777000077700007777700077700007700c0000000000000000
c0007777777000ccc0007777777777700007777700000777777777700077777700777777777707777770777777000777777777777777700c0000000000000000
c0077777777700cccc000077777770000077777770000077777777770000777707777777777707777770777777700007777777777777700c0000000000000000
c0000000000000ccccc000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000000000c0000000000000000
cc00000000000cccccccc000000000ccc000000000ccc000000000000cc000000000000000000000000000000000cc0000000000000000cc0000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000
00000000000000000000000000000000000006000000000006000000000000000000000000060006000000000066006600066600000666000006660000066600
00000000006660000000000000000000006600600006600060066000006600000066006600060006006600660600060000660600006606000066060000660600
00666000060666000066600000000000006660606066600060666000006660600600060000600060060006000600060006666000066660000666606606666066
06066600060666000606660006666660066666006066006006666600600660600066606000666060006660600066606006666666066666660666660606666606
60666660066666006066666060066666600666000666660006660060066666000606660606666606066606060606060606666606006606060660660000660600
66666660066666006666666066666666606660000666600000666060006666000666060606060606060666060660660666066000066000006606600006600000
06666600006660000666660006666660006666000066660006666000066660000606666006606660066606600666666006606600006600000060660000660000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000666000000066000000000000000000000000000000000000000000000666000000000000666600006666000066666600666600
00666600000000000066660006600600000666600000660000000000000066000000000000066600006666660006660000066666000660660006606600066066
06600060006666660660006006000000000606000006666000006600000666600006660000666666006666060066666600666666006666660066660000666666
06660000066600000666000006660000060666660006060000066660000606000066666600666606066666660066660600060000000600000006000000060000
00666600006666000066660000666600066666060606666600060600060666660066660606666666066666000666666600006600060066000000660006006600
06066066060660660606606606066066006660000666660606066666066666060666666606666600066666660666660000006660060066600000666006006660
06060660060606600606066006060660000000000066600006666606006660000666660006666666066606060666666606666600006666000666660000666600
00000000000000000000000000000000000000000000000000666000000000000666666606660606066660000666060600000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000606000000000000060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000
00060600006666000006060000666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000000
00666600000606660066660000060666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077700000
00060666000666660006066600066666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000000
06066666006000000006666606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000
66000000066066000660000066066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66066606066066000660660066066606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00600600000660000060060000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000050500050303030103010307020005050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505000000000000000004040000000000010101000000000000000000000000000101010000000000000000000000000001030100000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0202020202020202020202020202020203030303030303030303030303030303030303030303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020f0101010d01010707020801c00e0203030303030303030303030303030303030000000000000000000000000000030000000000000010111200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02010101070201010707020101c0c002030303030303030303030303030303030300000010111111111112000000000300000000000000200e2200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010108020801010102010101010203030303030310111203030303030303030000002002020202022200000000030000101111111124442311111111120000000000000000000000101111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02010101080208010108020707010102030303101111240e2311111203030303030000002002050205022200000003030000200404044545444545040404220000000000000000000000200101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020101010102020d0202020202020d0203030320040445444504042203030303030000002004040404042200000003030000204001484444444444480142220000000000000000000000200101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02080101080201010102010d01010102030303204a01444444014b22030303030303000020014d4e4f0122000000030300002001494a4444064444494a01220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0208010808020101010201020d020202030303204001440644014322030303030303000020015d5e5f0122000000030300002001214944444444444a2148220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02020d02020201c001020102c0c00802030303204801444444010122030303030303000020016d6e6f012200000000030000200148014444444444010101220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010d0101010201020101010203030320070101010101072203030303030000002001010101012200000000030000204001014a44444401014a42220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d02020202020101010201020101010203030320080701010108082203030303030000003014010101133200000000030000200107070101010101010708220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010102020d02020201020101010203030330313114011331313203030303030000000020010f012200000000030300003031311c3327011331313131320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101020101010102010d010a0102030303030303200f2203030303030303030000000030313131320000000003030000000000200f04012200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010102010c01c0020102c001010203030303030330313203030303030303030000000000000000000000000000030000000000303131313200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010101010d01c001010d01020101070203030303030303030303030303030303030000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020203030303030303030303030303030303030303030303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
001600000217502705021150200002135000000210402104021250000002105000000215500000000000211401175017050111500105011350010500105001050112500105001050010501135001000000000000
00160000215101d510195251a535215351d520195151a5152151221515215252252521525215150e51511515205141c510195251c535205351c520195151c5152051220515205252152520525205150d51510515
0116000000000215101d510195151a515215151d510195151a5152151221515215152251521515215150e51511515205141c510195151c515205151c510195151c5152051220515205152151520515205150d515
01160000150051d00515015150151a0251a0151d0151d015220252201521025210151d0251d0151502515015140201402214025140151400514004140050d000100140c0100d0201003014030150201401210015
011600000217502705021150200002135000000000000000021250000000000000000215500000000000211405175001050511500105051350010500105001050512500105001050010505135000000000000000
01160000215141d510195251a525215251d520195151a5152151221515215202252021525215150e52511515205141d5101852519525205251d520185151951520512205151c5201d52020525205151052511515
0116000000000215141d510195151a515215151d510195151a5152151221515215102251021515215150e51511515205141d5101851519515205151d510185151951520512205151c5101d510205152051510515
01160000000002000015015150151a0251a0151d0251d015220252201521015210151d0251d01526015260152502025012250152501518000000000000000000100000d02011030140401505014040190301d010
011600000717502005071150200007135000000000000000071250000000000000000715500000000000711403175001050311500105031350010500105001050312500105001050010503155000000000000000
01160000091750200509115020000913500000000000000009125000000000000000091550000000000091140a175001050a115001050a1250010504105001050a125001050910500105041350c1000912500100
01160000225121f5201a5251f515225251f5201a5151f515215122151222525215251f5251f5150e52513515225141f5101b5251f525225251f5201b5151f515215122151222525215251f5251f5150f52513515
01160000215141c510195251d515215251c520195151d5152151222510215201f51021512215150d52510515205141d5101a52516515205151d5201a5151651520522205151d515205251f5251d5151c52519515
0116000000000225121f5101a5151f515225151f5101a5151f515215122151222515215151f5151f5150e51513515225141f5101b5151f515225151f5101b5151f515215122151222515215151f5151f5150f515
0116000000000215141c510195151d515215151c510195151d5152151222510215101f51021510215150d51510515205141d5101a51516515205151d5101a5152051520510205151d515205151f5151d5151c515
01160000000000000022015220151f0251f0151a0151a01522025220151f0151f01519020190221a0251a0151f0201f0221f0151f01518000000000000000000000000f010130201603015030160321502013015
011600001902519015220252201521015210151c0251c015220252201521025210151c0221c0151d0251d01520020200222001520015110051a0151d015220152601226012280102601625010250122501025015
011600000217509035110150203502135090351101502104021250000002105000000212511035110150211401175080351001501035011350803510015001050112500105001050010501135100351001500000
0116000002175090351101502035021350903511015021040212500000021050000002155110351101502114051750c0351401505035051350c03514015001050512500105001050010505135140351401500000
01160000071750e0351601507035071350e0351601502104071250000002105000000715516035160150711403175160351301503035031351603513015001050312500105001050010503135160351601500000
0116000009175100351101509035091351003511015021040912500000021050000009155100350d015091140a17510035110150a0350a1351003511015001050a12500105001050010509135150350d01509020
0116000002215020451a7051a7050e70511705117050e7050e71511725117250e7250e53511535115450e12501215010451a6001a70001205012051a3001a2001071514725147251072510535155351554514515
0116000002215020451a7051a7050e70511705117050e7050e71511725117250e7250e53511535115450e12505215050451a6001a70001205012051a3001a2001171514725147251172511535195351954518515
0116000007215070451a7051a7050e70511705117050e705137151672516725137251353516535165451312503215030451a6001a70001205012051a3001a2001371516725167250d7250f535165351654513515
0116000009215090451a7051a7050e70511705117050e7050d715157251572510725115351653516545157250a2150a0451a6001a70001205012051a3001a2000e71510725117250e7250d5350e5351154510515
0116000021005210051d00515015150151a0151a0151d0151d015220152201521015210151d0151d01515015150151401014012140151401518000000000000000000100100c0100d01010010140101501014010
0016000000000000002000015015150151a0151a0151d0151d015220152201521015210151d0151a01526015260152501019015190151900518000000000000000000000000d0101101014010150101401019010
0016000000000000000000022015220151f0151f0151a0151a01522015220151f0151f01519010190121a0151a0151f0101f012130151300518000000000000000000000000f0101301016010150101601215010
01160000190051901519015220152201521015210151c0151c015220152201521015210151c0121c0151d0151d015200102001220015200051d0051a015220152901029012260102801628010280122801528005
01160000097140e720117300e730097250e7251173502735057240e725117350e735097450e7401174002740087400d740107200d720087350d7351072501725047240d725107250d725087350d7301074001740
01160000097240e720117300e730097450e745117350e735117240e725117350e735097450e740117400e740087400d740117200d720087350d735117250d725117240d725117250d725087350d730117400d740
011600000a7240e720137300e7300a7450e745137350e735137240e725137350e7350a7450e740137400e7400a7400f740137200f7200a7350f735137250f725137240f725137250f7250a7350f730137400f740
0116000010724097201073009730107450974510735097351072409725107350973510745097401074009740117400e740117200e720117350e735117250e725117240e725117250e725097350d730107400d740
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0113000029700297002670026700257002570022700227000000026700217000e7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011300000255011555165501555016555115550d5500a5500e5500e5520e5520e5521400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011300001170015700197001a700117001670019700197001a7001a70025700257002570025700257002570025700197021970219702000000000000000000000000000000000000000000000000000000000000
001300000d2200c2200b220154000000000000000000000029720287302672626745287402173029720217322673026732267350210526702267020e705021050000000000000000000000000000000000000000
0113000000000000000000000000000000000000000000000e1100d1200a1300e1350d135091000a120091300e1220e1200e1200e1000e1020e10200000000000000000000000000000000000000000000000000
0113000000000000000000000000000000000000000000000a14300000000000a060090600a000090000900002072020720207202005020020200500000000000000000000000000000000000000000000000000
011200001b0001f0002200023000220001f0002000022000230002700023000200001f000200001f0001b0001f00022000200002200023000270001d000200001f0001f0001f0001f00000000000000000000000
011200001f5001f5001b5001b50022500225002350023500225002250020500205001f5001f500205002050022500225002350023500255002550023500235002250022500225002250000000000000000000000
000100000f0000b0001c5002550030500225001c50030000270001d0001d0001c00013000110000f0001000010000000000000000000000000000000000000000000000000000000000000000000000000000000
011200001e0201e0201e032210401a0401e0401f0301f0321f0301f0301e0201e0201f0201f020210302103022030220322902029020290222902228020280202602026020260222602200000000000000000000
011200001a7041a70415534155301a5321a5301c5401c5401c5451a540155401554516532165301a5301a5351f5401f54522544225402254222545215341f5301e5441e5401e5421e54500000000000000000000
01120000110250e000120351500015045150000e0550e00512045150051503515005130251500516035260051a0452100513045210051604526005100251f0050e0500e0520e0520e0500c000000000000000000
0002000031530315302d500315003b5303b5302e5000050031530315302e5002d50039530395302d5000050031530315303153031530315203152000500005000050000500005000050000500005000050000500
000100003101031010300102f0102d0202c0202a02028030270302503023050210501e0501d0501b05018050160501405012050120301103011010110100e0100b01007010000000000000000000000000000000
00010000240102e0202b0202602021010210101a01000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000024010337203372033720277103a7103a71000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000096201163005620056150160000600006001160011600116001160001620006200a6100a6050a6000a6000f6000f6000f6000f6000060000600026100261002615016000160005600056000160001600
00010000145201a520015000150001500015000150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000211102114015140271300f6300f6101c610196001761016600156100f6000c61009600076000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100001b61006540065401963018630116100e6100c610096100861000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001f5302b5302e5302e5303250032500395002751027510285102a510005000050000500275102951029510005000050000500005002451024510245102751029510005000050000500005000050000500
0001000024030240301c0301c0302a2302823025210212101e2101b2101b21016210112100d2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100020000200
0001000024030240301c0301c03039010390103a0103001030010300102d010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000210302703025040230301a030190100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000d720137200d7100c40031200312000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
03 00424344
01 00031843
00 04071947
00 080e1a4e
00 090f1b4f
00 10010243
00 11050647
00 120a0c4e
00 130b0d4f
00 001c0344
00 041d0744
00 081e0e44
00 091f0f44
00 00145c44
00 04155d44
00 08165e44
02 13175f44
00 41424344
00 41424344
00 41424344
00 41424344
00 68696744
04 2a2b2c44
00 6d6e6f44
04 30313244

