module Ruby2D
    class Let
        def initialize(v = nil, &b)
            set(v, &b)
        end
    
        def set(v = nil, &b)
            if block_given?
                @b = b
            elsif v.is_a? Let
                @b = v.get_proc
            elsif v.is_a? Proc
                @b = v
            else
                @b = ->{v}
            end
        end
    
        def get
            @b.call
        end
    
        def +(that)
            if that.is_a? Let
                Let.new{get + that.get}
            else
                Let.new{get + that}
            end
        end
    
        def -(that)
            if that.is_a? Let
                Let.new{get - that.get}
            else
                Let.new{get - that}
            end
        end
    
        def *(that)
            if that.is_a? Let
                Let.new{get * that.get}
            else
                Let.new{get * that}
            end
        end
    
        def /(that)
            if that.is_a? Let
                Let.new{get / that.get}
            else
                Let.new{get / that}
            end
        end
    
        def **(that)
            if that.is_a? Let
                Let.new{get ** that.get}
            else
                Let.new{get ** that}
            end
        end
    
        def %(that)
            if that.is_a? Let
                Let.new{get % that.get}
            else
                Let.new{get % that}
            end
        end
    
        protected
    
        def get_proc = @b
    end

    module Letfull
        def let(l = Let.new)
            l.is_a?(Let) ? l : Let.new(l)
        end
    end
end

class Class
    def let_accessor(*args, **named_args)
        args.each do |arg|
            self.class_eval("def #{arg};@#{arg}.get;end")
            self.class_eval("def #{arg}=(val);@#{arg}.set val;end")
        end
        named_args.each do |a, n|
            self.class_eval("def #{n};@#{a}.get;end")
            self.class_eval("def #{n}=(val);@#{a}.set val;end")
        end
    end
end