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

   def delegate(**na)

      make_delegate = proc do |d, fn|
         if fn =~ /[=+-\/*%]$/
            "def #{fn}(a); @#{d}.#{fn}(a) end"
         else
            "def #{fn}(*a, **na, &b); @#{d}.#{fn}(*a, **na, &b) end"
         end
      end

      na.each do |k, v|
         v.each do |n|
            ns = n.split('\\')
            self.class_eval(make_delegate.(k, ns[0]))
            ns[1..].each do |nn|
               self.class_eval(make_delegate.(k, ns[0] + nn))
            end
         end
      end
   end
end

class Object

   def timems
       now = Time.now
       (now.to_i * 1e3 + now.usec / 1e3).to_i
   end
 
   def array
     is_a?(Array) ? self : [self]
   end
 end


require 'ruby2d/core'
include Ruby2D
extend DSL
include CommunicatingVesselSystem



class Array
   def all_in?(*o)
     o.all?{include? _1}
   end

   def any_in?(*o)
      o.any?{include? _1}
   end

   alias or any?
   alias and all?
 end
 class Hash
   def all_in?(*o)
     o.all?{has_key? _1}
   end

   def any_in?(*o)
      o.any?{has_key? _1}
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
window.enable_tab_callback


class ColRowContainer < Cluster

   def initialize(gap: 0, **ona)
      super()
      ona[:color] ||= 0
      @body = new_rectangle **ona
      place @body
      @gap = pot gap
   end

   def append(element, **plan)
      gs = @grid.sector(-1, -1)
      plan[:x] = gs.x if not plan_x_defined? plan
      plan[:y] = gs.y if not plan_y_defined? plan
      element.plan **plan
      place element
   end

   delegate body: %w[fill plan left top right bottom x y width height color\=]
end

class Row < ColRowContainer

   def initialize(gap: 0, **ona)
      @height = pot 0
      super
      h = ona[:height] || @height
      @grid = Grid.new rows: [h], left: @body.left, top: @body.top
      @body.width = @grid.width
      @body.height = h
   end

   def append(element, **plan)
      @grid.cols.set{|a|a.empty? ? [element.width] : a + [@gap, element.width]}
      super
      let(*@objects.map{_1.height}).max >> @height
   end
end

class Col < ColRowContainer

   def initialize(gap: 0, **ona)
      @width = pot 0
      super
      w = ona[:width] || @width
      @grid = Grid.new cols: [w], left: @body.left, top: @body.top
      @body.width = w
      @body.height = @grid.height
   end

   def append(element, **plan)
      @grid.rows.set{|a|a.empty? ? [element.height] : a + [@gap, element.height]}
      super
      let(*@objects.map{_1.width}).max >> @width
   end
end

class Form < Arena

   def initialize(**plan)
      super()
      @body = new_rectangle **plan
   end

   delegate body: %w[fill plan x y width height left right top bottom contains?]

   def note_row(label)
      n = nil
      row do
         col do |c| text label, right: c.right end
         col span: 2 do |c| n = note width: c.width{_1 - 20} end
      end
      n
   end

   def button_row(col, *labels)
      btns = []
      row right: col.right{_1 - 10}, gap: 5 do
         btns = labels.map{button _1}
      end
      btns
   end

end


class PersonForm < Form
   def build
      margin = pot 4
      col color: [0.5, 0.5, 0.5], round: 8, gap: 6 do |c|
         row margin
         row gap: 5 do
            col margin
            col width: 80 do text "Imię:", right: _1.right end
            @name = note
            col margin
         end
         row gap: 5 do
            col margin
            col width: 80 do text "Nazwisko:", right: _1.right end
            @surname = note
            col margin
         end
         row gap: 5 do
            col margin
            col width: 80 do text "Wiek:", right: _1.right end
            @age = note
            col margin
         end
         row 2
         @c = row gap: 5, right: c.right do
            col margin
            @save = button "Zapisz"
            @cancel = button "Anuluj"
            col margin
         end
         row margin
      end

      @save.on :click do
         p "Name: #{@name.text.get}, Surname: #{@surname.text.get}, Age: #{@age.text.get}"
      end

      @cancel.on :click do
         @name.text.set ''
         @surname.text.set ''
         @age.text.set ''
         margin.set{_1 + 1}
      end
   end
end

class OtherForm < Form
   def build
      margin = pot 4
      col color: [0.5, 0.5, 0.5], round: 8, gap: 6 do |c|
         row do
            col margin
            # col margin
         end
         # row margin
         # row gap: 5 do
            # col margin
            # @cancel = button "Anuluj"
            # col margin
         # end
         # row margin
      end

      puts margin.nod.join("\n")

      # @cancel.on :click do
      #    margin.set{_1 + 1}
      # end
   end
end

f = OtherForm.new x: window.x, y: window.y
place f

# p Pot.instances
# p Let.instances
p Rectangle.instances

show