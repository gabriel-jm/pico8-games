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
	
	mob_sprs=s"240,192"
	mob_atk=s"1,1"
	mob_hp=s"5,2"
	mob_los=s"4,4"
	
	item_name=s"broad sword,leather armor,red potion,ninja star,steel axe"
	item_type=s"wep,arm,fud,thr,wep"
	item_stat1=s"2,0,1,1,1"
	item_stat2=s"0,2,0,0,0"
	
	crv_sigs=s[[0b11111111,
		0b11010110,0b01111100,
		0b10110011,0b11101001
	]]
	crv_msks=s[[0,0b00001001,
		0b00000011,0b00001100,
		0b00000110
	]]

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
	fadeperc=1
	
	btn_buffer=-1
	
	skip_ai=false
	
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
	
--	add_mob(2,7,5)
--	add_mob(2,6,9)
--	add_mob(2,9,12)

--	take_item(1)
--	take_item(2)
--	take_item(3)
--	take_item(4)
--	take_item(5)
	
	windows={}
	talk_window=nil
	hp_box=add_window(
		5,5,28,13,{"♥5/5"}
	)
	
	-- list of floating text
	floaters={}
	
	-- fog map
	fog=blank_map()

	_upd=update_game
	_drw=draw_game
	
	gen_floor(0)
	
	unfog()
end
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
		anim_timer+0.125,
		1
	)
	
	if (plyr.anim)	plyr:anim()
	
	if anim_timer==1 then
		_upd=update_game
		local tile=mget(plyr.x,plyr.y)
		
		if
			fget(tile,1)
			and trigger_step(tile)
		then
			return
		end

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
		anim_timer+0.125,
		1
	)
	
	for_each(mobs,function(mob)
		if
			mob!=plyr and mob.anim
		then
			mob:anim()
		end	
	end)
	
	if anim_timer==1 then
		_upd=update_game
		check_end()
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
		map_gen()
	end
end
-->8
-- draws

function draw_game()
	cls(0)
	map()
	
	for_each(dead_mobs,
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
	
	for_each(floaters,function(fl)
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

function for_each(table,cb)
	for item in all(table) do
		cb(item)	
	end
end

function for_each_xy(fx,fy,sx,sy)
	fx=fx or 15
	fy=fy or 15
	sx=sx or 0
	sy=sy or 0
	
	return function(cb)
		for x=sx,fx do
			for y=sy,fy do
				cb(x,y)
			end
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
		mset(d_x,d_y,1)
		if rnd(4)<1 then
			local itm=flr(rnd(#item_name))+1
			take_item(itm)
			show_msg(item_name[itm],60)
		end
	elseif tile==10 or tile==12 then
		-- chest
		sfx(61)
		mset(d_x,d_y,tile-1)
		local itm=flr(rnd(#item_name))+1
		take_item(itm)
		show_msg(item_name[itm],60)
	elseif tile==13 then
		-- door
		sfx(62)
		mset(d_x,d_y,1)
	elseif tile==6 then
		-- stone tablet
		show_talk({
			"hello my dear friend",
			"",
			"this is porklike"
		})
	end
end

function trigger_step(tile)
	if tile==14 then
		gen_floor(floor+1)
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

function check_end()
	if (plyr.hp>0) return true

	windows={}	
	_upd=update_gameover
	_drw=draw_gameover
	reload(0x2000,0x2000,0x1000)
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
		
		for_each(candits,function(c)
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
	
	if effect==1 then
		-- heal
		heal_mob(mob,1)
	end
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
	for_each(windows,
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
	for_each(floaters,
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
	
	stat_wind=add_window(
		5,5,84,13,{
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
	
	for_each(
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
	for_each(mobs,function (m)
		if (m==plyr) return
		
		m.anim=nil
		moving=m:task() or moving
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
		hit_mob(m,plyr)
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
-->8
-- level generation

function gen_floor(num)
	floor=num
	map_gen()
end

function map_gen()
	for x=0,15 do
		for y=0,15 do
			mset(x,y,2)
		end
	end
	
	doors={}
	rooms={}
	room_map=blank_map()
	
	gen_rooms()
	mazeworm()
	placeflags()
	carvedoors()
	carvescuts()
	start_end()
	fill_ends()
	installdoors()
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
	
		for_each_xy()(function(x,y)
			if 
				not is_walkable(x,y)
				and get_sig(x,y)==255
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
	if
		in_bounds(x,y)
		and is_walkable(x,y)==walk
	then
		local sig=get_sig(x,y)
	
		for i=1,#crv_sigs do
			if bcomp(
				sig,crv_sigs[i],crv_msks[i]
			) then
				return true
			end
		end
	end
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
	flags=blank_map()
	
	for x=0,15 do
		for y=0,15 do
			if is_walkable(x,y)
				and flags[x][y]==0
			then
				grow_flag(x,y,curf)
				curf+=1
			end
		end
	end
end

function grow_flag(x,y,flg)
	local cand,candnew={{x=x,y=y}}
	flags[x][y]=flg
	
	repeat
		candnew={}
		
		for_each(cand,function(c)
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
		
		for_each_xy()(function(x,y)
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
		end
	until #drs==0
end

function fill_ends()
	local cands,tile

	repeat
		cands={}	

		for x=0,15 do
			for y=0,15 do
				tile=mget(x,y)
				if
					can_carv(x,y,true)
					and tile!=14
					and tile!=15
				then
					add(cands,{x=x,y=y})
				end
			end
		end
		
		for_each(cands,function(c)
			mset(c.x,c.y,2)
		end)
	until #cands==0
end

function is_door(x,y)
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
	for_each(doors,function(d)
		if
			is_walkable(d.x,d.y)
			and is_door(d.x,d.y)
		then
			mset(d.x,d.y,13)
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
	for x=0,15 do
		for y=0,15 do
			local dist=dist_map[x][y]
			
			if is_walkable(x,y)
				and dist>high
			then
				px,py=x,y
				high=dist
			end
		end
	end
	
	calc_dist(px,py)
	high=0
	low=9999
	for x=0,15 do
		for y=0,15 do
			local dist=dist_map[x][y]
			
			if dist>high
				and can_carv(x,y,false)
			then
				ex,ey=x,y
				high=dist
			end
		end
	end
	
	mset(ex,ey,14)
	
	for x=0,15 do
		for y=0,15 do
			local dist=dist_map[x][y]
			
			if
				dist>=0
				and dist<low
				and can_carv(x,y,false)
			then
				px,py=x,y
				low=dist
			end
		end
	end
	
	mset(px,py,15)
	plyr.x=px
	plyr.y=py
end
__gfx__
000000000000000060666060d0ddd0d00000000000000000aaaaaaaa00aaa00000aaa00000000000000000000000000000aaa000a0aaa0a0a000000055555550
000000000000000000000000000000000000000000000000aaaaaaaa0a000a000a000a00066666600aaaaaa066666660a0aaa0a000000000a0aa000000000000
007007000000000066606660ddd0ddd00000000000000000a000000a0a000a000a000a00060000600a0000a060000060a00000a0a0aaa0a0a0aa0aa055000000
000770000000000000000000000000000000000000000000a0aa0a0a00aaa000a0aaa0a0060000600a0aa0a060000060a00a00a000aaa00000aa0aa055055000
000770000000000060666060d0ddd0d00000000000000000000000000a00aa00aa00aaa0066666600aaaaaa066666660aaa0aaa0a0aaa0a0a0000aa055055050
007007000005000000000000000000000000000000000000a0a0aa0a0aaaaa000aaaaa000000000000000000000000000000000000aaa000a0aa000055055050
000000000000000066606660ddd0ddd00000000000000000a000000a00aaa00000aaa000066666600aaaaaa066666660aaaaaaa0a0aaa0a0a0aa0aa055055050
000000000000000000000000000000000000000000000000aaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00666000060666000066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06066600060666000606660006666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60666660066666006066666060066666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666660066666006666666066666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06666600006660000666660006666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000606000000000000060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000
00060600006666000006060000666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000000
00666600000606660066660000060666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077700000
00060666000666660006066600066666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000000
06066666060000000006666606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000
66000000660660000660000066066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66066606660660000660660066066606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00600600006600000060060000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000050500000303030103010307020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020f010101010101010101020e01010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010101010202020201020202010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010101010201010101020101010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010101010201010101020102020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010101010201010101020101010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010101010102020202020101010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010101010101010101020101010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02020d02020202020202020202020d0200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010701020a0101010108020201010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010102010101010101020201010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010102020202020101020201010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02010601020c01010101010d0101020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010102010101010101020101010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
