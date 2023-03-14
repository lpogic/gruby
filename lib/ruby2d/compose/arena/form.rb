module Ruby2D
  class Form < Arena

    def init(margin: 6, **plan)
      @body = new_rectangle(**plan)
      @margin = pot << margin
      @nw = pot 80
    end

    masking do

      delegate body: %w[fill plan x y width height left right top bottom]
      cvsa :margin

      def tap(&b)
        rows! color: 'green', round: 10, gap: [@margin] do
          b.call self
        end
      end

      scoping do
        def note_row!(label, ruby: false)
          a = nil
          cols! gap: 5 do
            gap! @margin
            rows! width: @nw do 
              text! label, right: right 
            end
            a = ruby ? ruby_note! : note!
            gap! @margin
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
      end#scoping
    end#masking
  end
end
