module Ruby2D
  class Widget < Cluster
    def initialize(parent, *una, **na, &b)
      super

      @tab_pass_keyboard = on :key_down do |e|
        self.parent.pass_keyboard self, reverse: shift_down if e.key == 'tab'
      end
    end

    attr_reader :state

    def pass_keyboard(*)
      return false if @accept_keyboard_disabled

      window.keyboard_current_object = self
      true
    end
  end
end
