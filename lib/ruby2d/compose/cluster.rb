module Ruby2D
  class Cluster
    extend Builder
    include Entity

    attr_reader :objects, :rendered

    class EventDescriptor
      attr_reader :type

      def initialize(type, cluster)
        @type = type
        @cluster = cluster
      end

      def cancel
        @cluster.off self
      end
    end

    cvsa :hovered, :pressed

    def initialize(parent, *una, name: nil, **na)
      @objects = pot []
      @parent = parent
      @event_handlers = {}
      @pot_handlers = []
      self.name name

      @keyboard_current = pot false
      @hovered = pot false
      @pressed = pot false
      on :mouse_down do |e|
        handle_mouse_down e
      end

      on :mouse_up do |e|
        if @pressed.get
          @pressed.set false
          emit :click, e if !pressed.get
        end
      end
      on :mouse_in do
        @hovered.set true
      end
      on :mouse_out do
        @hovered.set false
        @pressed.set false
      end

      init(*una, **na)
      dress **na
    end

    def handle_mouse_down e
      @hovered.set true
      @pressed.set true
      window.keyboard_current_object = self if (window.mouse_current == self) && !@accept_keyboard_disabled
    end

    def init(*)
    end

    def dress(*)
    end

    def inspect
      "#{self.class}:id:#{object_id}"
    end

    def des(filter = nil, &b)
      if filter.is_a? Array
        r = filter.map{ des _1 }.reduce(:union)
        return r
      else
        o = @objects.get
        o0 = case filter
        when nil then o
        when Class then o.select{ _1.is_a? filter }
        when Symbol then o.select{ _1.names.include? filter }
        else o.select{ filter.to_proc.call _1 }
        end
        o0 = o0.filter(&b) if block_given?
        r = o.map{ _1.des filter, &b }.reduce o0, :+
        return r
      end
    end

    def [](*names, &b)
      des(names).proxy self, &b
    end

    def update
      @objects.get.reverse.filter { _1.is_a? Entity }.each { |e| e.emit :update }
    end

    def outfit(*path)
      parent.outfit(*path)
    end

    def disable(*keys)
      keys.each do |k|
        case k
        when :accept_keyboard
          @accept_keyboard_disabled = true
        else raise "Unknown switch " + k.to_s
        end
      end
    end

    cvsa :keyboard_current

    def keyboard_current?
      @keyboard_current.get
    end

    def care(*objects, nanny: false)
      @objects.set { _1.union(objects) }
      objects.filter { _1.is_a? Entity }.each do |o|
        if nanny
          o.nanny = self
        else
          o.parent = self
        end
      end
      (objects.size > 1) ? objects : objects[0]
    end

    def leave(*objects)
      @objects.set { _1.difference(objects) }
      objects.filter { _1.is_a? Entity }.each do |o|
        o.nanny = nil if o.nanny == self
        o.parent = nil if o.parent == self
      end
    end

    def leave_all
      @objects << []
    end

    def pull
      pt = pot pull: true
      @pot_handlers << pt
      pt
    end

    # Set an event handler
    def on(*events, &b)
      r = []
      return r if !b
      events.each do |event|
        if event.is_a? Symbol
          ed = EventDescriptor.new(event, self)
          (@event_handlers[event] ||= {})[ed] = b
          r << ed
        elsif event.is_a? Pot
          prev = pot pull: true
          l = let(event, sublet_enabled: true) do |v|
            b.call v, prev.get
            v
          end
          prev.let(l, pull: false)
          r << l
          @pot_handlers << prev
        else
          raise "Only Symbols/Pots allowed, #{event} given"
        end
      end
      (r.length > 1) ? r : r[0]
    end

    def on_key key = nil, type = :key, &b
      if key.nil?
        on(type, &b)
      else
        on type do |e|
          b.call(e) if key == e.key
        end
      end
    end

    # Remove an event handler
    def off(event_descriptor)
      handlers = @event_handlers[event_descriptor.type]
      handlers&.delete(event_descriptor)
    end

    builder :rect do |**na|
      Rectangle.new(**na)
    end

    builder :line do |**na|
      Line.new(**na)
    end

    builder :raw_text do |text, **na|
      Text.new(text, **na)
    end

    builder :text do |t = nil, plan_dim: true, **plan|
      e = TextNote.new self, text: t || plan[:text] || "", name: plan[:name]
      plan[:color] ||= [0,0,0,0]
      plan[:border_color] ||= [0,0,0,0]
      plan[:text_color] ||= "white"
      plan[:border] ||= 0
      plan[:round] ||= 0
      plan[:text_size] ||= 14
      plan[:text_font] ||= "rubik-regular"
      if plan_dim
      plan[:x] = 200 if !Rectangle.x_dim? plan
      plan[:y] = 100 if !Rectangle.y_dim? plan
      end
      plan[:width] = let(e.text_font, e.text) { _1.size(_2)[:width] + 1 } if !Rectangle.w_dim? plan
      plan[:width_pad] = 0
      plan[:height] = e.raw_text.height { _1 + 3 } if !Rectangle.h_dim? plan
      e.plan **plan
      return e
    end

    def _button_plan e, plan_dim: true, **plan
      plan[:color_rest] ||= "#2c2c8f"
      plan[:color_hovered] ||= "#4c4c4f"
      plan[:color_pressed] ||= "#5c5c5f"
      plan[:border_color_rest] ||= plan[:border_color] || "blue"
      plan[:border_color_keyboard_current] ||= "#7b00ae"
      plan[:text_color_rest] ||= "white"
      plan[:text_color_pressed] ||= "#DFDFDF"
      plan[:border] ||= 1
      plan[:round] ||= 12
      plan[:text_size] ||= 16
      plan[:text_font] ||= "consola"
      plan[:x] = 200 if !Rectangle.x_dim? plan
      plan[:y] = 100 if !Rectangle.y_dim? plan
      plan[:width] = e.raw_text.width { _1 + 20 } if !Rectangle.w_dim? plan
      plan[:height] = e.raw_text.height{ _1 + 10 } if !Rectangle.h_dim? plan
      return plan
    end

    builder :button do |n = nil, t = nil, plan_dim: true, **plan|
      e = Button.new self, text: t || plan[:text] || n || plan[:name] || "Button", name: n || plan[:name]
      plan = _button_plan e, **plan
      e.plan **plan
      return e
    end

    builder :option_button do |n = nil, t = nil, plan_dim: true, **plan|
      e = OptionButton.new self, text: t || plan[:text] || n || plan[:name] || "Button", name: n || plan[:name]
      plan[:round] ||= 0
      plan[:border_color] ||= [0,0,0,0]
      plan[:color_rest] ||= "#2c2c2f"
      plan[:color_hovered] ||= "#4c4c4f"
      plan[:color_pressed] ||= "#5c5c5f"
      plan = _button_plan e, **plan
      e.plan **plan
      return e
    end

    def _note_plan e, plan_dim: true, **plan
      plan[:color_rest] ||= "#3c3c3f"
      plan[:color_hovered] ||= "#4c4c4f"
      plan[:border_color_rest] ||= plan[:border_color] || "blue"
      plan[:border_color_keyboard_current] ||= "#7b00ae"
      plan[:text_color_rest] ||= "white"
      plan[:text_color_pressed] ||= "#DFDFDF"
      plan[:border] ||= case_let e.keyboard_current, 1, 0
      plan[:round] ||= 12
      plan[:text_size] ||= 16
      plan[:text_font] ||= "consola"
      plan[:x] = 200 if !Rectangle.x_dim? plan
      plan[:y] = 100 if !Rectangle.y_dim? plan
      plan[:width] = 200 if !Rectangle.w_dim? plan
      plan[:width_pad] ||= 20
      plan[:height] = e.raw_text.height{ _1 + 10 } if !Rectangle.h_dim? plan
      return plan
    end

    builder :note do |n = nil, t = nil, **plan|
      e = Note.new self, text: t || plan[:text] || "", name: n || plan[:name]
      plan = _note_plan e, **plan
      e.plan **plan
      return e
    end

    builder :ruby_note do |n = nil, t = nil, **plan|
      e = RubyNote.new self, text: t || plan[:text] || "", name: n || plan[:name]
      plan = _note_plan e, **plan
      e.plan **plan
      return e
    end

    builder :album do |o = nil, **plan|
      e = Album.new self, options: o || options || [], name: plan[:name]
      plan = _note_plan e, **plan
      plan[:text_color_object_absent] ||= "AAAA11"
      plan[:text_color_pressed_object_absent] ||= "9A9A11"
      plan[:text_font_object_absent] ||= "consolai"
      e.plan **plan
      return e
    end

    def emit(type, event = nil)
      case type
      when :update
        update
      when :render
        cluster_render
      when :click
        click_time = timems
        if @last_double_click_time && (click_time - @last_double_click_time < 300)
          emit :triple_click, event
          @last_double_click_time = nil
        elsif @last_click_time && (click_time - @last_click_time < 300)
          emit :double_click, event
          @last_double_click_time = click_time
        end
        @last_click_time = click_time
      end
      ehh = @event_handlers[type]
      ehh&.each { |eh, pro| pro.call(event, eh) }
    end

    def contains?(x, y)
      @objects.get.filter { _1.is_a? Entity }.any? { |e| e.contains?(x, y) }
    end

    def cluster_render
      if @nanny
        return if !@nanny.rendered
      elsif !@parent.rendered
        return
      end
      @rendered = true
      render
      @rendered = false
    end

    def render
      @objects.get.each do |o|
        if o.is_a? Entity
          o.emit :render
        else
          o.render
        end
      end
    end

    def accept_mouse(e, invoker)
      if @nanny
        return nil if invoker != @nanny
      elsif invoker != @parent
        return nil
      end
      return nil if !contains?(e.x, e.y)

      am = nil
      objects = @objects.get
      objects.reverse.find { |t| t.is_a?(Entity) && (am = t.accept_mouse(e, self)) }
      am || self
    end

    def accept_keyboard(current = true)
      @keyboard_current.set current
    end

    def pass_keyboard(current, reverse: false)
      objects = @objects.get
      if current.nil?
        ps = reverse ? objects.reverse : objects
        ps.filter { _1.is_a? Cluster }.each do |psi|
          return true if psi.pass_keyboard nil, reverse: reverse
        end
        false
      else
        i = objects.find_index(current)
        ps = reverse ? objects[...i].reverse : objects[i + 1..]
        ps.filter { _1.is_a? Cluster }.each do |psi|
          return true if psi.pass_keyboard nil, reverse: reverse
        end
        parent.pass_keyboard self, reverse: reverse
      end
    end

    def enable_text_input(enable = true)
      if enable
        ext_start_text_input
      else
        ext_stop_text_input
      end
    end

    def disable_text_input
      enable_text_input false
    end

    delegate parent: %w[key_modifiers shift_down ctrl_down alt_down gui_down caps_locked num_locked scroll_locked]

    def key_down(key)
      window.key_down(key)
    end

    def clipboard
      ext_get_clipboard.force_encoding("utf-8")
    end

    def clipboard=(c)
      ext_set_clipboard c
      return c
    end

    private

    # An an object to the window, used by the public `add` method
    def add_object(object)
      objects = @objects.get
      if !objects.include?(object)
        @objects.set objects.push(object)
        true
      else
        false
      end
    end
  end
end
