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
    def self.pot(value = nil, unique: true, pull: true)
      return value if !unique && v.is_a?(Pot)

      location = Pot.debug ? caller(1..1).first : nil
      BasicPot.new(pull:, location:).let value
    end

    def self.converted_pot(*v, pull: true, &block)
      p1 = CommunicatingVesselSystem.pot
      p2 = CommunicatingVesselSystem.pot(pull:)
      CommunicatingVesselSystem.let(*v, p1, BasicPot.new(p2), &block)._connect(p2, pull: false)
      p2._recent = true
      location = Pot.debug ? caller(1..1).first : nil
      ConvertedPot.new(p1, p2, location:)
    end

    def self.array_pot(pull: true, &block)
      p1 = CommunicatingVesselSystem.pot []
      p2 = CommunicatingVesselSystem.pot(pull:)
      p3 = CommunicatingVesselSystem.pot pull: true
      block ||= proc { _1 }
      CommunicatingVesselSystem.let(p1) do |pots|
        pots = block.call(Array(pots))
        CommunicatingVesselSystem.let(*pots){|*a| a} >> p2
        pots
      end >> p3
      location = Pot.debug ? caller(1..1).first : nil
      ArrayPot.new(p1, p2, p3, location:)
    end

    def self.let(*inpot, &)
      inpot = inpot.map do |i|
        case i
        when Pot then i
        when Let then i.pot
        else BasicPot.new.let(i)
        end
      end
      Let.new(inpot, &)
    end
  end
end