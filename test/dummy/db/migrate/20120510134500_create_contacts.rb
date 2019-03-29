class CreateContacts < ActiveRecord::Migration[4.2]
  def change
    create_table :contacts do |t|
      t.integer :person_id
      t.text :address
      t.string :phone
      t.string :fax
      t.string :country

      t.timestamps null: false
    end
  end
end
