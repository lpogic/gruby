# SYSTEM ZMIENNYCH POWIĄZANYCH

# Zmienne wyjściowe (outpot) muszą być podane jawnie, a nie jako efekt uboczny np {@a.set _1}, ponieważ przy zmianie wejścia (inlet), stare musi zostać odpięte.
# Algorytm sprawdzający cykle wykrywa nieskończone pętle tylko dla jawnych połączeń.
#
#  let:outpot ==weakref==> pot:outlet ==weakref==> let
#  let:inpot ==hardref==> pot:inlet ==hardref==> let
#
require_relative "let"
require_relative "pot"
require_relative "basic_pot"
require_relative "converted_pot"
require_relative "array_pot"

module Ruby2D
  module CommunicatingVesselSystem
    def self.pot(value = nil, unique: true, pull: false, name: nil)
      return value if !unique && v.is_a?(Pot)

      BasicPot.new(pull:, name:).let value
    end

    def self.converted_pot(*v, pull: false, name: nil, &block)
      p1 = CommunicatingVesselSystem.pot
      p2 = CommunicatingVesselSystem.pot(pull:)
      CommunicatingVesselSystem.let(*v, p1, BasicPot.new(p2), &block)._connect(p2, pull: false)

      ConvertedPot.new(p1, p2, name:)
    end

    def self.array_pot(pull: false, name: nil, &block)
      p1 = CommunicatingVesselSystem.pot []
      p2 = CommunicatingVesselSystem.pot(pull:)
      p3 = CommunicatingVesselSystem.pot pull: true
      block ||= proc { _1 }
      CommunicatingVesselSystem.let(p1, sublet_enabled: true) do |pots|
        pots = block.call(pots.to_a)
        CommunicatingVesselSystem.let(*pots){|*a| a} >> p2
        pots
      end >> p3
      name = CVS.debug ? caller(1..1).first : nil
      ArrayPot.new(p1, p2, p3, name:)
    end

    def self.let(*inpot, name: nil, sublet_enabled: false, &b)
      inpot = inpot.map do |i|
        case i
        when Pot then i
        when Let then i.pot
        else BasicPot.new.let(i)
        end
      end
      Let.new(inpot, name:, sublet_enabled:, &b)
    end
  end
end