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

module Container
end

class ColRowContainer < Cluster
   include Container

   def initialize(span: 1, **ona)
      super()
      ona[:color] ||= 0
      @body = new_rectangle **ona
      @span = pot span
      place @body
      @total_span = pot 0
      @spans = compot do |v|
         let(*v).sum >> @total_span
         v
      end.set []
   end

   attr_reader :span

   def append(element, **plan)
      gs = @grid.sector(-1, -1)
      plan[:x] = gs.x if not plan_x_defined? plan
      plan[:y] = gs.y if not plan_y_defined? plan
      plan[:width] = gs.width if not plan_w_defined?(plan) and element.is_a? Container
      plan[:height] = gs.height if not plan_h_defined?(plan) and element.is_a? Container
      element.plan **plan
      place element
   end

   delegate body: %w[fill plan left top right bottom x y width height color\=]
end

class Col < ColRowContainer

   def initialize(span: 1, **ona)
      super
      @grid = Grid.new cols: [@body.width], left: @body.left, top: @body.top
   end

   def append(element, **plan)
      if element.is_a? Row
         span = element.span
      else
         span = pot 1
      end
      @spans.set{_1 + [span]}
      @grid.rows.set{|a|a + [let(@body.height, @total_span){_1 * span.get / _2}]}
      super
   end
end

class Row < ColRowContainer

   def initialize(**ona)
      super
      @grid = Grid.new rows: [@body.height], left: @body.left, top: @body.top
   end

   def append(element, **plan)
      if element.is_a? Col
         span = element.span
      else
         span = pot 1
      end
      @spans.set{_1 + [span]}
      @grid.cols.set{|a|a + [let(@body.width, @total_span){_1 * span.get / _2}]}
      super
   end
end

class Form < Arena

   def initialize(**plan)
      super()
      @body = new_rectangle **plan
   end

   delegate body: %w[fill plan x y width height left right top bottom]

   def note_row(label)
      n = nil
      row do
         col do |c| text label, right: c.right end
         col span: 2 do |c| n = note width: c.width{_1 - 20} end
      end
      n
   end

   def button_row(*labels)
      btns = []
      row do
         labels.each do |l|
            col{btns << button(l)}
         end
      end
      btns
   end

   def build
      col color: [0.5, 0.5, 0.5], round: 8 do
         @name = note_row 'Imię:'
         @surname = note_row 'Nazwisko:'
         @age = note_row 'Age:'
         @save, @cancel = button_row 'Zapisz', 'Anuluj'
      end

      @save.on :click do
         p "Name: #{@name.text.get}, Surname: #{@surname.text.get}, Age: #{@age.text.get}"
      end

      @cancel.on :click do
         @name.text.set ''
         @surname.text.set ''
         @age.text.set ''
      end

   end
end

# f = Form.new x: window.x, y: window.y, width: 300, height: 200
# place f

def color_row
   n = nil
   r = row color: 'green' do
      n = note text: 'Choose color'
   end
   [r, n]
end

col color: 0.5, width: 400, height: 400 do
   row color: 'red' do |r|
      text 'Red', left: r.left, top: r.top
   end
   @r, @n = color_row
   row color: 'blue' do 
      @b = button 'Button'
   end
end


@b.on :click do
   @r.color = 'random'
   @n.text.set @r.color.get.to_s(opacity: false)
end

on @n.text do |t|
   begin
      @r.color = t
   rescue
   end
end


show