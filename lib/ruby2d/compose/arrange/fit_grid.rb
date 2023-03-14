module Ruby2D
  class FitGrid < Grid
    def initialize(**plan)
      super(**plan)
      @object_sectors = []
      @cols_length = 0
      @rows_length = 0
    end

    ObjectSector = Struct.new(:object, :cols, :rows, :align)

    def add(object, col, row, *align, arrange: true)
      col = col..col unless col.is_a? Range
      row = row..row unless row.is_a? Range
      @cols_length = col.max + 1 if col.max > @cols_length - 1
      @rows_length = row.max + 1 if row.max > @rows_length - 1
      align << :x unless align.any_in? :x, :left, :right
      align << :y unless align.any_in? :y, :top, :bottom

      @object_sectors << ObjectSector.new(object, col, row, align)
      self.arrange if arrange
    end

    def arrange
      let(*@object_sectors.map { _1.object.width }) { fit(:cols, :width, @cols_length) } >> @cols
      let(*@object_sectors.map { _1.object.height }) { fit(:rows, :height, @rows_length) } >> @rows
      @object_sectors.each do |os|
        sector = sector(os.cols, os.rows)
        os.object.plan(**os.align.map { [_1, sector.send(_1)] }.to_h)
      end
    end

    private

    def fit(dir, dim, length)
      x = Array.new(length, 0)
      n = Array.new(length, 0)
      @object_sectors.sort { |a, b| a.send(dir).max <=> b.send(dir).max }.each do |os|
        last = os.send(dir).max
        x[last] = [x[last], os.object.send(dim).get - x[os.send(dir).min...last].sum].max
      end
      @object_sectors.sort { |a, b| a.send(dir).min <=> b.send(dir).min }.each do |os|
        first = os.send(dir).min
        n[first] = [n[first], os.object.send(dim).get - n[first + 1..os.send(dir).max].sum].max
      end
      x.zip(n).map { _1.sum / 2.0 }
    end
  end
end
