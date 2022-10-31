module Kernel
   alias_method :original_require, :require
  
   def require name
      if name == 'ruby2d/ruby2d'
         original_require name
      elsif name.start_with?('ruby2d')
         original_require "./lib/#{name}"
      else
         original_require name
      end
   end
end

class Class
   def hash_init(*una, accessor: false, reader: false, **na)
      self.class_eval("def initialize(#{(una.map{_1.to_s + ':'} + na.map{|k, v| k.to_s + ':' + v.to_s}).join(',')});" + 
         "#{(una + na.keys).map{"@#{_1} = #{_1};"}.join}end")
      attr_accessor *una if accessor
      attr_reader *una if reader and not accessor
  end
end


require 'ruby2d/core'
include Ruby2D
extend DSL
include CommunicatingVesselSystem

class Object
   def timems
       now = Time.now
       (now.to_i * 1e3 + now.usec / 1e3).to_i
   end
 
   def array
     is_a?(Array) ? self : [self]
   end
 end

class Array
 
   def all_in?(*o)
     o.all?{include? _1}
   end

   def any_in?(*o)
      o.any?{include? _1}
   end
 end

 module Gmath
   def self.sin(t, speed = 1, scale = 1, offset = 0, phase: 0)
      (Math.sin(t * speed * Math::PI / 500.0 + phase) * scale + scale) / 2 + offset
   end

   def self.cos(t, speed = 1, scale = 1, offset = 0, phase: 0)
      sin(t, speed, scale, offset, Math::PI / 2 + phase)
   end

 end

set background: 'gray', resizable: true
on :key_down do |e|
    close if e.key == 'escape'
end

class Box
   include Planned

   def initialize(object, v: nil, h: nil, left: nil, right: nil, top: nil, bottom: nil)
      @object = object
      @ls = pot(left || h || 0)
      @rs = pot(right || h || 0)
      @ts = pot(top || v || 0)
      @bs = pot(bottom || v || 0)
   end

   def _default_plan(x: nil, y: nil, left: nil, right: nil, top: nil, bottom: nil)
      if x
        let(x, @ls, @rs){_1 + _2 / 2 - _3 / 2} >> @object.x
      elsif left
         let(left, @ls, @object.width){_1 + _2 + _3 / 2} >> @object.x
      elsif right
         let(right, @rs, @object.width){_1 - _2 - _3 / 2} >> @object.x
      end

      if y
         let(y, @ts, @bs){_1 + _2 / 2 - _3 / 2} >> @object.y
       elsif left
          let(left, @ts, @object.height){_1 + _2 + _3 / 2} >> @object.y
       elsif right
          let(right, @bs, @object.height){_1 - _2 - _3 / 2} >> @object.y
       end
    end

    cvs_accessor :x, :y, :width, :height, :left, :right, :top, :bottom
    
    def _cvs_left
      let(@object.left, @ls){_1 - _2}
    end

    def _cvs_right
      let(@object.right, @rs){_1 + _2}
    end

    def _cvs_top
      let(@object.top, @ts){_1 - _2}
    end

    def _cvs_bottom
      let(@object.bottom, @bs){_1 + _2}
    end

    def _cvs_x
      let(@object.x, @ls, @rs){_1 - _2 / 2 + _3 / 2}
    end

    def _cvs_y
      let(@object.y, @ts, @bs){_1 - _2 / 2 + _3 / 2}
    end

    def _cvs_width
      let(@object.width, @ls, @rs).sum
    end

    def _cvs_height
      let(@object.height, @ts, @bs).sum
    end
end

class Form < Cluster
   def initialize(**plan)
      super()
      @body = new_rectangle color: [0.4], r: 6,  **plan
      @grid = FitGrid.new x: @body.x, y: @body.y
      @body.width = @grid.width{_1 + 10}
      @body.height = @grid.height{_1 + 10}
      place @body
   end

   def add_row(label)
      l = new_note text: label, style: 'text'
      n = new_note
      r = @grid.rows.get.length
      @grid.arrange(Box.new(l, h: 10), 0, r, :right)
      @grid.arrange(n, 1, r)
      place l, n
   end

   def contains?(x, y)
      @body.contains?(x, y)
   end
end

f = Form.new x: window.x, y: window.y
place f
f.add_row 'Imię:'
f.add_row 'Nazwisko:'
# speed = 2
# size = 20
# t = FitGrid.new(x: mouse_x, y: mouse_y)
# r1 = place new_rectangle color: 'red', width: timepot.as{Gmath.sin(_1, speed, size, size, phase: Math::PI * 0 / 2)}, height: timepot.as{Gmath.sin(_1, speed, size, size, phase: Math::PI * 0 / 2)}
# r2 = place new_rectangle color: 'green', width: timepot.as{Gmath.sin(_1, speed, size, size, phase: Math::PI * 2 / 2)}, height: timepot.as{Gmath.sin(_1, speed, size, size, phase: Math::PI * 2 / 2)}
# r3 = place new_rectangle color: 'blue', width: timepot.as{Gmath.sin(_1, speed, size, size, phase: Math::PI * 3 / 2)}, height: timepot.as{Gmath.sin(_1, speed, size, size, phase: Math::PI * 3 / 2)}
# r4 = place new_rectangle color: 'yellow', width: timepot.as{Gmath.sin(_1, speed, size, size, phase: Math::PI * 1 / 2)}, height: timepot.as{Gmath.sin(_1, speed, size, size, phase: Math::PI * 1 / 2)}
# t.arrange r1, 0, 0, :right, :bottom
# t.arrange r2, 1, 1, :top, :left
# t.arrange r3, 0, 1, :right, :top
# t.arrange r4, 1, 0, :left, :bottom
# place (n = new_note(text: "0", left: 50, top: 50))
# n.on :key_type do |e|
#    if e.key == 'return'
#       @t.set n.text.get.to_i
#    end
# end
show