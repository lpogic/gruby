require 'guigem'

records = load_records
cols = {
    "serwis" => "Serwis",
    "login" => "Login",
    "haslo" => "Hasło",
    "dodatki" => "Dodatki"
}

change_store_button = button "Zmień magazyn"
search_note = note placeholder: "Czego szukasz?"
add_button = button "Dodaj"
records_table = fast_table cols: cols, data: records

scene :store do
    row gap: 6, pad: 6 do
        care change_store_button
        care search_note, width: 'fill'
        care add_button
    end
    row pad: 6 do
        care records_table, max_width: 'fill', max_height: 'fill'
    end
end


change_store_button.click do
    window.go :stores
end
add_button.click do
    parts = search_note.text.get.split
    if parts[0] and parts[0] != ''
        records << {
            'serwis' => parts[0],
            'login' => parts[1] || '',
            'haslo' => parts[2] || '',
            'dodatki' => parts[3] || ''
        }
        records_table.data.set records
    end
end
search_note.change do |txt|
    records_table.data.set records.filter{|r| r.values.any?{|rv| rv.contains? txt}}
end