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

class Object
  def timems
    now = Time.now
    ((now.to_i * 1e3) + (now.usec / 1e3)).to_i
  end

  def array
    is_a?(Array) ? self : [self]
  end
end

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

require 'ruby2d/core'
include Ruby2D
extend DSL

set background: 'gray', resizable: true
on :key_down do |e|
  close if e.key == 'escape'
end
window.enable_tab_callback
Pot.debug = true

class Form < Cluster
  include Arena

  def init(**plan)
    super()
    @body = new_rectangle(**plan)
    @margin = pot 8
    @nw = pot 80
  end

  delegate body: %w[fill plan x y width height left right top bottom]
  cvs_reader :margin

  def note_row(label, ruby_note_enabled: false)
    a = nil
    row gap: 5 do
      gap @margin
      col width: @nw do text label, right: _1.right end
      a = ruby_note_enabled ? ruby_note : note
      a.on a.keyboard_current do |kc|
        a.text.set { _1.capitalize } unless kc
      end
      gap @margin
    end
    a
  end

  def album_row(label, _options)
    a = nil
    row gap: 5 do
      gap @margin
      col width: @nw do text label, right: _1.right end
      a = note
      gap @margin
    end
    a
  end

  def button_row(*labels)
    btns = []
    row gap: 5 do
      gap @margin
      btns = labels.map { button _1 }
      gap @margin
    end
    btns
  end
end

class PersonForm < Form
  def build
    margin = @margin
    nw = @nw
    @c0 = col do |_c|
      c1 = col color: 'black', round: [8, 8, 0, 0], gap: 5 do
        gap margin
        @name = note_row 'Imię:'
        @surname = note_row 'Nazwisko:'
        @age = note_row 'Wiek:', ruby_note_enabled: true
        @sex = album_row 'Płeć:', %w[Facet Babka]
        gap 8
      end
      @c = col width: c1.width, color: 'yellow', round: [0, 0, 8, 8], gap: 5 do |r|
        col right: r.right do
          gap 8
          @save, @cancel = button_row 'Zapisz', 'Anuluj'
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
      @margin.set { _1 + 1 }
    end
    p "XD"
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
        @dok = button '-'
        gap margin
      end
      gap margin
    end

    @ok.on :click do
      margin.value += 1
    end

    @dok.on :click do
      margin.value -= 1
    end
  end
end
note

# f = OtherForm.new self
# p window
# f = PersonForm.new window
# care f

@c = col color: 'yellow' do |c|
  @n = note
  @b = button width: c.width{_1 - 5}
end

@b.on :click do
  @n.width.value += 30
end

show
