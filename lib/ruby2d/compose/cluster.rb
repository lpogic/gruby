module Ruby2D
    class Cluster
        include Entity
        attr_reader :objects
        EventDescriptor = Struct.new(:type, :id)

        def initialize()
            @objects = []
            @event_handlers = {}
            @pot_handlers = []

            # Unique ID for the input event being registered
            @event_key = 0
            @keyboard_current = pot false
        end

        pot_reader :keyboard_current

        def add(*objects)
            objects.each do |o|
                case o
                when nil
                    raise Error, "Cannot add '#{o.class}' to cluster!"
                when Entity
                    add_object(o)
                    o.parent = self
                else
                    add_object(o)
                end
            end
            objects.size > 1 ? objects : objects[0]
        end

        def remove(object)
            raise Error, "Cannot remove '#{object.class}' from cluster!" if object.nil?
    
            ix = @objects.index(object)
            return false if ix.nil?
    
            @objects.delete_at(ix)
            true
        end
    
        def clear
            @objects.clear
        end

        # Generate a new event key (ID)
        def new_event_key
            @event_key = @event_key.next
        end

        # Set an event handler
        def on(*events, &proc)
            events.each do |event|
                if event.is_a? Symbol
                    event_id = new_event_key
                    (@event_handlers[event] ||= {})[event_id] = proc
                    EventDescriptor.new(event, event_id)
                elsif event.is_a? Pot
                    prev = pot
                    let(event) do |v|
                        proc.call(v, prev.get)
                        v
                    end >> prev
                    @pot_handlers << prev
                else
                    raise "Only Symbols/Pots allowed"
                end
            end
        end
    
        # Remove an event handler
        def off(event_descriptor)
            handlers = @event_handlers[event_descriptor.type]
            handlers.delete(event_descriptor.id) if handlers
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

        def make_outfit(element, style)
            parent.make_outfit(element, style)
        end

        def button(text = 'Button', x: 100, y: 100, left: nil, right: nil, top: nil, bottom: nil, 
            style: 'default', text_size: nil, text_color: nil, round: nil, r: nil, color: nil, border: nil, b: nil, border_color: nil, 
            padding_x: nil, px: nil, padding_y: nil, py: nil, &on_click)
        
            btn = Button.new text: text, x: x, y: y, left: left, right: right, top: top, bottom: bottom, &on_click
            style = make_outfit btn, style
            btn.text_size = text_size || style.text_size
            btn.text_color = text_color || style.text_color
            btn.round = round || r || style.round
            btn.color = color || style.color
            btn.border = border || b || style.border
            btn.border_color = border_color || style.border_color
            btn.padding_x = padding_x || px || style.padding_x
            btn.padding_y = padding_y || py || style.padding_y
            btn
        end

        def emit(type, event = nil)
            ehh = @event_handlers[type]
            ehh.each_value{|eh|eh.call(event)} if ehh
            case type
            when :update
                update
            when :render
                render
            when :mouse_out
                @mouse_down = false
            when :mouse_down
                @mouse_down = true
                window.keyboard_current_object = self if window.mouse_current == self
            when :mouse_up
                if @mouse_down
                    emit :click, event
                    @mouse_down = false
                end
            end
        end

        def contains?(x, y)
            @objects.filter{_1.is_a? Entity}.any?{|e|e.contains?(x, y)}
        end

        def update()
            @objects.reverse.filter{_1.is_a? Entity}.each{|e| e.emit :update}
        end

        def render()
            @objects.each do |o|
                if o.is_a? Entity
                    o.emit :render
                else
                    o.render
                end
            end
        end

        def accept_mouse(e)
            return nil if not contains?(e.x, e.y)
            ent = @objects.reverse.filter{_1.is_a? Entity}.find{|t| t.accept_mouse(e)}
            return ent || self
        end

        def accept_keyboard(current = true)
            @keyboard_current.set current
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
            window.key_down(key) || window.key_down(key)
        end

        private

        # An an object to the window, used by the public `add` method
        def add_object(object)
            if !@objects.include?(object)
                @objects.push(object)
                true
            else
                false
            end
        end
    end
end