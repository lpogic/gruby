require_relative "./test_setup"

Person = Struct.new(:name, :surname, :age, :sex)
@people = pot []

# margin = pot 4
# form margin: margin do
#   @name = note_row "Imię:"
#   @surname = note_row "Nazwisko:"
#   @age = note_row "Wiek:", ruby: true
#   @sex = album_row "Płeć:", %w[Facet Babka]
#   @save, @cancel = button_row "Zapisz", "Wyczyść"
# end

# def clear
#   [@name, @surname, @age, @sex].each{_1.clear}
# end

# def save
#   @people.value <<= Person.new(@name.text.get, @surname.text.get, @age.text.get, @sex.text.get)
# end
  
# @save.on :click do
#   save
#   clear
#   p @people.get
# end

# @cancel.on :click do
#   clear
# end


fit_grid = FitGrid.new x: window.x, y: window.y
fit_grid.arrange note, 0, 0
fit_grid.arrange button, 0, 1, :right
fit_grid.arrange note, 1, 1
fit_grid.arrange note, 0, 2
# table do
#   row do
#     text "Imię"
#     text "Nazwisko"
#     text "Wiek"
#     text "Płeć"
#   end
#   grows @people do |person|
#     row do
#       text person.name
#       text person.surname
#       text person.age
#       text person.sex
#     end
#   end
# end

show
