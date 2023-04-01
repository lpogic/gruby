require_relative "sketch_setup"



#MODEL

model = self
behalf model do
  Person = Struct.new(:name, :surname, :age, :sex, keyword_init: true)
  @people = pot []
    
  def save_person(**na)
    @people.val <<= Person.new(**na)
  end

  def print_people
    puts "Peoples are:"
    @people.get.proxy{ puts "> #{name} #{surname}, age: #{age}, sex: #{sex}" }
  end
end


#VIEW

form = form! do
  note_row! :name, "Imię"
  note_row! :surname, "Nazwisko"
  note_row! :age, "Wiek", ruby: true
  album_row! :sex, "Płeć", options: %w[Facet Babka]
  button_row! do
    button! :save, "Zapisz"
    button! :clear, "Wyczyść"
    button! :close, "Zamknij"
  end

  def clear_inputs
    des{ _1.is_a?(Note) && !_1.is_a?(TextNote)}.proxy{ clear }
  end

  def data
    des(Note).proxy{ [names.first, val] if names.first }.compact.to_h 
  end
end

#PRESENTER

form[:save] do |f|
  on :click do
    model.save_person **f.data
    model.print_people
  end
end

form[:clear] do |f|
  on :click do
    f.clear_inputs
  end
end

form[:close] do |f|
  on :click do
    window.leave f
  end
end

on :click do
  care form
end
show
