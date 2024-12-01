class CreateMunicipalities < ActiveRecord::Migration[7.0]
  def change
    create_table :municipalities do |t|
      t.string :name, null: false
      t.string :state
      t.string :country

      t.timestamps

      t.index :name, unique: true
    end
  end
end
