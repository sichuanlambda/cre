class CreateSubscriptions < ActiveRecord::Migration[7.0]
  def change
    create_table :subscriptions do |t|
      t.string :email, null: false
      t.timestamps
    end

    add_index :subscriptions, :email, unique: true
  end
end
