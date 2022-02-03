pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
-- initialization

function _init()
	local s=split
	-- directions
	dirs_x=s"-1,1,0,0,1,1,-1,-1"
	dirs_y=s"0,0,-1,1,-1,1,1,-1"
	
	dpal=s"0,1,1,2,1,13,6,4,4,9,3,13,1,13,14"
	
	item_name=s"butter knife,cheese knife,paring knife,utility knife,chef's knife,meat cleaver,paper apron,cotton apron,rubber apron,leather apron,chef's apron,butcher's apron,food 1,food 2,food 3,food 4,food 5,food 6,spork,salad fork,fish fork,dinner fork"
	item_type=s"wep,wep,wep,wep,wep,wep,arm,arm,arm,arm,arm,arm,fud,fud,fud,fud,fud,fud,thr,thr,thr,thr"
	item_stat1=s"1,2,3,4,5,6,0,0,0,0,1,2,1,2,3,4,5,6,1,2,3,4"
	item_stat2=s"0,0,0,0,0,0,1,2,3,4,3,3,0,0,0,0,0,0,0,0,0,0"
	item_minf=s"1,2,3,4,5,6,1,2,3,4,5,6,1,1,1,1,1,1,1,2,3,4"
	item_maxf=s"3,4,5,6,7,8,3,4,5,6,7,8,8,8,8,8,8,8,4,6,7,8"
	item_desc=s",,,,,,,,,,,,heals,heals a lot,increase hp,stun,is cursed,is blessed,,,,"
	
	mob_name=s"player,slime,melt,shoggoth,mantis-man,giant scorpion,ghost,golem,drake"
	mob_sprs=s"240,192,196,200,204,208,212,216,220"
	mob_atk=s"1,1,2,2,2,3,3,5,5"
	mob_hp=s"5,1,2,3,3,4,5,14,8"
	mob_los=s"4,4,4,4,4,4,4,4,4"
	mob_minf=s"0,1,2,3,4,5,6,7,8"
	mob_maxf=s"0,3,4,5,6,7,8,8,8"
	mob_spec=s",,,spawn,fast,stun,ghost,slow,"	
		
	crv_sigs=s"255,214,124,179,233"
	crv_msks=s"0,9,3,12,6"

	wall_sig=s"251,233,253,84,146,80,16,144,112,208,241,248,210,177,225,120,179,0,124,104,161,64,240,128,224,176,242,244,116,232,178,212,247,214,254,192,48,96,32,160,245,250,243,249,246,252"
 wall_msk=s"0,6,0,11,13,11,15,13,3,9,0,0,9,12,6,3,12,15,3,7,14,15,0,15,6,12,0,0,3,6,12,9,0,9,0,15,15,7,15,14,0,0,0,0,0,0"

	final_floor=9
	frames=0
	
	startgame()
end

function _draw()
	_drw()
	draw_windows()
	check_fade()
end

function _update60()
	frames+=1
	_upd()
	anim_floaters()
	upd_hp_box()
end

function startgame()
	tile_ani=0
	fadeperc=1
	
	btn_buffer=-1
	
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
		5,5,28,13,{"♥5/5"}
	)
	
	-- list of floating text
	floaters={}

	_upd=update_game
	_drw=draw_game
	
	food_names()
	gen_floor(0)
end

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
-->8
-- updates

function update_game()
	if talk_window then
		if get_btn()==5 then
			talk_window:close()
			talk_window=nil
		end
	else
		do_btn_buff()
		
		btn_action()
		btn_buffer=-1
	end
end

function update_inv()
	menu_action(actv_wind)

	if btnp(4) then
		actv_wind:cancel()
	elseif btnp(5) then
		actv_wind:confirm()
	end
end

function menu_action(wnd)
	if btnp(2) then
		wnd.cursor-=1
	elseif btnp(3) then
		wnd.cursor+=1
	end
	wnd.cursor=
		(wnd.cursor-1)%#wnd.text+1
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
			and not skipai
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
	if btn_buffer<0 then return end
	
	if btn_buffer<4 then
		move_player(
			dirs_x[btn_buffer+1],
			dirs_y[btn_buffer+1]
		)
	elseif btn_buffer==5 then
		-- menu button
		show_inv()
	elseif btn_buffer==4 then
		gen_floor(floor+1)
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
			if sin(time()*8)>0 then
				draw_mob(m)
			end
			
			m.dur-=1
			
			if m.dur<=0 then
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

function draw_gameover()
	cls(2)
	print("u ded",50,50,7)
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
	else
		-- not walkable
		mob_bump(plyr,dx,dy)
		
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
	
	anim_timer=0
	_upd=update_player_turn
	
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
			else
				local itm=get_rnd(fipool_com)
				
				take_item(itm)
				show_msg(item_name[itm],60)
			end
		end
	elseif tile==10 or tile==12 then
		-- chest
		if not has_inv_slot() then
			show_msg("inventory full",120)
			skipai=true
		else
			local itm=get_rnd(fipool_com)
			
			if tile==12 then
				itm=get_rare_item()
			end
			
			sfx(61)
			mset(d_x,d_y,tile-1)
			take_item(itm)
			show_msg(item_name[itm],60)
		end
	elseif tile==13 then
		-- door
		sfx(62)
		mset(d_x,d_y,1)
	elseif tile==6 then
		-- stone tablet
		if floor==0 then
			show_talk({
				"welcome to porklike!",
				"",
				"climb this sausage",
				"tower to obtain the",
				"ultimate power of",
				"the golden kielbasa",
				""
			})
		end
	elseif tile==110 then
		-- kielbasa
		win=true
	end
end

function trigger_step(tile)
	local tile=mget(plyr.x,plyr.y)

	if tile==14 then
		plyr.bless=0
		fadeout()
		gen_floor(floor+1)
		floor_msg()
		
		return true
	end
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
	
	if trgt.hp<=0 then
		trgt.dur=13
		add(dead_mobs,trgt)
		del(mobs,trgt)
	end	
end

function heal_mob(mb,heal)	
	heal=min(mb.max_hp-mb.hp,heal)
	mb.hp+=heal
	mb.flash=10
	
	add_floater(
		"+"..heal,mb.x*8,mb.y*8,7
	)
end

function stun_mob(mob)
	mob.stun=true
	mob.flash=10
	
	add_floater(
		"stun",mob.x*8-3,mob.y*8,7
	)
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
end

function check_end()
	if win then
		windows={}
		_upd=update_gameover
		_drw=draw_win
		fadeout(0.02)
		
		return false
	end

	if (plyr.hp>0) return true

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
	
	if x1<x2 then
		sx,dx=1,x2-x1
	else
		sx,dx=-1,x1-x2
	end
	
	if y1<y2 then
		sy,dy=1,y2-y1
	else
		sy,dy=-1,y1-y2
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

	plyr.atk=1+atk
	plyr.defmin=dmin
	plyr.defmax=dmax
end

function eat(item,mob)
	local effect=item_stat1[item]

	food_effects[effect](mob)
	
	show_msg(
		item_name[item].." "..item_desc[item],
		120
	)
end

function throw()
	local itm,tx,ty=inv[thrslt],
		throw_tile()

	if in_bounds(tx,ty) then
		local mb=get_mob(tx,ty)
		
		if (not mb) return
		
		if item_type[itm]=="fud" then
			eat(itm,mb)	
		else
			hit_mob({
				atk=item_stat1[itm]
			},mb)
			sfx(58)
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

function add_window(
	x,y,width,height,txt
)
	return add(windows,{
		x=x,
		y=y,
		width=width,
		height=height,
		text=txt,
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
	foreach(floaters,
		function (flt)
			flt.y+=(flt.trg_y-flt.y)/10
			flt.timer+=1
			if flt.timer>70 then
				del(floaters,flt)
			end
		end
	)
end

function upd_hp_box()
	hp_box.text[1]=
		"♥"..plyr.hp.."/"..plyr.max_hp
	local y=5
	if plyr.y<8 then
		y=110
	end
	hp_box.y+=(y-hp_box.y)/5
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
	
	inv_wind=add_window(
		5,17,84,62,txt
	)
	inv_wind.cursor=3
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
	inv_wind.cancel=function()
		_upd=update_game
		inv_wind:close()
		stat_wind:close()
	end
	
	actv_wind=inv_wind
	_upd=update_inv
end

function show_use()
	local txt,i={},inv_wind.cursor
	local item=i<3
		and eqp[i] or inv[i-3]
		
	if (not item) return	

	local typ=item_type[item]
	local typ_map={
		wep="equip",
		arm="equip",
		fud="eat,throw",
		thr="throw"
	}
	
	foreach(
		split(typ_map[typ]),
		function(act) add(txt,act) end
	)
	
	add(txt,"trash")

	use_menu=add_window(
		84,i*6+11,36,7+#txt*6,txt
	)
	use_menu.cursor=1
	
	use_menu.confirm=trigger_use
	use_menu.cancel=function()
		use_menu:close()
		actv_wind=inv_wind
	end

	actv_wind=use_menu
end

function trigger_use()
-- 3300
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
	end
end

function floor_msg()
	show_msg("floor "..floor,120)
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
		flash=0,
		flipped=false,
		hp=mob_hp[typ],
		max_hp=mob_hp[typ],
		atk=mob_atk[typ],
		defmin=0,
		defmax=0,
		bless=0,
		stun=false,
		charge=1,
		spec=mob_spec[typ],
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
			m.stun=false
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
	
	local min_mobs=split"3,5,7,9,10,11,12,13"
	local max_mobs=split"6,10,14,18,20,22,24,26"
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
	
	for i=1,#item_name do
		if item_type[i]=="fud" then
			fu,ad=get_rnd(foods),
				get_rnd(adjs)
				
			del(foods,fu)
			del(adjs,ad)
			
			item_name[i]=ad.." "..fu
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
	
	if floor==0 then
		return copy_map(16,0)
	end
	
	if floor==final_floor then
		return copy_map(32,0)
	end
	
	fog=blank_map()
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
	local mw,mh=6,6

	repeat
		local r=rnd_room(mw,mh)
		
		if place_room(r) then
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
		local sig=get_sig(x,y)
	
		for i=1,#crv_sigs do
			if bcomp(
				sig,crv_sigs[i],crv_msks[i]
			) then
				return true
			end
		end
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

function next_to_room(x,y)
	for i=1,4 do
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
			
		if
			dist>=0
			and dist<low
			and can_carv(x,y)
		then
			px,py=x,y
			low=dist
		end
	end)
	
	mset(px,py,15)
	plyr.x=px
	plyr.y=py
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
			local sig,tile=get_sig(x,y),3
			
			for i=1,#wall_sig do
				if bcomp(
					sig,wall_sig[i],wall_msk[i]
				)
				then
					tile=i+15
					break
				end
			end
			
			mset(x,y,tile)
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

	foreach(rooms,function(r)
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
	end)
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
00006660666666606660000066666660666066606660666066606660666066600000666066600000000066600000000066606660666000005000000000000000
00006660666666606660000066666660666066606660666066606660666066600000666066600000000066600000000066606660666000005055000000000000
00000660666666606600000066666660666066606660666066606660666066600000066066000000000006600000000066000660660000005055055000000000
00000000000000000000000000000000666066606660000066606660000066600000000000000000000000000000000000000000000000000055055000000000
00000000000000000000000066666660666066606666666066666660666666606600000000000660000006606600066000000000660000005000055000000000
00000000000000000000000066666660666066606666666066666660666666606660000000006660000066606660666000000000666000005055000000000000
00000000000000000000000066666660666066600666666006666600666666006660000000006660000066606660666000000000666000005055055000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06000000000000000000060000000000505050506660666000000000000550000000000000000000000000000000000000000000000000000000000000000000
60000000060000000000006000000600000000000000000000500500000000500500005005050050005000000000005000500000000000000000000000000000
66000000660000000000066000000660505050506066606000050000055005000500005005000000000005000050055000000500000000000000000000000000
00000000000000000000000000000000000000000000000005050000555050000005000000005000000000000000000005000000000000000000000000000000
66000000660000000000066000000660505050505050505000005050000050500005050000005050000000000000000000055000000000000000000000000000
0005000000050000000500000005000000000000000000000050500000050000050505000500005000050000005500500050050000aaaaa00000000000000000
600000006000000000000060000000605050505050505050000050000005000005000000050500500000000005555000005550000aaaaaaaa000000000aaaa00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa0aaaaaaaa00000aaaaaaa0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00aaaaaaaaaaaaaaaaaaaaa
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaaaaaaaaaaaaaaaaaaaa
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaaaaaaaaaaaaaaaaaa0a
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaaaaaaaaaaaaaaaaa0aa
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaaaaaaaaaaaaaaa0aa0
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaaaaaaaaaaa0a0a0a0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00aaa0a0a0a0a0a0a0a0a0a
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0000aaaa0a0a0a0a0aaa00a
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa000000aaaaaaaaaaa000aa
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa000aa000000000000000aa
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa0000aaaaaaaaaa0000aa0
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0aa00000000000000aa0a0
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00aa0000000000aa00a00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa00aaaaaaaaaa00aa000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa0000000000aa00000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaaaaaa0000000
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
00000000000000000000000000000000000006000000000006000000000000006600660000000000600060000000000000666000006660000066600000666000
00000000006660000000000000000000006600600006600060066000006600000060006066006600600060006600660000606600006066000060660000606600
00666000060666000066600000000000006660606066600060666000006660600060006000600060060006000060006066066660660666600006666000066660
06066600060666000606660006666660066666006066006006666600600660600606660006066600060666000606660060666660606666606666666066666660
60666660066666006066666060066666600666000666660006660060066666006060606060606660606666606066606000606600006606606060660060666660
66666660066666006666666066666666606660000666600000666060006666006066066060666060606060606060666000000660000660660000066000066066
06666600006660000666660006666660006666000066660006666000066660000666666006606660066606600666606000006600006606000000660000660660
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066600000000000000000000000000000000000000000000000000006600000000000000666000000000000000000000666600666666000066660000666600
00600660006666000000000000666600006600000000000000660000066660000066600066666600006660000000000066066000660660006606600066666000
00000060060006606666660006000660066660000066000006666000006060006666660060666600666666000066600066666600006666006666660066666600
00006660000066600000666000006660006060000666600000606000666660606066660066666660606666006666660000006000000060000000600000006000
00666600006666000066660000666600666660600060600066666060606666606666666000666660666666606066660000660060006600000066006000660000
66066060660660606606606066066060606666606666606060666660000666000066666066666660006666606666666006660060066600000666006006660000
06606060066060600660606006606060000666006066666000066600000000006666666060606660666666600066666000666600006666600066660000666660
00000000000000000000000000000000000000000006660000000000000000006060666000066660606066606666666000000000000000000000000000000000
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
0000050500050303030103010307020005050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505000000000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020f010101010101010101020e01010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010101010202020201020202010200000000000010111111120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010101010201010101020101010200000000001024450e45231200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010101010201010101020102020200000000102445444444452312000000000000000002020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010101010201010101020101010200000000200444444444440422000000000000000002010101010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010101010102020202020101010200000000204949440644014822000000000000000002010601010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010101010101010101020101010200000000200101444444480122000000000000000002010101010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02020d02020202020202020202020d0200000000204001444444014222000000000000000002010101010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010701020a0101010108020201010200000000200701484848010722000000000000000002020201020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010102010101010101020201010200000000200808010101070822000000000000000000020f01020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010102020202020101020201010200000000303114010101133132000000000000000000020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02010601020c01010101010d0101020200000000000020010f01220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010102010101010101020101010200000000000030313131320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010101010101010707020101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00010000211102114015140271300f6300f6101c610196001761016600156100f6000c61009600076000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001b61006540065401963018630116100e6100c610096100861000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001f5302b5302e5302e5303250032500395002751027510285102a510005000050000500275102951029510005000050000500005002451024510245102751029510005000050000500005000050000500
0001000024030240301c0301c0302a2302823025210212101e2101b2101b21016210112100d2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100020000200
0001000024030240301c0301c03039010390103a0103001030010300102d010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000210302703025040230301a030190100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000d720137200d7100c40031200312000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
