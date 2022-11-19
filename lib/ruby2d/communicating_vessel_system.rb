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
            pt = BasicPot.new location: caller(1, 1)[0]
            pt.let(*v, &block)
            pt.lock_inlet self if locked
            pt
        end

        # def pot(v, accept_origin: false)
        #     return v if v.is_a?(Pot) and accept_origin
        #     BasicPot.new.let(v)
        # end
        
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
            Compot.new(p1, p2, location: caller(1, 1)[0])
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
        
        private
        
        class Let
            @@instances = 0

            def self.instances
                @@instances
            end

            @@suppress = false
            def self.suppress
                s, @@suppress = @@suppress, true
                yield
                @@suppress = s
            end

            @@pool = false
            @@to_update = []
            def self.pool
                if @@pool
                    yield
                else
                    t, @@pool = @@pool, true
                    yield
                    @@pool = t
                    to_update, @@to_update = @@to_update, []
                    to_update.uniq.each{_1.__update_values}
                end
            end 

            def initialize(inpot, &block)
                @function = block
                @inpot = inpot
                @outpot = []
                @@instances += 1
            end

            def copy
                Let.new @inpot, &@function
            end

            # dla funkcji agregujących np. let(*xes).max,    let(a, b, c).max
            def method_missing(m, *a, &b)
                if Array.method_defined? m
                    __compose(m, *a, &b)
                else
                    super
                end
            end

            def __compose(m, *arg, &b)
                if @function
                    Let.new(@inpot) do |*a|
                        @function.call(*a).array.send(m, *arg, &b)
                    end
                else
                    Let.new(@inpot) do |*a|
                        a.send(m, *arg, &b)
                    end
                end
            end

            def as(&b)
                if @function
                    Let.new(@inpot) do |*a|
                        b.(*@function.call(*a))
                    end
                else
                    Let.new(@inpot, &b)
                end
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

            def update_values(unlock = true)
                return if @locked
                @locked = true
                if not @@suppress
                    if @@pool
                        @@to_update << self
                    else
                        __update_values
                    end
                end
                @locked = false if unlock
            end

            def unlock
                @locked = false
            end
            
            def __update_values
                return if @closed
                outpot = self.outpot
                oc = outpot.compact
                if oc.empty?
                    cancel
                    return
                end
                result = get.array
                if outpot.size > 1
                    begin
                        result.zip(outpot).map{|r, o| o.nil? ? [] : o.__set(r, false) || []}.reduce(&:+).uniq.each{_1.update_values}
                    ensure
                        oc.each{_1.__unlock}
                    end
                else
                    outpot[0].__set result[0]
                end
                result
            end

            def get
                i = @inpot.map(&:get)
                @function ? @function.call(*i) : i.size > 1 ? i : i[0]
            end
            
            def close
                @closed = true
            end
            
            def open(open = true)
                raise "Canceled let open" if open and (!@function or !@outpot)
                @closed = !open
            end
            
            def cancel
                @inpot.each{|i| i.delete_outlet(self)}
                @inpot = nil
                @function = nil
                @closed = true
            end

            def detach
                @inpot.each{|i| i.delete_outlet(self)}
                @inpot_connected = false
                outpot.each{_1.set_inlet(false)}
                @outpot = []
            end
            
            def delete_outpot(to_delete)
                @outpot = @outpot.map{_1.nil? || !_1.weakref_alive? || _1.__getobj__ == to_delete ? nil : _1}
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

            def nodes
                o = outpot.compact
                o.map{_1.nodes}.sum + o.size
            end

            def nod(tabs)
                ["<#{object_id}>"] + outpot.compact.map{_1.nod tabs}.reduce(&:+)
            end

            def levels
                o = outpot.compact
                (o.map{_1.levels}.max || 0) + 1
            end
        end

        class Pot
            @@instances = 0

            def self.instances
                @@instances
            end

            def initialize
                @@instances += 1
            end

            def nodes()
                return 0 if @loop
                @loop = true
                s = outlet.map{_1.nodes}.sum
                @loop = false
                s
            end

            def nod(tabs = 0)
                return [] if @loop
                @loop = true
                s = [object_id.to_s] + outlet.map{_1.nod tabs + 1}.flatten.map{" " + _1}
                @loop = false
                s
            end

            def levels
                return 0 if @loop
                @loop = true
                s = outlet.map{_1.levels}.max
                @loop = false
                s
            end
        end
        
        class BasicPot < Pot

            def initialize(value = nil, location: nil)
                super()
                @inlet = nil
                @outlet = []
                @value = value
                @location = location
            end
            
            def inspect
                "Pot:#{self.object_id} @value=#{@value.inspect} @inlet=Let:#{@inlet.object_id} @outlet=[#{@outlet.map{"Let:#{_1.object_id}"}.join(', ')}]"
            end
            
            def get
                @value
            end
            
            alias value get
            
            def __set(value, auto_unlock = true)
                return if @set_lock
                @value = value
                @set_lock = true
                if auto_unlock
                    begin
                        outlet.each{_1.update_values false}
                    ensure
                        outlet.each{_1.unlock}
                        @set_lock = false
                    end
                else
                    outlet
                end
            end

            def __unlock
                @set_lock = false
            end
        
            def outlet
                @outlet.map{_1.weakref_alive? ? _1.__getobj__ : nil}.compact
            end
            
            def set(value = nil, &mod)
                value = mod.call(get, value) if block_given?
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
                    l = Let.new(v)
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
                @outlet.append(WeakRef.new let) if not outlet.include? let
            end
            
            def delete_outlet(let)
                @outlet.delete_if{not _1.weakref_alive? or _1.__getobj__ == let}
            end
        end

        class Compot < Pot

            def initialize(inpot, outpot, location: nil)
                super()
                @inpot = inpot
                @outpot = outpot
                @location = location
            end
            
            def inspect
                "Compot:#{self.object_id} @inpot=#{@inpot.inspect} @outpot=#{@outpot.inspect}]"
            end

            def get
                @outpot.get
            end
            
            alias value get
        
            def outlet
                @outpot.outlet
            end
            
            def __set(value, auto_unlock = true)
                @inpot.__set value, auto_unlock
            end
            
            def set(value = nil, &mod)
                @inpot.set value, &mod
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
    def cvs_reader(*una, **na)
        una.each{na[_1] = _1}
        na.each do |mn, a|
            if a.is_a? Array
                pt = 'c = @' + a.join('.') 
            else
                pt = "c = defined?(self._cvs_#{a}) ? self._cvs_#{a} : @#{a}"
            end
            mn = [mn] if not mn.is_a? Array
            mn.each do |m|
                self.class_eval("def #{m}(&b); #{pt}; block_given? ? c.as(&b) : c;end")
            end
        end
    end

    def cvs_accessor(*una, **na)
        cvs_reader(*una, **na)
        una.each{na[_1] = _1}
        na.each do |mn, a|
            if a.is_a? Array
                pt_assign = '@' + a.join('.') + ' = val' 
            else
                pt_assign = "c = defined?(self._cvs_#{a}) ? self._cvs_#{a} : @#{a}; c.let val"
            end
            mn = [mn] if not mn.is_a? Array
            mn.each do |m|
                self.class_eval("def #{m}=(val); #{pt_assign};end")
            end
        end
    end
end