# frozen_string_literal: trueCluster

# Ruby2D::Window

module Ruby2D
  # Represents a window on screen, responsible for storing renderable graphics,
  # event handlers, the update loop, showing and closing the window.
  class Window < Cluster
    
    # Event structures
    ResizeEvent           = Struct.new(:width, :height)
    MouseEvent            = Struct.new(:type, :button, :direction, :x, :y, :delta_x, :delta_y)
    KeyEvent              = Struct.new(:type, :key)
    TextEvent             = Struct.new(:type, :text)
    ControllerEvent       = Struct.new(:which, :type, :axis, :value, :button)
    ControllerAxisEvent   = Struct.new(:which, :axis, :value)
    ControllerButtonEvent = Struct.new(:which, :button)

    #
    # Create a Window
    # @param title [String] Title for the window
    # @param width [Numeric] In pixels
    # @param height [Numeric] in pixels
    # @param fps_cap [Numeric] Over-ride the default (60fps) frames-per-second
    # @param vsync [Boolean] Enabled by default, use this to override it (Not recommended)
    def initialize(title: 'Ruby 2D', width: 640, height: 480, fps_cap: 60, vsync: true)
      super()

      # Title of the window
      @title = title

      # Window size
      @width  = pot width
      @height = pot height
      @width_value = width
      @height_value = height

      # Frames per second upper limit, and the actual FPS
      @fps_cap = fps_cap
      @fps = @fps_cap
      @timepot = pot timems

      # Vertical synchronization, set to prevent screen tearing (recommended)
      @vsync = vsync

      # Total number of frames that have been rendered
      @frames = 0

      # Renderable objects currently in the window, like a linear scene graph
      @objects = []

      @mouse_current = nil
      @mouse_owner = self
      @keyboard_current_object = self
      @key_typer = KeyTyper.new self

      _init_window_defaults
      _init_event_stores
      _init_event_registrations
      _init_procs_dsl_console
    end

    # Track open window state in a class instance variable
    @open_window = false

    # Class methods for convenient access to properties
    class << self
      def current
        get(:window)
      end

      def window
        get :window
      end

      def title
        get(:title)
      end

      def background
        get(:background)
      end

      def width
        get(:width)
      end

      def height
        get(:height)
      end

      def viewport_width
        get(:viewport_width)
      end

      def viewport_height
        get(:viewport_height)
      end

      def display_width
        get(:display_width)
      end

      def display_height
        get(:display_height)
      end

      def resizable
        get(:resizable)
      end

      def borderless
        get(:borderless)
      end

      def fullscreen
        get(:fullscreen)
      end

      def highdpi
        get(:highdpi)
      end

      def frames
        get(:frames)
      end

      def fps
        get(:fps)
      end

      def fps_cap
        get(:fps_cap)
      end

      def mouse_x
        get(:mouse_x)
      end

      def mouse_y
        get(:mouse_y)
      end

      def diagnostics
        get(:diagnostics)
      end

      def screenshot(opts = nil)
        get(:screenshot, opts)
      end

      def get(sym, opts = nil)
        DSL.window.get(sym, opts)
      end

      def set(opts)
        DSL.window.set(opts)
      end

      def on(event, &proc)
        DSL.window.on(event, &proc)
      end

      def off(event_descriptor)
        DSL.window.off(event_descriptor)
      end

      def add(object)
        DSL.window.add(object)
      end

      def remove(object)
        DSL.window.remove(object)
      end

      def clear
        DSL.window.clear
      end

      def update(&proc)
        DSL.window.update(&proc)
      end

      def render(&proc)
        DSL.window.render(&proc)
      end

      def show
        DSL.window.show
      end

      def close
        DSL.window.close
      end

      def button(*a, **na)
        DSL.window.button(*a, **na)
      end

      def render_ready_check
        return if opened?

        raise Error,
              'Attempting to draw before the window is ready. Please put calls to draw() inside of a render block.'
      end

      def opened?
        @open_window
      end

      private

      def opened!
        @open_window = true
      end
    end

    def contains?(x, y)
      (0..@width.get).include?(x) && (0..@height.get).include?(y)
    end

    def window = self
    def lineage = [self]

    def make_outfit(element, style = 'default')
      case element
      when Button
        case style
        when 'default'
            return BasicButtonStyle.new(element, Color.new('blue'), Color.new('#1084E9'), Color.new('#0064C9'), Color.new('white'), Color.new('#DFDFDF'))
        when 'green'
            return BasicButtonStyle.new(element, Color.new('#2c9b33'), Color.new('#23b22d'), Color.new('#2b642f'), Color.new('white'), Color.new('#DFDFDF'))
        end
      when Note
        case style
        when 'default'
          return BasicNoteStyle.new(
            element, 
            Color.new('#3c3c3f'), 
            Color.new('#4c4c4f'), 
            Color.new('#4c4c4f'), 
            Color.new('white'), 
            Color.new('#DFDFDF'),
            'consola'
          )
        when 'green'
          return BasicNoteStyle.new(
            element, 
            Color.new('#2c9b33'), 
            Color.new('#23b22d'), 
            Color.new('#2b642f'), 
            Color.new('white'), 
            Color.new('#DFDFDF'),
            'consola'
          )
        when 'text'
          return TextNoteStyle.new(
            element, 
            Color.new([0,0,0,0]),
            Color.new('white'),
            'consola'
          )
        end
      end
      raise "Unsupported style '#{style}' used for element #{element.class}"
    end

    cvs_reader :x, :y, :left, :top, :mouse_x, :mouse_y, :timepot, [:width, :right] => :width, [:height, :bottom] => :height

    def _cvs_left
      @left ||= locked_pot 0
    end

    def _cvs_top
      @top ||= locked_pot 0
    end

    def _cvs_x
      self.width{_1 / 2}
    end

    def _cvs_y
      self.height{_1 / 2}
    end

    def keyboard_current_object=(new_keyboard_current)
      if @keyboard_current_object != new_keyboard_current
        @keyboard_current_object.accept_keyboard false
        new_keyboard_current.accept_keyboard
        @keyboard_current_object = new_keyboard_current
      end
    end

    def mouse_current
      @mouse_current
    end

    def replace_mouse_owner(new_owner)
      o, @mouse_owner = @mouse_owner, new_owner
      o
    end

    # Getters for ruby2d_window_ext_show
    def get_width = @width.get
    def get_height = @height.get
    # Setters for ruby2d.c update
    def set_mouse_x x
      if x != @mouse_x.get
        @mouse_x.set x
      end
    end
    def set_mouse_y y
      if y != @mouse_y
        @mouse_y.set y
      end
    end

    # Public instance methods

    # --- start exception
    # Exception from lint check for the #get method which is what it is. :)
    #
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/AbcSize

    # Retrieve an attribute of the window
    # @param sym [Symbol] The name of an attribute to retrieve.
    def get(sym, opts = nil)
      case sym
      when :window then          self
      when :title then           @title
      when :background then      @background
      when :width then           @width.get
      when :height then          @height.get
      when :viewport_width then  @viewport_width
      when :viewport_height then @viewport_height
      when :display_width, :display_height
        ext_get_display_dimensions
        if sym == :display_width
          @display_width
        else
          @display_height
        end
      when :resizable then       @resizable
      when :borderless then      @borderless
      when :fullscreen then      @fullscreen
      when :highdpi then         @highdpi
      when :frames then          @frames
      when :fps then             @fps
      when :fps_cap then         @fps_cap
      when :mouse_x then         @mouse_x
      when :mouse_y then         @mouse_y
      when :diagnostics then     @diagnostics
      when :screenshot then      screenshot(opts)
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/AbcSize
    # --- end exception

    # Set a window attribute
    # @param opts [Hash] The attributes to set
    # @option opts [Color] :background
    # @option opts [String] :title
    # @option opts [Numeric] :width
    # @option opts [Numeric] :height
    # @option opts [Numeric] :viewport_width
    # @option opts [Numeric] :viewport_height
    # @option opts [Boolean] :highdpi
    # @option opts [Boolean] :resizable
    # @option opts [Boolean] :borderless
    # @option opts [Boolean] :fullscreen
    # @option opts [Numeric] :fps_cap
    # @option opts [Numeric] :diagnostics
    def set(opts)
      # Store new window attributes, or ignore if nil
      _set_any_window_properties opts
      _set_any_window_dimensions opts

      @fps_cap = opts[:fps_cap] if opts[:fps_cap]
      return if opts[:diagnostics].nil?

      @diagnostics = opts[:diagnostics]
      ext_diagnostics(@diagnostics)
    end

    # Key down event method for class pattern
    def key_down(key)
      @keys_down.include? key
    end

    # Key up event method for class pattern
    def key_up(key)
      not @keys_down.include?(key)
    end

    # Key callback method, called by the native and web extentions
    def key_callback(type, key)
      key = key.downcase

      # All key events
      emit :key, KeyEvent.new(type, key)

      case type
      # When key is pressed, fired once
      when :down
        _handle_key_down type, key
      # When key is being held down, fired every frame
      when :held
        _handle_key_held type, key
      # When key released, fired once
      when :up
        _handle_key_up type, key
      when :text
        _handle_key_text type, key
      end
    end

    # Mouse down event method for class pattern
    def mouse_down(btn)
      @mouse_buttons_down.include? btn
    end

    # Mouse up event method for class pattern
    def mouse_up(btn)
      @mouse_buttons_up.include? btn
    end

    # Mouse scroll event method for class pattern
    def mouse_scroll
      @mouse_scroll_event
    end

    # Mouse move event method for class pattern
    def mouse_move
      @mouse_move_event
    end

    # Mouse callback method, called by the native and web extentions
    def mouse_callback(type, button, direction, x, y, delta_x, delta_y)
      # All mouse events
      emit :mouse, MouseEvent.new(type, button, direction, x, y, delta_x, delta_y)

      case type
      # When mouse button pressed
      when :down
        _handle_mouse_down type, button, x, y
      # When mouse button released
      when :up
        _handle_mouse_up type, button, x, y
      # When mouse motion / movement
      when :scroll
        _handle_mouse_scroll type, direction, delta_x, delta_y
      # When mouse scrolling, wheel or trackpad
      when :move
        _handle_mouse_move type, x, y, delta_x, delta_y
      end
    end

    def resize_callback(width, height)
      emit :resize, ResizeEvent.new(width, height)

      @width.set width
      @height.set height
    end

    # Add controller mappings from file
    def add_controller_mappings
      ext_add_controller_mappings(@controller_mappings) if File.exist? @controller_mappings
    end

    # Controller axis event method for class pattern
    def controller_axis(axis)
      @controller_axes_moved.include? axis
    end

    # Controller button down event method for class pattern
    def controller_button_down(btn)
      @controller_buttons_down.include? btn
    end

    # Controller button up event method for class pattern
    def controller_button_up(btn)
      @controller_buttons_up.include? btn
    end

    # Controller callback method, called by the native and web extentions
    def controller_callback(which, type, axis, value, button)
      # All controller events
      emit :controller, ControllerEvent.new(which, type, axis, value, button)

      case type
      # When controller axis motion, like analog sticks
      when :axis
        _handle_controller_axis which, axis, value
      # When controller button is pressed
      when :button_down
        _handle_controller_button_down which, button
      # When controller button is released
      when :button_up
        _handle_controller_button_up which, button
      end
    end

    # Update callback method, called by the native and web extentions
    def update_callback
      @timepot.set timems

      update unless @using_dsl

      update

      # Accept and eval commands if in console mode
      _handle_console_input if @console && $stdin.ready?

      # Clear inputs if using class pattern
      _clear_event_stores unless @using_dsl
    end

    # Render callback method, called by the native and web extentions
    def render_callback
      render
    end

    # Show the window
    def show
      raise Error, 'Window#show called multiple times, Ruby2D only supports a single open window' if Window.opened?

      Window.send(:opened!)
      ext_show
    end

    # Take screenshot
    def screenshot(path)
      if path
        ext_screenshot(path)
      else
        time = if RUBY_ENGINE == 'ruby'
                 Time.now.utc.strftime '%Y-%m-%d--%H-%M-%S'
               else
                 Time.now.utc.to_i
               end
        ext_screenshot("./screenshot-#{time}.png")
      end
    end

    # Close the window
    def close
      ext_close
    end

    # Private instance methods

    private

    def _set_any_window_properties(opts)
      @background = Color.new(opts[:background]) if Color.valid? opts[:background]
      @title           = opts[:title]           if opts[:title]
      @icon            = opts[:icon]            if opts[:icon]
      @resizable       = opts[:resizable]       if opts[:resizable]
      @borderless      = opts[:borderless]      if opts[:borderless]
      @fullscreen      = opts[:fullscreen]      if opts[:fullscreen]
    end

    def _set_any_window_dimensions(opts)
      @width.set opts[:width]           if opts[:width]
      @height.set opts[:height]          if opts[:height]
      @viewport_width  = opts[:viewport_width]  if opts[:viewport_width]
      @viewport_height = opts[:viewport_height] if opts[:viewport_height]
      @highdpi         = opts[:highdpi] unless opts[:highdpi].nil?
    end

    def _handle_key_down(type, key)
      # For class pattern
      @keys_down << key if !@using_dsl && !(@keys_down.include? key)

      # Call event handler
      e = KeyEvent.new(type, key)
      c = @keyboard_current_object
      while c
          c.emit :key_down, e
          c = c.parent
      end
    end

    def _handle_key_held(type, key)
      # For class pattern
      @keys_down << key if !@using_dsl && !(@keys_down.include? key)

      # Call event handler
      e = KeyEvent.new(type, key)
      c = @keyboard_current_object
      while c
          c.emit :key_held, e
          c = c.parent
      end
      if @key_typer.type key
        c = @keyboard_current_object
        while c
            c.emit :key_type, e
            c = c.parent
        end
      end
    end

    def _handle_key_up(type, key)
      # For class pattern
      @keys_down.delete(key) if !@using_dsl && (@keys_down.include? key)

      # Call event handler
      e = KeyEvent.new(type, key)
      c = @keyboard_current_object
      while c
          c.emit :key_up, e
          c = c.parent
      end
      @key_typer.up
    end

    def _handle_key_text(type, text)

      # Call event handler
      e = TextEvent.new(type, text.force_encoding('utf-8'))
      c = @keyboard_current_object
      while c
          c.emit :key_text, e
          c = c.parent
      end
    end

    class KeyTyper
      def initialize(entity)
          @entity = entity
          @functional_keys = {
              'left shift' => true,
              'left ctrl' => true,
              'left alt' => true,
              'right shift' => true,
              'right ctrl' => true,
              'right alt' => true
          }.freeze
      end

      def type(key)
          return if @functional_keys[key]
          if @last_key == key
              @held_count += 1
              return @held_count > 10 && @held_count % 3 == 0              
          else
              @last_key = key
              @held_count = 0
              return true
          end
      end

      def up
          @last_key = nil
      end
    end


    def _handle_mouse_down(type, button, x, y)
      # For class pattern
      @mouse_buttons_down << button if !@using_dsl && !(@mouse_buttons_down.include? button)

      # Call event handler
      e = MouseEvent.new(type, button, nil, x, y, nil, nil)
      c = @mouse_current
      while c
          c.emit :mouse_down, e
          c = c.parent
      end
    end

    def _handle_mouse_up(type, button, x, y)
      # For class pattern
      @mouse_buttons_up << button if !@using_dsl && !(@mouse_buttons_up.include? button)

      # Call event handler
      e = MouseEvent.new(type, button, nil, x, y, nil, nil)
      c = @mouse_current
      while c
          c.emit :mouse_up, e
          c = c.parent
      end
    end

    def _handle_mouse_scroll(type, direction, delta_x, delta_y)
      # For class pattern
      unless @using_dsl
        @mouse_scroll_event     = true
        @mouse_scroll_direction = direction
        @mouse_scroll_delta_x   = delta_x
        @mouse_scroll_delta_y   = delta_y
      end

      # Call event handler
      e = MouseEvent.new(type, nil, direction, nil, nil, delta_x, delta_y)
      @mouse_current.lineage.each{_1.emit :mouse_scroll, e}
    end

    def _handle_mouse_move(type, x, y, delta_x, delta_y)
      # For class pattern
      unless @using_dsl
        @mouse_move_event   = true
        @mouse_move_delta_x = delta_x
        @mouse_move_delta_y = delta_y
      end

      # Call event handler
      e = MouseEvent.new(type, nil, nil, x, y, delta_x, delta_y)
      if @mouse_owner.contains?(x, y)
        new_mouse_current = @mouse_owner.accept_mouse(e)
        if @mouse_current.nil?
          new_mouse_current.lineage.each{_1.emit :mouse_in, e}
          @mouse_current = new_mouse_current
        elsif new_mouse_current != @mouse_current
          mc_lineage = @mouse_current.lineage
          nmc_lineage = new_mouse_current.lineage
          i = mc_lineage.zip(nmc_lineage).index{|a, b| a != b}
          mc_lineage[i..].reverse.each{_1.emit :mouse_out, e}
          mc_lineage[...i].each{_1.emit :mouse_move, e}
          nmc_lineage[i..].each{_1.emit :mouse_in, e}
          @mouse_current = new_mouse_current
        else
          @mouse_current.lineage.each{_1.emit :mouse_move, e}
        end
      end
    end

    def _handle_controller_axis(which, axis, value)
      # For class pattern
      unless @using_dsl
        @controller_id = which
        @controller_axes_moved << axis unless @controller_axes_moved.include? axis
        _set_controller_axis_value axis, value
      end

      # Call event handler
      emit :controller_axis, ControllerAxisEvent.new(which, axis, value)
    end

    def _set_controller_axis_value(axis, value)
      case axis
      when :left_x
        @controller_axis_left_x = value
      when :left_y
        @controller_axis_left_y = value
      when :right_x
        @controller_axis_right_x = value
      when :right_y
        @controller_axis_right_y = value
      end
    end

    def _handle_controller_button_down(which, button)
      # For class pattern
      unless @using_dsl
        @controller_id = which
        @controller_buttons_down << button unless @controller_buttons_down.include? button
      end

      # Call event handler
      emit :controller_button_down, ControllerButtonEvent.new(which, button)
    end

    def _handle_controller_button_up(which, button)
      # For class pattern
      unless @using_dsl
        @controller_id = which
        @controller_buttons_up << button unless @controller_buttons_up.include? button
      end

      # Call event handler
      emit :controller_button_up, ControllerButtonEvent.new(which, button)
    end

    # --- start exception
    # Exception from lint check for this method only
    #
    # rubocop:disable Lint/RescueException
    # rubocop:disable Security/Eval
    def _handle_console_input
      cmd = $stdin.gets
      begin
        res = eval(cmd, TOPLEVEL_BINDING)
        $stdout.puts "=> #{res.inspect}"
        $stdout.flush
      rescue SyntaxError => e
        $stdout.puts e
        $stdout.flush
      rescue Exception => e
        $stdout.puts e
        $stdout.flush
      end
    end
    # rubocop:enable Lint/RescueException
    # rubocop:enable Security/Eval
    # ---- end exception

    def _clear_event_stores
      @mouse_buttons_down.clear
      @mouse_buttons_up.clear
      @mouse_scroll_event = false
      @mouse_move_event = false
      @controller_axes_moved.clear
      @controller_buttons_down.clear
      @controller_buttons_up.clear
    end

    def _init_window_defaults
      # Window background color
      @background = Color.new([0.0, 0.0, 0.0, 1.0])

      # Window icon
      @icon = nil

      # Window characteristics
      @resizable = false
      @borderless = false
      @fullscreen = false
      @highdpi = false

      # Size of the window's viewport (the drawable area)
      @viewport_width = nil
      @viewport_height = nil

      # Size of the computer's display
      @display_width = nil
      @display_height = nil
    end

    def _init_event_stores
      _init_key_event_stores
      _init_mouse_event_stores
      _init_controller_event_stores
    end

    def _init_key_event_stores
      # Event stores for class pattern
      @keys_down = []
    end

    def _init_mouse_event_stores
      @mouse_buttons_down = []
      @mouse_buttons_up   = []
      @mouse_scroll_event     = false
      @mouse_scroll_direction = nil
      @mouse_scroll_delta_x   = 0
      @mouse_scroll_delta_y   = 0
      @mouse_move_event   = false
      @mouse_move_delta_x = 0
      @mouse_move_delta_y = 0
    end

    def _init_controller_event_stores
      @controller_id = nil
      @controller_axes_moved   = []
      @controller_axis_left_x  = 0
      @controller_axis_left_y  = 0
      @controller_axis_right_x = 0
      @controller_axis_right_y = 0
      @controller_buttons_down = []
      @controller_buttons_up   = []
    end

    def _init_event_registrations
      # Mouse X and Y position in the window
      @mouse_x = pot 0
      @mouse_y = pot 0

      # Controller axis and button mappings file
      @controller_mappings = "#{File.expand_path('~')}/.ruby2d/controllers.txt"
    end

    

    def _init_procs_dsl_console
    
      # Detect if window is being used through the DSL or as a class instance
      @using_dsl = !(method(:update).parameters.empty? || method(:render).parameters.empty?)

      # Whether diagnostic messages should be printed
      @diagnostics = false

      # Console mode, enabled at command line
      @console = if RUBY_ENGINE == 'ruby'
                   ENV['RUBY2D_ENABLE_CONSOLE'] == 'true'
                 else
                   false
                 end
    end
  end
end
