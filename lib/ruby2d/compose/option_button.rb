module Ruby2D
  class OptionButton < Button

    def init(text: nil, **na)
      super

      @tab_pass_keyboard.cancel
      @tab_pass_keyboard = nil
    end

    def pass_keyboard(*)
      false
    end

    def border_color_plan(border_color: nil, **)
      if border_color
        self.border_color << border_color
      end
    end
  end
end
