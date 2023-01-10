module Kernel
  alias original_require require

  def require(name)
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
    class_eval("def initialize(#{(una.map { _1.to_s + ':' } + na.map { |k, v| k.to_s + ':' + v.to_s }).join(',')});" +
       "#{(una + na.keys).map { "@#{_1} = #{_1};" }.join}end")
    attr_accessor(*una) if accessor
    attr_reader(*una) if reader and !accessor
  end

  def delegate(**na)
    make_delegate = proc do |d, fn, nfn|
      if fn =~ %r{[=+-/*%]$}
        "def #{nfn}(a); @#{d}.#{fn}(a) end"
      else
        "def #{nfn}(*a, **na, &b); @#{d}.#{fn}(*a, **na, &b) end"
      end
    end

    na.each do |k, v|
      v.each do |n|
        nx = n.split(':')
        ns = nx[0].split('\\')
        nfn = nx[1] || ns[0]
        class_eval(make_delegate.call(k, ns[0], nfn))
        ns[1..].each do |nn|
          class_eval(make_delegate.call(k, ns[0] + nn, nfn + nn))
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

class Array
  def all_in?(*o)
    o.all? { include? _1 }
  end

  def any_in?(*o)
    o.any? { include? _1 }
  end

  alias or any?
  alias and all?
end

class Hash
  def all_in?(*o)
    o.all? { has_key? _1 }
  end

  def any_in?(*o)
    o.any? { has_key? _1 }
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
Pot.debug = true

class ColRowContainer < Cluster
  def init(gap: 0, **ona)
    ona[:color] ||= 0
    care @body = new_rectangle(**ona)
    @gap = pot.let gap
  end

  def append(element, **plan)
    gs = @grid.sector(@grid.cols.get.length - 1, @grid.rows.get.length - 1, fixed: false)
    plan[:x] = gs.x unless plan_x_defined? plan
    plan[:y] = gs.y unless plan_y_defined? plan
    element.plan(**plan)
    care element
  end

  delegate body: %w[fill plan left top right bottom x y width height color round]
  def body = @body
  attr_reader :grid
end

class Row < ColRowContainer
  def init(gap: 0, **ona)
    super
    let(ona[:height] || 0, @objects.as { [_1 - [@body]] }.arrpot { _1.height }) { [_1, _2.max || 0].max } >> @body.height
    @grid = Grid.new rows: [@body.height], x: @body.x, y: @body.y
    @body.width << let(ona[:width] || 0, @grid.width) { [_1, _2].max }
  end

  def append(element, **plan)
    if element.is_a? Gap
      @grid.cols.set { |a| a + [element.size] }
      @last_gap = true
    else
      if @last_gap
        @grid.cols.set { |a| a + [element.width] }
      else
        @grid.cols.set { |a| a.empty? ? [element.width] : a + [@gap, element.width] }
      end
      @last_gap = false
      super
    end
  end
end

class Col < ColRowContainer
  def init(gap: 0, **ona)
    super
    let(ona[:width] || 0, @objects.as { [_1 - [@body]] }.arrpot { _1.width }) { [_1, _2.max || 0].max } >> @body.width
    @grid = Grid.new cols: [@body.width], x: @body.x, y: @body.y
    @body.height << @grid.height
  end

  def append(element, **plan)
    if element.is_a? Gap
      @grid.rows.set { |a| a + [element.size] }
      @last_gap = true
    else
      if @last_gap
        @grid.rows.set { |a| a + [element.height] }
      else
        @grid.rows.set { |a| a.empty? ? [element.height] : a + [@gap, element.height] }
      end
      @last_gap = false
      super

    end
  end
end

class Gap
  def initialize(size)
    @size = size
  end

  attr_reader :size
end

class Form < Arena
  def init(**plan)
    super()
    @body = new_rectangle(**plan)
  end

  delegate body: %w[fill plan x y width height left right top bottom]

  def note_row(label)
    n = nil
    row do
      col { |c| text label, right: c.right }
      col span: 2 do |c| n = note width: c.width { _1 - 20 } end
    end
    n
  end

  def button_row(col, *labels)
    btns = []
    row right: col.right { _1 - 10 }, gap: 5 do
      btns = labels.map { button _1 }
    end
    btns
  end
end

class PersonForm < Form
  def build
    margin = pot 8
    nw = pot 80
    @c0 = col do |c|
       c1 = col color: 'black', round: 8, gap: 5 do
        gap margin
        row gap: 5 do
          gap margin
          col width: nw do text 'Imię:', right: _1.right end
          @name = note
          gap margin
        end
        row gap: 5 do
          gap margin
          col width: nw do text 'Nazwisko:', right: _1.right end
          @surname = note
          gap margin
        end
        row gap: 5 do
          gap margin
          col width: nw do text 'Wiek:', right: _1.right end
          @age = note
          gap margin
        end
        row gap: 5, left: c.left do
          gap margin
          col width: nw do text 'Płeć:', right: _1.right end
          button 'Facet'
          button 'Babka'
          gap margin
        end
        gap 8
      end
      @c = col width: c1.width, color: 'yellow', round: 8, gap: 5 do |r|
        col right: r.right do
          gap margin
          row gap: 6 do
            gap margin
            @save = button 'Zapisz'
            @cancel = button 'Anuluj'
            gap margin
          end
          gap margin
        end
      end
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
    c = col color: [0.5, 0.5, 0.5], round: 12 do |_c|
      gap margin
      @r = row do
        gap margin
        @ok = button '+'
        gap 4
        @dok = button '-+'
        gap margin
      end
      gap margin
    end

    @ok.on :click do
      margin.set { _1 + 1 }
    end

    @dok.on :click do
      margin.set { _1 - 1 }
    end
  end
end

# f = OtherForm.new self, x: window.x, y: window.y
# f = PersonForm.new self, x: window.x, y: window.y
# care f
# r = rect round: [20,20,10,10], border: 8, border_color: [0,0,0,0.5], color: [1,1,1,0.5]
r = rect width: 100, border: 8, border_color: [0,0,0,0.5], color: [1,1,1,0.5]
r.round << let(r.right, r.bottom, window.mouse_x, window.mouse_y, r.top, r.left){[[
  Math.sqrt((_6 - _3) ** 2 + (_5 - _4) ** 2),
  Math.sqrt((_1 - _3) ** 2 + (_5 - _4) ** 2),
  Math.sqrt((_6 - _3) ** 2 + (_2 - _4) ** 2),
  Math.sqrt((_1 - _3) ** 2 + (_2 - _4) ** 2)
  ]]}
# l = Line.new(x1: window.x, y1: window.y, x2: window.mouse_x, y2: window.mouse_y, thick: 20, round: 9)
# care l
show
