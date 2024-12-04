class AddCoordinatesToMunicipalities < ActiveRecord::Migration[7.1]
  def change
    add_column :municipalities, :latitude, :decimal, precision: 10, scale: 6
    add_column :municipalities, :longitude, :decimal, precision: 10, scale: 6
  end
end
