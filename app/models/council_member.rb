class CouncilMember < ApplicationRecord
  belongs_to :municipality

  validates :name, presence: true
  validates :position, presence: true
  validates :first_term_start_year, presence: false
  validates :terms_served, presence: false

  serialize :social_links, coder: JSON

  def term_status
    if next_election_date
      "Next election on #{next_election_date.strftime('%B %d, %Y')}"
    else
      "No election date available"
    end
  end

  def term_limited?
    return false unless terms_served
    terms_served >= 2  # Or whatever your term limit is
  end

  def next_eligible_year
    return nil unless first_term_start_year && terms_served
    first_term_start_year + (terms_served * years_per_term)
  end

  private

  def years_per_term
    4  # You might want to make this configurable
  end
end
