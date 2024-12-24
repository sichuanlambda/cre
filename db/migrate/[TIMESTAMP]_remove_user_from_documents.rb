class RemoveUserFromDocuments < ActiveRecord::Migration[7.1]
  def change
    remove_reference :documents, :user, foreign_key: true, index: true
  end
end
