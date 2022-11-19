class Pot
    def initialize
        @inlet = nil
        @outlet = []
        @value = nil
    end

    def get
        @value
    end

    def set(value)
        set_inlet nil if not @inlet.nil?
        @value = value
        outlet_update
    end


    def set_inlet(inlet)
        if not @inlet.nil?
            @inlet.detach self
        end
        @inlet = inlet
    end

    def _set(value) #invoked by inlet
        @value = value
    end

    def independent?
        @inlet.nil?
    end

    def collect_independent
        manual? [self] : @inlet.collect_independent
    end
end

class Let
    def initialize(inpot, outpot, action)
        @inpot = inpot
        @outpot = outpot
        @action = action
    end

    def collect_independent
        inpot.map(&:collect_independent).sum
    end
end

def pot
    Pot.new
end

def link(inpot, outpot, &action)
    in_ind = inpot.collect_independent
    
    Let.new(inpot, outpot, action)
end

