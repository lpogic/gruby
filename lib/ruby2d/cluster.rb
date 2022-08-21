module Ruby2D
    module Cluster
        include Entity
        attr_reader :objects
        EventDescriptor = Struct.new(:type, :id)

        def initialize()
            @objects = []
            @event_handlers = {}

            # Unique ID for the input event being registered
            @event_key = 0
        end

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
        def on(event, &proc)
            event_id = new_event_key
            (@event_handlers[event] ||= {})[event_id] = proc
            EventDescriptor.new(event, event_id)
        end
    
        # Remove an event handler
        def off(event_descriptor)
            handlers = @event_handlers[event_descriptor.type]
            handlers.delete(event_descriptor.id) if handlers
        end

        def square(**args)
            Square.new(**args)
        end

        def rectangle(**args)
            Rectangle.new(**args)
        end

        def circle(**args)
            Circle.new(**args)
        end

        def line(**args)
            Line.new(**args)
        end

        def text(text, **args)
            Text.new(text, **args)
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