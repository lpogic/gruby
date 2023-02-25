require_relative "./test_setup"

margin = pot 4
form margin: margin do
  @name = note_row "Imię:"
  @surname = note_row "Nazwisko:"
  @age = note_row "Wiek:", ruby: true
  @sex = album_row "Płeć:", %w[Facet Babka]
  @save, @cancel = button_row "Zapisz", "Anuluj"
end
  
@save.on :click do
  p @name.text.get
end

@cancel.on :click do
  margin.value += 1
end

# graphic_form do
#   row "     Imię: _______________", :text
#   row " Nazwisko: _______________", :text
#   row "     Wiek: _______________", :number
#   row "       [Wyświetl][Wyczyść]", proc{|f| p f }, proc{|f| f.clear }
# end

show
