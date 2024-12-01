class AddNameToElectionCycles < ActiveRecord::Migration[7.1]
  def change
    add_column :election_cycles, :name, :string, null: false, default: "Unnamed Cycle"
  end
end
