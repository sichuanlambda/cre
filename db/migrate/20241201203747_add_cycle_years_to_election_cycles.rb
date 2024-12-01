class AddCycleYearsToElectionCycles < ActiveRecord::Migration[7.1]
  def change
    add_column :election_cycles, :cycle_years, :integer
  end
end
