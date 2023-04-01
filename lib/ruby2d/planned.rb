module Ruby2D
  module Planned
    include CVS

    def plan(*upr, linker: nil, **pr, &blinker)
      upr.each { pr[_1] ||= pot(send(_1).get) }
      if linker
        linker.call(**pr)
      elsif block_given?
        blinker.call(self, **pr)
      else
        default_plan(**pr)
      end
      upr.map { pr[_1] }
    end
  end
end
