module Ruby2D
    module Cluster
        include Entity
        attr_accessor :parent
        EventDescriptor = Struct.new(:type, :id)

        def initialize()
            @entities = []
            @objects = []
            @event_handlers = {}

            # Unique ID for the input event being registered
            @event_key = 0
        end

        def add(*objects)
            objects.each do |o|
                case o
                when nil
                    raise Error, "Cannot add '#{o.class}' to window!"
                when Cluster
                    @entities.push(o)
                    o.parent = self
                when Entity
                    @entities.push(o)
                else
                    add_object(o)
                end
            end
            objects.size > 1 ? objects : objects[0]
        end

        def remove(object)
            raise Error, "Cannot remove '#{object.class}' from window!" if object.nil?
    
            collection = object.class.ancestors.include?(Ruby2D::Entity) ? @entities : @objects
            ix = collection.index(object)
            return false if ix.nil?
    
            collection.delete_at(ix)
            true
        end
    
        def clear
            @objects.clear
            @entities.clear
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
            @entities.any?{|e|e.contains?(x, y)}
        end

        def window = parent.window

        def update()
            @entities.reverse.each{|e| e.emit :update}
        end

        def render()
            @entities.each{|e| e.emit :render}
            @objects.each(&:render)
        end

        def accept_mouse(e, mouse_in = false)
            emit :mouse_in, e if mouse_in
            ent = @entities.reverse.find do |t|
                if t.contains?(e.x, e.y)
                    t.accept_mouse(e, true)
                end
            end
            return ent || self
        end

        private

        # An an object to the window, used by the public `add` method
        def add_object(object)
            if !@objects.include?(object)
                index = @objects.index do |obj|
                    obj.z > object.z
                end
                if index
                    @objects.insert(index, object)
                else
                    @objects.push(object)
                end
                true
            else
                false
            end
        end
    end
end