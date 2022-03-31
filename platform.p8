pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
function _init()
	_upd=update_start
	_drw=draw_start
end

function _update()
	_upd()
end

function _draw()
	_drw()
end
-->8
-- updates

function update_start()
	if btnp(❎) then
		_upd=update_game
		_drw=draw_game
	end
end

function update_game()

end
-->8
-- draw

function draw_start()
	cls()
	print(
		"press ❎ to start",
		20,
		30
	)
end

function draw_game()
	print(
		"pressed",
		20,
		50
	)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
