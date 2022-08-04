module Ruby2D
    module Cluster
        def initialize()
            @entities = []
            @objects = []
            @update_proc = proc {}
            @render_proc = proc {}
        end

        def add(object)
            case object
            when nil
                raise Error, "Cannot add '#{object.class}' to window!"
            when Entity
                @entities.push(object)
            when Array
                object.each { |x| add_object(x) }
            else
                add_object(object)
            end
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

        def send(type, event)

        end

        def contains?(x, y)
            @entities.any?{|e|e.contains?(x, y)}
        end

        def parent = nil

        def update(&proc)
            @update_proc = proc
            true
        end
    
        def render(&proc)
            @render_proc = proc
            true
        end

        def prot_update()
            @update_proc.call

            @entities.reverse.each(&:prot_update)
        end

        def prot_render()
            @render_proc.call

            @entities.each(&:prot_render)
            @objects.each(&:render)
        end

        def accept_mouse(e, mouse_in = false)
            ent = @entities.reverse.find do |t|
                if t.contains?(e.x, e.y)
                    t.accept_mouse(e, true)
                end
            end
            send :mouse_in, e if mouse_in
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