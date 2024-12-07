class FixDevelopmentProjectsTable < ActiveRecord::Migration[7.1]
  def change
    # Add missing columns without destroying existing data
    add_reference :development_projects, :municipality, null: true, foreign_key: true
    add_column :development_projects, :name, :string
    add_column :development_projects, :project_type, :string
    add_column :development_projects, :status, :string
    add_column :development_projects, :description, :text
    add_column :development_projects, :estimated_completion, :date
    add_column :development_projects, :estimated_cost, :decimal
    add_column :development_projects, :developer_name, :string
    add_column :development_projects, :project_url, :string
    add_column :development_projects, :details, :json

    # Make municipality_id not null after adding it
    change_column_null :development_projects, :municipality_id, false
  end
end
