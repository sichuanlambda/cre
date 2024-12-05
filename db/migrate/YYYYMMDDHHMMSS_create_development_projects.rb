class CreateDevelopmentProjects < ActiveRecord::Migration[7.0]
  def change
    create_table :development_projects do |t|
      t.references :municipality, null: false, foreign_key: true
      t.string :name
      t.string :project_type # residential, commercial, industrial, mixed-use
      t.string :status # proposed, approved, in_progress, completed
      t.text :description
      t.date :estimated_completion
      t.jsonb :details # For storing additional project-specific details
      t.decimal :estimated_cost
      t.string :developer_name
      t.string :project_url

      t.timestamps
    end
  end
end
