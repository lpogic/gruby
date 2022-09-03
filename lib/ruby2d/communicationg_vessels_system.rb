# SYSTEM ZMIENNYCH POWIĄZANYCH TYPU PUSH

# Zmienne wyjściowe (outpot) muszą być podane jawnie, a nie jako efekt uboczny np {@a.set _1}, ponieważ przy zmianie wejścia (inlet), stare musi być znane.
require 'weakref'

module Ruby2D
    module CommunicatingVesselsSystem
        def pot(*v, locked: false, &block)
            pt = Pot.new
            pt.let(*v, &block)
            pt.lock_inlet self if locked
            pt
          end
          
          def locked_pot(*v, &block)
            pot(*v, locked: true, &block)
          end
          
          def pot_affect(*inpot, &affect)
            pt = pot
            inpot = inpot.map{_1.is_a?(Pot) ? _1 : pot(_1)}
            PotAffect.new(pt) do |a|
                pt.let(a, *inpot){|*v| affect.call *v}
            end
          end
          
          def let(*inpot, out: nil, &block)
            inpot = inpot.map{_1.is_a?(Pot) ? _1 : pot(_1)}
            if block_given?
                if out.nil?
                    return Let.new(inpot, &block)
                else
                    l = Let.new(inpot, &block)
                    if out.is_a? Array
                        l.apply_outpot(*out)
                    else
                        l.apply_outpot(out)
                    end
                    l.update_values
                    return l
                end
            else
                return Let.new(inpot) do |*v| v end
            end
          end
          
          def let_sum(*inpot)
            let(*inpot) do |*a| 
                a.sum 
            end
          end
          
          private
          
          class Let

            def initialize(inpot, &block)
                @callee = block
                @inpot = inpot
                @outpot = []
            end

            def copy
                Let.new @inpot, &@callee
            end
          
            def inpot = @inpot
          
            def apply_outpot(*outpot)
                outpot.each{_1.set_inlet(self)}
                @outpot += outpot.map{WeakRef.new _1}
                if not @inpot_connected
                    @inpot.each{_1.add_outlet(self)}
                    @inpot_connected = true
                end
            end
          
            def outpot
                @outpot.map{_1 and _1.weakref_alive? ? _1.__getobj__ : nil}
            end
          
            def >>(that)
                that.is_a?(Array) ? apply_outpot(*that) : apply_outpot(that)
                self
            end

            def update_values
                __update_values
            end
          
            def __update_values
                return if @closed
                outpot = self.outpot
                if outpot.compact.empty?
                    cancel
                    return
                end
                result = call
                if outpot.size > 1
                    ra = result.is_a?(Array) ? result : [result]
                    ra.zip(outpot).each{|r, o| o.__set r if not o.nil?}
                else
                    outpot[0].__set result
                end
                result
            end
        
            def call
                @callee.call(*@inpot.map(&:get))
            end
          
            def close
                @closed = true
            end
          
            def open(open = true)
                raise "Canceled let open" if open and (!@callee or !@outpot)
                @closed = !open
            end
          
            def cancel
                @inpot.each{|i| i.delete_outlet(self)}
                @inpot = nil
                @callee = nil
                @closed = true
            end
          
            def delete_outpot(outpot)
                @outpot = @outpot.map{not _1.weakref_alive? or _1.__getobj__ == outpot ? nil : _1}
                cancel if @outpot.compact.empty?
            end
        
            def pot(count: nil, locked: false)
                if count.nil?
                    pt = Pot.new
                    pt.let(self)
                    pt.lock_inlet self if locked
                    pt
                else
                    pots = Array.new(count){Pot.new}.map do |pt|
                        self >> pt
                        pt.lock_inlet locked if locked
                        pt
                    end
                    update_values
                    pots
                end
            end
        
            def affect(&affect)
                PotAffect.new(pot, &affect)
            end  
          end
          
          class Pot
            @@let_updating = true

            def self.let_update_enabled(enabled = true)
                @@let_updating = enabled
            end

            def initialize(value = nil)
                @inlet = nil
                @outlet = []
                @value = value
            end
          
            def inspect
                "Pot:#{self.object_id} @value=#{@value.inspect} @inlet=Let:#{@inlet.object_id} @outlet=[#{@outlet.map{"Let:#{_1.object_id}"}.join(', ')}]"
            end
          
            def get
                @value
            end
          
            alias value get
          
            def __set(value)
                return if @set_lock
                @value = value
                @set_lock = true
                outlet.each(&:update_values)
                @set_lock = false
            end
        
            def outlet
                @outlet.map{_1.weakref_alive? ? _1.__getobj__ : nil}.compact
            end
          
            def set(value)
                set_inlet(nil)
                __set(value)
                self
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
                    l.apply_outpot(self)
                    l.update_values if @@let_updating
                elsif v[0].is_a? Let
                    l = v[0].copy
                    l.apply_outpot(self)
                    l.update_values if @@let_updating
                elsif v[0].is_a? Pot
                    l = Let.new(v) do _1 end
                    l.apply_outpot(self)
                    l.update_values if @@let_updating
                else
                    set v[0]
                end
                self
            end
          
            def as(&block)
                Let.new([self], &block)
            end
          
            alias value= set
          
            def set_inlet(inlet)
                raise "Pot locked by #{@let_lock}" if @let_lock
                @inlet.delete_outpot(self) if @inlet
                @inlet = inlet
            end
        
            def inlet
                @inlet
            end
        
            def __inlet=(inlet)
                @inlet = inlet
            end
        
          
            def dependent?
                return !!@inlet
            end
          
            def lock_inlet(lock)
                @let_lock = lock
            end
          
            def unlock_inlet
                @let_lock = nil
            end
          
            def add_outlet(let)
                @outlet.append(WeakRef.new let)
            end
          
            def delete_outlet(let)
                @outlet.delete_if{not _1.weakref_alive? or _1.__getobj__ == let}
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
          
          class PotAffect < Pot
            def initialize(outpot, &affect)
                super(nil)
                @outpot = outpot
                @affect = affect
                @rewrapper = PotAffectRewrapper.new self
                @value = @outpot.get
            end
          
            def get
                @outpot.get
            end
          
            def affect_value
              @value
            end
        
            def set_inlet(inlet)
                Pot.let_update_enabled false
                @affect.call @rewrapper
                Pot.let_update_enabled true
                super
            end
          end
          
          
          class PotAffectRewrapper < Pot
            def initialize(a)
                @a = a
            end
          
            def get
                @a.affect_value
            end
            alias value get
            def __set(value) = @a.__set(value)
            def set(value) = @a.set(value)
            def let(*v, &block) = @a.let(*v, &block)
            def as(&block) = @a.as(&block)
            alias value= set
            def set_inlet(inlet) = @a.set_inlet(inlet)
            def dependent? = @a.dependent?
            def lock_inlet(lock) = @a.lock_inlet(lock)
            def unlock_inlet = @a.unlock_inlet
            def add_outlet(let) = @a.add_outlet(let)
            def delete_outlet(let) = @a.delete_outlet(let)
            def +(that) = @a + that
            def -(that) = @a - that
            def *(that) = @a * that
            def /(that) = @a / that
            def **(that) = @a ** that
            def %(that) = @a % that
          end
        
    end
end

class Class
    def pot_reader(*una, **na)
        una.each{na[_1] = _1}
        na.each do |mn, a|
            if a.is_a? Array
                pt = 'pt = @' + a.join('.') 
            else
                pt = "pt = defined?(self._#{a}) ? self._#{a} : @#{a}"
            end
            mn = [mn] if not mn.is_a? Array
            mn.each do |m|
                self.class_eval("def #{m}(&b); #{pt}; block_given? ? pt.as(&b) : pt;end")
            end
        end
    end

    def pot_accessor(*una, **na)
        pot_reader(*una, **na)
        una.each{na[_1] = _1}
        na.each do |mn, a|
            if a.is_a? Array
                pt_assign = '@' + a.join('.') + ' = val' 
            else
                pt_assign = "pt = defined?(self._#{a}) ? self._#{a} : @#{a}; pt.let val"
            end
            mn = [mn] if not mn.is_a? Array
            mn.each do |m|
                self.class_eval("def #{m}=(val); #{pt_assign};end")
            end
        end
    end
end