require_relative "sketch_setup"
require 'benchmark'

Benchmark.bm do |bm|
  bm.report do
    @t = table! color: 'green', border: 1 do
      4.times do
        row! do
          %w[Imię Nazwisko Wiek Płeć Imię Nazwisko Wiek Płeć Imię Nazwisko Wiek Płeć].each{text! _1}
        end
        row! do
          %w[Nazwisko Wiek Płeć Imię Imię Nazwisko Wiek Płeć Imię Nazwisko Wiek Płeć].each{button! _1}
        end
        row! do
          %w[Wiek Płeć Imię Nazwisko Imię Nazwisko Wiek Płeć Imię Nazwisko Wiek Płeć].each{text! _1}
        end
        row! do
          %w[Płeć Imię Nazwisko Wiek Imię Nazwisko Wiek Płeć Imię Nazwisko Wiek Płeć].each{text! _1}
        end
      end
    end
  end
end

on_key 'right' do
  @t.x.val += 5
end

on_key 'left' do
  @t.x.val -= 5
end

show
