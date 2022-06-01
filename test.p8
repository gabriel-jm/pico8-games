pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
function _init()
  ship = {
    x = 64,
    y = 64,
    sx = 0,
    sy = 0,
  }
end

function _draw()
  cls()
  spr(1, ship.x, ship.y)
end

function _update()
  ship.sx,ship.sy = 0,0

  if (btn(0)) ship.sx = -2
  if (btn(1)) ship.sx = 2
  if (btn(2)) ship.sy = -2
  if (btn(3)) ship.sy = 2

  ship.x += ship.sx
  ship.y += ship.sy
end
-->8
function create_bullet(x, y)
  return {
    x = x,
    y = y,
    update = function(self)
      self.x-=1
    end
  }
end
__gfx__
00000000000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006776000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006776000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000006c77c600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000677777760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000006773b7760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000667337660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000066556600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000