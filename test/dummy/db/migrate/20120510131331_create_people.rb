class CreatePeople < ActiveRecord::Migration[4.2]
  def change
    create_table :people do |t|
      t.string :name
      t.date :born_on
      t.decimal :height
      t.decimal :balance_amount
      t.string  :currency

      t.timestamps null: false
    end
  end
end
