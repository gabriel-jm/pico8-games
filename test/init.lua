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
