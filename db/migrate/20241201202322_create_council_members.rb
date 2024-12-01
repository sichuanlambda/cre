class CreateCouncilMembers < ActiveRecord::Migration[7.1]
  def change
    create_table :council_members do |t|
      t.string :name
      t.string :position
      t.text :social_links
      t.references :municipality, null: false, foreign_key: true

      t.timestamps
    end
  end
end
