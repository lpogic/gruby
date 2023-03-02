module Ruby2D
  class FitGrid < Grid
    def initialize(**plan)
      super(**plan)
      @object_sectors = []
    end

    ObjectSector = Struct.new(:object, :cols, :rows)

    def arrange(object, col, row, *align)
      col = col..col unless col.is_a? Range
      row = row..row unless row.is_a? Range
      @cols << Array.new(col.max + 1, 0) if col.max > @cols.get.length - 1
      @rows << Array.new(row.max + 1, 0) if row.max > @rows.get.length - 1
      sector = sector(col, row)
      align << :x unless align.any_in? :x, :left, :right
      align << :y unless align.any_in? :y, :top, :bottom
      object.plan(**align.map { [_1, sector.send(_1)] }.to_h)

      @object_sectors << ObjectSector.new(object, col, row)
      let(*@object_sectors.map { _1.object.width }) { fit(:cols, :width) } >> @cols
      let(*@object_sectors.map { _1.object.height }) { fit(:rows, :height) } >> @rows
    end

    def fit(dir, dim)
      x = Array.new(send(dir).get.length, 0)
      n = Array.new(send(dir).get.length, 0)
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
