module Ruby2D
  module Planned
    include CVS

    def plan(*upr, **pr, &linker)
      upr.each { pr[_1] ||= pot(send(_1).get) }
      if block_given?
        linker.call(self, **pr)
      else
        default_plan(**pr)
      end
      upr.map { pr[_1] }
    end
  end
end
