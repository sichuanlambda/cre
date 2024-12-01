class CreateDevelopmentScores < ActiveRecord::Migration[7.1]
  def change
    create_table :development_scores do |t|
      t.integer :current_score
      t.references :municipality, null: false, foreign_key: true

      t.timestamps
    end
  end
end
