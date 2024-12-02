class AddElectionDatesToElectionCycles < ActiveRecord::Migration[7.1]
  def change
    add_column :election_cycles, :last_election_date, :date
    add_column :election_cycles, :next_election_date, :date
  end
end
