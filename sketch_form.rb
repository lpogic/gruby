require_relative "sketch_setup"
require 'benchmark'

Person = Struct.new(:name, :surname, :age, :sex)
@people = pot []


form! do
  @name = note_row! "Imię:"
  @surname = note_row! "Nazwisko:"
  @age = note_row! "Wiek:", ruby: true
  @sex = album_row! "Płeć:", %w[Facet Babka]
  @save, @cancel = button_row! "Zapisz", "Wyczyść"
end

def clear_inputs
  [@name, @surname, @age, @sex].each{ _1.clear }
end

def save_person
  @people.val <<= Person.new(@name.text.get, @surname.text.get, @age.text.get, @sex.object.get)
end
  
@save.on :click do
  save_person
  clear_inputs
  puts "Peoples are:"
  @people.get.each{puts "- #{_1.name} #{_1.surname}, age: #{_1.age}, sex: #{_1.sex}"}
end

@cancel.on :click do
  clear_inputs
end

show
