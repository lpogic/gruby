module Ruby2D
  class Form < Arena

    def init(margin: 6, **plan)
      @body = new_rectangle(**plan)
      @margin = pot << margin
      @note_col_width = pot 80
    end

    def scoped
      @rows = rows! color: 'green', round: 10, gap: [@margin]
      super
    end

    delegate body: %w[fill plan x y width height left right top bottom]
    cvsa :margin, :note_col_width
      
    def note_row!(label, ruby: false)
      a = nil
      behalf @rows do
        cols! gap: 5 do
          gap! up(Form).margin
          box! width: up(Form).note_col_width do 
            text! label, right: right 
          end
          a = ruby ? ruby_note! : note!
          gap! up(Form).margin
        end
      end
      a
    end

    def album_row!(label, options)
      a = nil
      behalf @rows do
        cols! gap: 5 do
          gap! up(Form).margin
          rows! width: up(Form).note_col_width do 
            text! label, right: right 
          end
          a = album! options
          gap! up(Form).margin
        end
      end
      a
    end

    def button_row!(*labels)
      btns = []
      behalf @rows do
        cols! gap: 5, right: right do
          gap! up(Form).margin
          btns = labels.map { button! _1 }
          gap! up(Form).margin
        end
      end
      btns
    end
  end
end
