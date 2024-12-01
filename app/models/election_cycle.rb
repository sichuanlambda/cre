class ElectionCycle < ApplicationRecord
  belongs_to :municipality

  validates :cycle_years, presence: true
  validates :last_election_date, presence: true

  def next_election_date
    last_election_date + cycle_years.years
  end
end
