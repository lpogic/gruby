# Zmienne wyjściowe (outpot) muszą być podane jawnie, a nie jako efekt uboczny np {@a.set _1}, ponieważ przy zmianie wejścia (inlet) musi być znany.

module Ruby2D
    module CommunicatingVesselsSystem
        def pot(*v, &block)
            pt = Pot.new
            pt.let(*v, &block)
            pt
        end
    
        def locked_pot(*v, &block)
            pt = pot(*v, &block)
            pt.lockInlet self
            pt
        end
    
        def let(*inpot, out: nil, &block)
            if block_given?
                if out.nil?
                    return Let.new(inpot, &block)
                else
                    l = Let.new(inpot, &block)
                    if out.is_a? Array
                        l.applyOutpot(*out)
                    else
                        l.applyOutpot(out)
                    end
                    l.call
                    return l
                end
            elsif inpot[0].is_a? Pot
                return inpot[0]
            else
                return Pot.new inpot[0]
            end
        end

        def initialize_let_arguments!(args)
            args.each do |k, v|
                if v.is_a? Let
                    v.inpot.map!{_1.is_a?(Pot) ? _1 : self[_1]}
                end
            end
        end
    
        private
    
        class Let
            def initialize(inpot, &block)
                @callee = block
                # raise "XD" if inpot.any?{not _1.is_a? Pot}
                @inpot = inpot
            end

            def inpot = @inpot
    
            def applyOutpot(*outpot)
                outpot.each{_1.setInlet(self)}
                @inpot.each{_1.addOutlet(self)}
                @outpot = outpot
            end

            def >>(that)
                that.is_a?(Array) ? applyOutpot(*that) : applyOutpot(that)
                self
            end
    
            def call
                return if @closed
                result = @callee.call(*@inpot.map(&:get))
                ra = result.is_a?(Array) ? result : [result]
                ra.zip(@outpot).each{|r, o| o.set r if not o.nil?}
                self
            end
    
            def close
                @closed = true
            end
    
            def open(open = true)
                raise "Canceled let open" if open and (!@callee or !@outpot)
                @closed = !open
            end
    
            def cancel
                @inpot.each{|i| i.deleteOutlet(self)}
                @inpot = nil
                @callee = nil
                @closed = true
            end
    
            def deleteOutpot(outpot)
                @outpot = @outpot.map{_1 == outpot ? nil : _1}
                cancel if @outpot.compact.empty?
            end
    
        end
    
        class Pot
            def initialize(value = nil)
                @inlet = nil
                @outlet = []
                @value = value
            end
    
            def get
                @value
            end
    
            alias value get
    
            def set(value)
                return if @set_lock
                @value = value
                @set_lock = true
                @outlet.each(&:call)
                @set_lock = false
            end
    
            def let(*v, &block)
                if block_given?
                    l = Let.new(v.map do |v1| 
                        if v1.is_a?(Pot)
                            v1
                        else
                            pot = Pot.new
                            pot.let(v1)
                            pot
                        end
                    end, &block)
                    l.applyOutpot(self)
                    l.call
                elsif v[0].is_a? Let
                    v[0].applyOutpot(self)
                    v[0].call
                elsif v[0].is_a? Pot
                    l = Let.new(v) do _1 end
                    l.applyOutpot(self)
                    l.call
                else
                    set v[0]
                end
            end

            def as(&block)
                Let.new([self], &block)
            end
    
            alias value= set
    
            def setInlet(inlet)
                raise "Locked by #{@lock}" if @lock
                @inlet.deleteOutpot(self) if @inlet
                @inlet = inlet
            end

            def lockInlet(lock)
                @lock = lock
            end

            def unlockInlet
                @lock = nil
            end
    
            def addOutlet(let)
                @outlet.append(let)
            end
    
            def deleteOutlet(let)
                @outlet.delete(let)
            end
    
            def +(that)
                if that.is_a? Pot
                    pot self, that do |a, b|
                        a + b
                    end
                else
                    pot self do |v|
                        v + that
                    end
                end
            end
        
            def -(that)
                if that.is_a? Pot
                    pot self, that do |a, b|
                        a - b
                    end
                else
                    pot self do |v|
                        v - that
                    end
                end
            end
        
            def *(that)
                if that.is_a? Pot
                    pot self, that do |a, b|
                        a * b
                    end
                else
                    pot self do |v|
                        v * that
                    end
                end
            end
        
            def /(that)
                if that.is_a? Pot
                    pot self, that do |a, b|
                        a / b
                    end
                else
                    pot self do |v|
                        v / that
                    end
                end
            end
        
            def **(that)
                if that.is_a? Pot
                    pot self, that do |a, b|
                        a ** b
                    end
                else
                    pot self do |v|
                        v ** that
                    end
                end
            end
        
            def %(that)
                if that.is_a? Pot
                    pot self, that do |a, b|
                        a % b
                    end
                else
                    pot self do |v|
                        v % that
                    end
                end
            end
        end
    end
end

class Class
    def pot_accessor(*args, **named_args)
        pot_getter(*args, **named_args)
        args.each do |arg|
            self.class_eval("def #{arg}=(val);pt = defined?(self.#{arg}_pot) ? self.#{arg}_pot : @#{arg};pt.let val;end")
        end
        named_args.each do |at, names|
            names = [names] if not names.is_a? Array
            names.each do |name|
                self.class_eval("def #{name}=(val);pt = defined?(self.#{at}_pot) ? self.#{at}_pot : @#{at};pt.let val;end")
            end
        end
    end
    def pot_getter(*args, **named_args)
        args.each do |arg|
            self.class_eval("def #{arg}(&b);pt = defined?(self.#{arg}_pot) ? self.#{arg}_pot : @#{arg}; block_given? ? pt.as(&b) : pt;end")
        end
        named_args.each do |at, names|
            names = [names] if not names.is_a? Array
            names.each do |name|
                self.class_eval("def #{name}(&b);pt = defined?(self.#{at}_pot) ? self.#{at}_pot : @#{at}; block_given? ? pt.as(&b) : pt;end")
            end
        end
    end
end