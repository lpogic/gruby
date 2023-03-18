module Ruby2D
  class Form < Arena

    def init(margin: 6, **plan)
      @body = new_rectangle(**plan)
      @margin = pot << margin
      @nw = pot 11
    end

    def scoped
      rows! color: 'green', round: 10, gap: [@margin] do
        yield self
      end
    end

    delegate body: %w[fill plan x y width height left right top bottom]
    cvsa :margin
      
    def note_row!(label, ruby: false)
      a = nil
      cols! gap: 5 do
        # gap! @margin
        # box! width: @nw, color: 'yellow' do 
          text! label#, right: right 
        # end
        box! width: 10 do
        end
        a = ruby ? ruby_note! : button!("XDXDXDXDXDX") do |b|
          on :click do
            text.val += "XD"
          end
        end
        # gap! @margin
      end
      a
    end

    def album_row!(label, options)
      a = nil
      cols! gap: 5 do
        gap! @margin
        rows! width: @nw do 
          text! label, right: right 
        end
        a = album! options
        gap! @margin
      end
      a
    end

    def button_row!(*labels)
      btns = []
      cols! gap: 5, right: self.right do
        gap! @margin
        btns = labels.map { button! _1 }
        gap! @margin
      end
      btns
    end
  end
end
