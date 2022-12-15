module Ruby2D
  module Planned
    include CommunicatingVesselSystem

    def plan(*upr, **pr, &linker)
      upr.each { pr[_1] ||= pot(send(_1), unique: false) }
      if block_given?
        linker.call(self, **pr)
      else
        _default_plan(**pr)
      end
      upr.map { pr[_1] }
    end
  end
end
