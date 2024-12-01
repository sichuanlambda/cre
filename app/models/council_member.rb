class CouncilMember < ApplicationRecord
  belongs_to :municipality
  belongs_to :election_cycle

  validates :name, presence: true
  validates :position, presence: true
  validates :first_term_start_year, presence: true
  validates :terms_served, presence: true, numericality: { greater_than_or_equal_to: 1 }

  serialize :social_links, coder: JSON

  def term_status
    return "No election cycle set" unless election_cycle
    return "Term Limited" if term_limited?
    "Eligible for reelection in #{next_eligible_year}"
  end

  def term_limited?
    return false unless election_cycle
    terms_served >= election_cycle.cycle_years
  end

  def next_eligible_year
    return nil unless election_cycle
    current_term_end_year + election_cycle.cycle_years
  end

  private

  def current_term_end_year
    first_term_start_year + (terms_served * years_per_term) - 1
  end

  def years_per_term
    4  # You might want to make this configurable
  end
end
