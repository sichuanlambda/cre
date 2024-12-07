class CreateZoningTables < ActiveRecord::Migration[7.0]
  def change
    create_table :zoning_maps do |t|
      t.references :municipality, null: false, foreign_key: true
      t.string :title
      t.string :url
      t.datetime :last_updated
      t.string :coverage_area
      t.string :map_type
      t.timestamps
    end

    create_table :zoning_decisions do |t|
      t.references :municipality, null: false, foreign_key: true
      t.datetime :decision_date
      t.string :decision_type
      t.text :description
      t.string :status
      t.string :location
      t.timestamps
    end

    add_column :municipalities, :zoning_code, :json
  end
end
