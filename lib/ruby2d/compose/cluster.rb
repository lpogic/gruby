module Ruby2D
  class Cluster
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

    cvs_reader :hovered, :pressed

    def initialize(parent, *una, **na, &b)
      @objects = pot []
      @parent = parent
      @event_handlers = {}
      @pot_handlers = []

      # Unique ID for the input event being registered
      @event_key = 0
      @keyboard_current = pot false
      @hovered = pot false
      @pressed = pot false
      on :mouse_down do |e|
        handle_mouse_down e
      end

      on :mouse_up do |e|
        if @pressed.get
          @pressed.set false
          emit :click, e if not pressed.get
        end
      end
      on :mouse_in do
        @hovered.set true
      end
      on :mouse_out do
        @hovered.set false
        @pressed.set false
      end

      init(*una, **na, &b)
    end

    def handle_mouse_down e
      @hovered.set true
      @pressed.set true
      window.keyboard_current_object = self if window.mouse_current == self and not @accept_keyboard_disabled
    end

    def disable(*keys)
      keys.each do |k|
        case k
        when :accept_keyboard
          @accept_keyboard_disabled = true
        else raise 'Unknown switch ' + k.to_s
        end
      end
    end

    def init
    end

    def inspect
      "#{self.class}:id:#{self.object_id}"
    end

    cvs_reader :keyboard_current

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
      objects.size > 1 ? objects : objects[0]
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

    # Generate a new event key (ID)
    def new_event_key
      @event_key = @event_key.next
    end

    def pull
      pt = pot
      @pot_handlers << pt
      pt
    end

    # Set an event handler
    def on(*events, &proc)
      r = []
      return r if not block_given?

      events.each do |event|
        if event.is_a? Symbol
          event_id = new_event_key
          ed = EventDescriptor.new(event, self)
          (@event_handlers[event] ||= {})[ed] = proc
          r << ed
        elsif event.is_a? Pot
          prev = pot
          l = let(event) do |v|
            proc.call(v, prev.get)
            v
          end
          prev.let(l, update: false)
          r << l
          @pot_handlers << prev
        else
          raise "Only Symbols/Pots allowed"
        end
      end
      r.length > 1 ? r : r[0]
    end

    def on_key key = nil, type = :key, &b
      if key.nil?
        on(type, &b)
      else
        on type do |e|
          b.(e) if key == e.key
        end
      end
    end

    # Remove an event handler
    def off(event_descriptor)
      handlers = @event_handlers[event_descriptor.type]
      handlers.delete(event_descriptor) if handlers
    end

    def new_square(**args)
      Square.new(**args)
    end

    def new_rectangle(**args)
      Rectangle.new(**args)
    end

    def new_circle(**args)
      Circle.new(**args)
    end

    def new_line(**args)
      Line.new(**args)
    end

    def new_text(text, **args)
      Text.new(text, **args)
    end

    def make_outfit(element, outfit)
      parent.make_outfit(element, outfit)
    end

    def new_button(text: 'Button', outfit: 'default', text_size: nil, text_color: nil, round: nil,
                   r: nil, color: nil, border: nil, b: nil, border_color: nil, **plan, &on_click)

      btn = Button.new self, text: text, &on_click
      outfit = make_outfit btn, outfit
      plan[:x] = 200 if not Rectangle.x_dim? plan
      plan[:y] = 100 if not Rectangle.y_dim? plan
      plan[:width] = outfit.width if not Rectangle.w_dim? plan
      plan[:height] = outfit.height if not Rectangle.h_dim? plan
      btn.plan **plan
      btn.text_size << (text_size || outfit.text_size)
      btn.text_color << (text_color || outfit.text_color)
      btn.round << (round || r || outfit.round)
      btn.color << (color || outfit.color)
      btn.border << (border || b || outfit.border)
      btn.border_color << (border_color || outfit.border_color)
      outfit.text_x
      btn
    end

    def new_note(text: '', outfit: 'default', text_font: nil, text_size: nil, text_color: nil,
                 round: nil, r: nil, color: nil, border: nil, b: nil, border_color: nil,
                 width_pad: nil, editable: nil, **plan, &on_click)

      tln = Note.new self, text: text, &on_click
      outfit = make_outfit tln, outfit
      plan[:width] = outfit.width if not Rectangle.w_dim? plan
      plan[:height] = outfit.height if not Rectangle.h_dim? plan
      plan[:x] = 200 if not Rectangle.x_dim? plan
      plan[:y] = 100 if not Rectangle.y_dim? plan
      tln.plan **plan
      tln.text_font << (text_font || outfit.text_font)
      tln.text_size << (text_size || outfit.text_size)
      tln.text_color << (text_color || outfit.text_color)
      tln.width_pad << (width_pad || outfit.width_pad)
      tln.round << (round || r || outfit.round)
      tln.color << (color || outfit.color)
      tln.border << (border || b || outfit.border)
      tln.border_color << (border_color || outfit.border_color)
      tln.editable << (editable.nil? ? outfit.editable : editable)
      tln
    end

    def new_ruby_note(text: '', outfit: 'default', text_font: nil, text_size: nil, text_color: nil,
      round: nil, r: nil, color: nil, border: nil, b: nil, border_color: nil,
      width_pad: nil, editable: nil, **plan, &on_click)

      tln = RubyNote.new self, text: text, &on_click
      outfit = make_outfit tln, outfit
      plan[:width] = outfit.width if not Rectangle.w_dim? plan
      plan[:height] = outfit.height if not Rectangle.h_dim? plan
      plan[:x] = 200 if not Rectangle.x_dim? plan
      plan[:y] = 100 if not Rectangle.y_dim? plan
      tln.plan **plan
      tln.text_font << (text_font || outfit.text_font)
      tln.text_size << (text_size || outfit.text_size)
      tln.text_color << (text_color || outfit.text_color)
      tln.width_pad << (width_pad || outfit.width_pad)
      tln.round << (round || r || outfit.round)
      tln.color << (color || outfit.color)
      tln.border << (border || b || outfit.border)
      tln.border_color << (border_color || outfit.border_color)
      tln.editable << (editable.nil? ? outfit.editable : editable)
      tln
    end

    # def new_album(outfit: 'default', **params text_font: nil, text_size: nil, text_color: nil,
    #   round: nil, r: nil, color: nil, border: nil, b: nil, border_color: nil,
    #   width_pad: nil, editable: nil, **plan)

    #   album = Album.new self
    #   outfit = make_outfit Album, outfit if not outfit.is_a? AlbumOutfit
    #   outfit.override 
    #   plan[:width] = outfit.width if not Rectangle.w_dim? plan
    #   plan[:height] = outfit.height if not Rectangle.h_dim? plan
    #   plan[:x] = 200 if not Rectangle.x_dim? plan
    #   plan[:y] = 100 if not Rectangle.y_dim? plan
    #   album.plan **plan
    #   album.text_font << (text_font || outfit.text_font)
    #   album.text_size << (text_size || outfit.text_size)
    #   album.text_color << (text_color || outfit.text_color)
    #   album.width_pad << (width_pad || outfit.width_pad)
    #   album.round << (round || r || outfit.round)
    #   album.color << (color || outfit.color)
    #   album.border << (border || b || outfit.border)
    #   album.border_color << (border_color || outfit.border_color)
    #   album.editable << (editable.nil? ? outfit.editable : editable)
    #   album
    # end

    def emit(type, event = nil)
      ehh = @event_handlers[type]
      ehh.each { |eh, pro| pro.call(event, eh) } if ehh
      case type
      when :update
        update
      when :render
        cluster_render
      when :click
        click_time = timems
        if @last_double_click_time and click_time - @last_double_click_time < 300
          emit :triple_click, event
          @last_double_click_time = nil
        elsif @last_click_time and click_time - @last_click_time < 300
          emit :double_click, event
          @last_click_time = nil
          @last_double_click_time = click_time
        else
          @last_click_time = click_time
        end
      end
    end

    def contains?(x, y)
      @objects.get.filter { _1.is_a? Entity }.any? { |e| e.contains?(x, y) }
    end

    def update()
      @objects.get.reverse.filter { _1.is_a? Entity }.each { |e| e.emit :update }
    end

    def cluster_render
      if @nanny
        return if not @nanny.rendered
      else
        return if not @parent.rendered
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
      else
        return nil if invoker != @parent
      end
      return nil if not contains?(e.x, e.y)

      am = nil
      objects = @objects.get
      objects.reverse.find { |t| t.is_a?(Entity) && (am = t.accept_mouse(e, self)) }
      return am || self
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
        return false
      else
        i = objects.find_index(current)
        ps = reverse ? objects[...i].reverse : objects[i + 1..]
        ps.filter { _1.is_a? Cluster }.each do |psi|
          return true if psi.pass_keyboard nil, reverse: reverse
        end
        return parent.pass_keyboard self, reverse: reverse
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

    def shift_down
      window.key_down('left shift') || window.key_down('right shift')
    end

    def ctrl_down
      window.key_down('left ctrl') || window.key_down('right ctrl')
    end

    def alt_down
      window.key_down('left alt') || window.key_down('right alt')
    end

    def key_down(key)
      window.key_down(key)
    end

    def clipboard
      ext_get_clipboard.force_encoding('utf-8')
    end

    def clipboard=(c)
      ext_set_clipboard c
      c
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
