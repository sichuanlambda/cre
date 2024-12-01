class CreateMunicipalities < ActiveRecord::Migration[7.1]
  def change
    create_table :municipalities do |t|

      t.timestamps
    end
  end
end
