class AddNextElectionDateToCouncilMembers < ActiveRecord::Migration[7.0]
  def change
    add_column :council_members, :next_election_date, :date
  end
end
