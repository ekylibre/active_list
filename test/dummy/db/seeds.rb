# encoding: UTF-8

Person.create! name: 'Leonardo di ser Piero da Vinci', born_on: '1452-04-15'
Person.create! name: '宮崎 駿', born_on: '1941-01-05'
Person.create! name: 'عَبْدَالله مُحَمَّد بِن مُوسَى اَلْخْوَارِزْمِي‎', born_on: Date.new(780, 8, 7)
Person.create! name: 'Περικλῆς', born_on: Date.new(-495, 9, 4)
200.times do |index|
  Person.create! name: "Human ##{index}", born_on: Date.new(1 + 11 * index, 1 + index % 11, 1 + (7 * index) % 27)
end

puts "#{Person.count} people"
