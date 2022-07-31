require 'ruby2d'

RSpec.describe Ruby2D::Square do
  describe '#new' do
    it 'creates a white square by default' do
      square = Square.new
      expect(square.color).to be_a(Ruby2D::Color)
      expect(square.color.r).to eq(1)
      expect(square.color.g).to eq(1)
      expect(square.color.b).to eq(1)
      expect(square.color.a).to eq(1)
    end

    it 'creates a square with options' do
      square = Square.new(
        x: 10, y: 20, z: 30,
        size: 40,
        color: 'gray', opacity: 0.5
      )

      expect(square.x).to eq(10)
      expect(square.y).to eq(20)
      expect(square.z).to eq(30)
      expect(square.size).to eq(40)
      expect(square.width).to eq(40)
      expect(square.height).to eq(40)
      expect(square.color.r).to eq(2 / 3.0)
      expect(square.color.opacity).to eq(0.5)
    end

    it 'creates a new square with one color via string' do
      square = Square.new(color: 'red')
      expect(square.color).to be_a(Ruby2D::Color)
    end

    it 'creates a new square with one color via array of numbers' do
      square = Square.new(color: [0.1, 0.3, 0.5, 0.7])
      expect(square.color).to be_a(Ruby2D::Color)
    end
  end

  describe 'attributes' do
    it 'can be set and read' do
      square = Square.new
      square.x = 10
      square.y = 20
      square.z = 30
      square.size = 40
      square.color = 'gray'
      square.color.opacity = 0.5

      expect(square.x).to eq(10)
      expect(square.y).to eq(20)
      expect(square.z).to eq(30)
      expect(square.size).to eq(40)
      expect(square.color.r).to eq(2 / 3.0)
      expect(square.color.opacity).to eq(0.5)
    end
  end
end
