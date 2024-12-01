class AddElectionCycleToCouncilMembers < ActiveRecord::Migration[7.1]
  def change
    add_reference :council_members, :election_cycle, null: false, foreign_key: true
    add_column :council_members, :first_term_start_year, :integer
    add_column :council_members, :terms_served, :integer, default: 1
  end
end
