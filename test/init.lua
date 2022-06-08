-- init

function _init()
  upd=update_game
  drw=draw_game

  ship = {
    x = 64,
    y = 64,
    sx = 0,
    sy = 0,
  }

  stars={}
  for i=1,100 do
    add(stars, {
      x=flr(rnd(128)),
      y=flr(rnd(128)),
      spr=rnd(1.5)+0.5
    })
  end
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
