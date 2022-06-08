-- update

function update_game()
  ship.sx,ship.sy = 0,0

  if (btn(0)) ship.sx = -2
  if (btn(1)) ship.sx = 2
  if (btn(2)) ship.sy = -2
  if (btn(3)) ship.sy = 2

  ship.x += ship.sx
  ship.y += ship.sy
end
