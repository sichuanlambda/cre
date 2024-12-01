class CreateElectionCycles < ActiveRecord::Migration[7.1]
  def change
    create_table :election_cycles do |t|
      t.date :next_election_date
      t.references :municipality, null: false, foreign_key: true

      t.timestamps
    end
  end
end
