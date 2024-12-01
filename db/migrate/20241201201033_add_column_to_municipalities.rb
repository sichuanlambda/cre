class AddColumnToMunicipalities < ActiveRecord::Migration[7.1]
  def change
    add_column :municipalities, :name, :string
    add_index :municipalities, :name
    add_column :municipalities, :state, :string
    add_column :municipalities, :country, :string
  end
end
