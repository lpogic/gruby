require_relative "sketch_setup"

Person = Struct.new(:name, :surname, :age, :sex)
@people = pot []


form do
  @name = note_row "Imię:"
  @surname = note_row "Nazwisko:"
  @age = note_row "Wiek:", ruby: true
  @sex = album_row "Płeć:", %w[Facet Babka]
  @save, @cancel = button_row "Zapisz", "Wyczyść"
end

# def clear_inputs
#   [@name, @surname, @age, @sex].each{_1.clear}
# end

# def save_person
#   @people.val <<= Person.new(@name.text.get, @surname.text.get, @age.text.get, @sex.text.get)
# end
  
# @save.on :click do
#   save_person
#   clear_inputs
#   p "Peoples are:"
#   @people.get.each{p "- #{_1.name} #{_1.surname}, age: #{_1.age}, sex: #{_1.sex}"}
# end

# @cancel.on :click do
#   clear_person
# end


# fit_grid = FitGrid.new x: window.x, y: window.y
# fit_grid.arrange note, 0, 0
# fit_grid.arrange button, 0, 1, :right
# fit_grid.arrange note, 1, 1
# fit_grid.arrange note, 0, 2
t = table do
  3.times do
  row do
    %w[Imię Nazwisko Wiek Płeć].each{text _1}
  end
  row do
    %w[Nazwisko Wiek Płeć Imię].each{text _1}
  end
  row do
    %w[Wiek Płeć Imię Nazwisko].each{text _1}
  end
  row do
    %w[Płeć Imię Nazwisko Wiek].each{text _1}
  end
  end
  # grows @people do |person|
  #   row do
  #     text person.name
  #     text person.surname
  #     text person.age
  #     text person.sex
  #   end
  # end
end

on_key 'right' do
  t.x.val += 5
end

show
