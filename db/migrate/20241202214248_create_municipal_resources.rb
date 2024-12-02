class CreateMunicipalResources < ActiveRecord::Migration[7.1]
  def change
    create_table :municipal_resources do |t|
      t.string :title
      t.string :url
      t.text :description
      t.string :category
      t.datetime :last_updated
      t.references :municipality, null: false, foreign_key: true

      t.timestamps
    end
  end
end
