module Kernel
  alias original_require require
  alias original_load load

  def require(name)
    if name == 'ruby2d/ruby2d'
      original_require name
    elsif name.start_with?('ruby2d')
      original_require "./lib/#{name}"
    else
      original_require name
    end
  end

  def load(name)
    if name.start_with?('ruby2d')
      original_load "./lib/#{name}"
    else
      original_load name
    end
  end
end

module Ruby2D
  def self.gem_dir
    '.'
  end

  def self.assets(path = nil)
    if path
       "#{gem_dir}/assets/#{path}"
    else 
      "#{gem_dir}/assets"
    end
  end

  def self.test_media
    "#{gem_dir}/assets/test_media"
  end
end

require 'ruby2d/core'
include Ruby2D
extend DSL

set background: 'gray', resizable: true, title: ARGV[0] || 'Ruby2D'#, diagnostics: true
on :key_down do |e|
  close confirm_required: true if e.key == 'escape'
end
window.enable_tab_callback
# Pot.debug = true

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

# f = OtherForm.new self
# p window
# f = PersonForm.new window
# care f
row color: 'yellow', x: window.x, y: window.y, gap: [2] do
  @c = col gap: [2] do |c|
    @n1 = album %w[magnez potas siarka wodór tlen azot węgiel]
    @n = note
    row width: c.width do |r|
      @b1 = button "Anuluj", left: r.left
      @b = button "Zapisz", right: r.right
    end
  end
end

@b.on :click do
  begin
    c = '#' + (1..6).map{rand(16).to_s(16)}.join
    @n1.text << c
    @a << c
  rescue
  end
end

@n.support %w[12 14 16 20 24]


show
