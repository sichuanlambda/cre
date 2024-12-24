class CreateDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :documents do |t|
      t.string :name
      t.string :document_type
      t.string :processing_status

      t.timestamps
    end
  end
end
