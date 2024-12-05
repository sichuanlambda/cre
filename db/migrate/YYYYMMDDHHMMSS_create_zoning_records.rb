class CreateZoningRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :zoning_records do |t|
      t.references :municipality, null: false, foreign_key: true
      t.string :record_type # map, rezoning_request, incentive, impact_fee
      t.string :title
      t.text :description
      t.string :status # for rezoning requests: pending, approved, denied
      t.date :effective_date
      t.string :url
      t.jsonb :details # For storing type-specific details

      t.timestamps
    end
  end
end
