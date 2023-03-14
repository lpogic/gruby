module Ruby2D
  module Utils
    def self.sin(t, speed = 1, scale = 1, offset = 0, phase: 0)
      (Math.sin(t * speed * Math::PI / 500.0 + phase) * scale + scale) / 2 + offset
    end
  
    def self.cos(t, speed = 1, scale = 1, offset = 0, phase: 0)
      sin(t, speed, scale, offset, phase: Math::PI / 2 + phase)
    end
  end
end