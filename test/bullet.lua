function create_bullet(x, y)
  return {
    x = x,
    y = y,
    update = function(self)
      self.x-=1
    end
  }
end