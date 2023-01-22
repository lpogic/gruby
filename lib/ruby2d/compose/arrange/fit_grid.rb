module Ruby2D
  class FitGrid < Grid
    def initialize(**plan)
      super(**plan)
      @object_sectors = []
    end

    ObjectSector = Struct.new(:object, :cols, :rows)

    def arrange(object, col, row, *a)
      col = col..col unless col.is_a? Range
      row = row..row unless row.is_a? Range
      @cols.set { _1 + Array.new(col.max - _1.length + 1) { pot 0 } } if @cols.get.length <= col.max
      @rows.set { _1 + Array.new(row.max - _1.length + 1) { pot 0 } } if @rows.get.length <= row.max
      sector = sector(col, row)
      a << :x unless a.any_in? :x, :left, :right
      a << :y unless a.any_in? :y, :top, :bottom
      object.plan(**a.map { [_1, sector.send(_1)] }.to_h)

      @object_sectors << ObjectSector.new(object, col, row)
      let(*@object_sectors.map { _1.object.width }) { fit :cols, :width } >> cols.get
      let(*@object_sectors.map { _1.object.height }) { fit :rows, :height } >> rows.get
    end

    def fit(dir, dim)
      x = Array.new(send(dir).get.length, 0)
      n = Array.new(send(dir).get.length, 0)
      @object_sectors.sort { |a, b| a.send(dir).max <=> b.send(dir).max }.each do |os|
        x[os.send(dir).max] =
          [x[os.send(dir).max], os.object.send(dim).get - x[os.send(dir).min...os.send(dir).max].sum].max
      end
      @object_sectors.sort { |a, b| a.send(dir).min <=> b.send(dir).min }.each do |os|
        n[os.send(dir).min] =
          [n[os.send(dir).min], os.object.send(dim).get - n[os.send(dir).min + 1..os.send(dir).max].sum].max
      end
      x.zip(n).map { _1.sum / 2.0 }
    end
  end
end
