class RecreateDevelopmentProjects < ActiveRecord::Migration[7.1]
  def up
    # Drop the existing table if it exists
    drop_table :development_projects if table_exists?(:development_projects)

    # Create the table with all needed columns
    create_table :development_projects do |t|
      t.references :municipality, null: false, foreign_key: true
      t.string :name
      t.string :project_type
      t.string :status
      t.text :description
      t.date :estimated_completion
      t.decimal :estimated_cost
      t.string :developer_name
      t.string :project_url
      t.json :details

      t.timestamps
    end
  end

  def down
    drop_table :development_projects
  end
end
