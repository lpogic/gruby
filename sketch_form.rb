require_relative "sketch_setup"
require 'benchmark'

Person = Struct.new(:name, :surname, :age, :sex)
@people = pot []


form = form! do
  self[:name] = note_row! "Imię:"
  self[:surname] = note_row! "Nazwisko:"
  self[:age] = note_row! "Wiek:", ruby: true
  self[:sex] = album_row! "Płeć:", %w[Facet Babka]
  button_row! save: "Zapisz", clear: "Wyczyść"
end

def clear_inputs
  form[Input].each{ _1.clear }
end

def save_person
  @people.val <<= Person.new(form[:name].text.get, form[:surname].text.get, form[:age].text.get, form[:sex].object.get)
end
  
form[:save].on :click do
  save_person
  puts "Peoples are:"
  # @people.get.each{puts "> #{_1.name} #{_1.surname}, age: #{_1.age}, sex: #{_1.sex}"}
  @people.get.each{ behalf(_1){ puts "> #{name} #{surname}, age: #{age}, sex: #{sex}" } }
  @people.get.each_one{ puts "> #{name} #{surname}, age: #{age}, sex: #{sex}" }
end

form[:clear].on :click do
  clear_inputs
end

show
