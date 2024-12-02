class CreateMunicipalityRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :municipality_requests do |t|
      t.string :name, null: false
      t.timestamps
    end
  end
end
