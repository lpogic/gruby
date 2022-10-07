# SYSTEM ZMIENNYCH POWIĄZANYCH TYPU PUSH

# Zmienne wyjściowe (outpot) muszą być podane jawnie, a nie jako efekt uboczny np {@a.set _1}, ponieważ przy zmianie wejścia (inlet), stare musi zostać odpięte.
#
#  let:outpot ==weakref==> pot:outlet ==weakref==> let
#  let:inpot ==hardref==> pot:inlet ==hardref==> let
#
require 'weakref'

module Ruby2D
    module CommunicatingVesselSystem
        def pot(*v, locked: false, &block)
            pt = BasicPot.new
            pt.let(*v, &block)
            pt.lock_inlet self if locked
            pt
        end
        
        def locked_pot(*v, &block)
            pot(*v, locked: true, &block)
        end

        def superpot(p0)
            BasicPot.new p0
        end

        def compot(*v, locked: false, &block)
            p1 = pot locked: locked
            p2 = pot
            p2.let(*v, p1, superpot(p2), update: false, &block)
            Compot.new(p1, p2)
        end
        
        def let(*inpot, out: nil, &block)
            inpot = inpot.map{_1.is_a?(Pot) ? _1 : BasicPot.new.let(_1)}
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

            @@suppress = false
            def self.suppress
                s, @@suppress = @@suppress, true
                yield
                @@suppress = s
            end

            def initialize(inpot, &block)
                @callee = block
                @inpot = inpot
                @outpot = []
                class << @outpot
                    alias xd <<
                    def <<(e)
                        p "XD" if e == true
                        xd(e)
                    end

                    alias xd1 +
                    def +(e)
                        p "XD" if e == true
                        xd1(e)
                    end
                end
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
                update_values
                self
            end

            def update_values
                __update_values if not @@suppress
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

            def detach
                @inpot.each{|i| i.delete_outlet(self)}
                @inpot_connected = false
                outpot.each{_1.set_inlet(false)}
                @outpot = []
            end
            
            def delete_outpot(outpot)
                @outpot = @outpot.map{_1.nil? || !_1.weakref_alive? || _1.__getobj__ == outpot ? nil : _1}
                cancel if @outpot.compact.empty?
            end
        
            def pot(count: nil, locked: false)
                if count.nil?
                    pt = BasicPot.new
                    pt.let(self)
                    pt.lock_inlet self if locked
                    pt
                else
                    pots = Array.new(count){BasicPot.new}.map do |pt|
                        self >> pt
                        pt.lock_inlet locked if locked
                        pt
                    end
                    update_val ues
                    pots
                end
            end
        end

        module Pot
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
        
        class BasicPot
            include Pot

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
            
            def let(*v, update: true, &block)
                if block_given?
                    l = Let.new(v.map do |v1| 
                        if v1.is_a?(Pot)
                            v1
                        else
                            pot = BasicPot.new
                            pot.let(v1)
                            pot
                        end
                    end, &block)
                elsif v[0].is_a? Let
                    l = v[0].copy
                elsif v[0].is_a? Pot
                    l = Let.new(v) do _1 end
                else
                    set_inlet(nil)
                    __set(v[0])
                    return self
                end
                l.apply_outpot(self)
                l.update_values if update
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
            
            def dependent?
                return !!@inlet
            end
            
            def lock_inlet(lock = true)
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
        end

        class Compot
            include Pot

            def initialize(inpot, outpot)
                @inpot = inpot
                @outpot = outpot
            end
            
            def inspect
                "CompoundPot:#{self.object_id} @inpot=#{@inpot.inspect} @outpot=#{@outpot.inspect}]"
            end

            def get
                @outpot.get
            end
            
            alias value get
        
            def outlet
                @outpot.outlet
            end
            
            def __set(value)
                @inpot.__set value
            end
            
            def set(value)
                @inpot.set value
                self
            end
            
            def let(*v, &block)
                @inpot.let(*v, &block)
                self
            end
            
            def as(&block)
                Let.new([self], &block)
            end

            alias value= set
            
            def set_inlet(inlet)
                @inpot.set_inlet inlet
            end
        
            def inlet
                @inpot.inlet
            end
            
            def dependent?
                @inpot.dependent?
            end
            
            def lock_inlet(lock = true)
                @inpot.lock_inlet lock
            end
            
            def unlock_inlet
                @inpot.unlock_inlet
            end
            
            def add_outlet(let)
                @outpot.add_outlet(let)
            end
            
            def delete_outlet(let)
                @outpot.delete_outlet(let)
            end
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