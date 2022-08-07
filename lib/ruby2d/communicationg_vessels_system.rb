module Ruby2D
    module CommunicatingVesselsSystem
        def pot(*v, &block)
            pot = Pot.new
            pot.let(*v, &block)
            pot
        end
    
        def pot_view(*v, &block)
            pot = PotView.new
            pot.let(*v, &block)
            pot
        end
    
        def let(*inpot, out: nil, &block)
            if block_given?
                if out.nil?
                    return Let.new(inpot, &block)
                else
                    l = Let.new(inpot, &block)
                    l.applyOutpot(out.is_a?(Array) ? out : [out])
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
                @inpot = inpot
            end

            def inpot = @inpot
    
            def applyOutpot(outpot)
                outpot.each{_1.setInlet(self)}
                @inpot.each{_1.addOutlet(self)}
                @outpot = outpot
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
                    l.applyOutpot([self])
                    l.call
                elsif v[0].is_a? Let
                    v[0].applyOutpot([self])
                    v[0].call
                elsif v[0].is_a? Pot
                    CommunicatingVesselsSystem::let v[0], out: self do _1 end.call
                else
                    set v[0]
                end
            end
    
            alias value= set
    
            def setInlet(inlet)
                @inlet.deleteOutpot(self) if @inlet
                @inlet = inlet
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

        class PotView < Pot
        end
    end
end

class Class
    def pot_accessor(*args, **named_args)
        args.each do |arg|
            self.class_eval("def #{arg};@#{arg}.get;end")
            self.class_eval("def #{arg}!;@#{arg};end")
            self.class_eval("def #{arg}=(val);@#{arg}.set val;end")
        end
        named_args.each do |name, at|
            self.class_eval("def #{name};@#{at}.get;end")
            self.class_eval("def #{name}!;@#{at};end")
            self.class_eval("def #{name}=(val);@#{at}.set val;end")
        end
    end
    def pot_reader(*args)
        args.each do |arg|
            self.class_eval("def #{arg};#{arg}!.get;end")
        end
    end
end