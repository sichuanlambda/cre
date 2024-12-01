class CouncilMember < ApplicationRecord
  belongs_to :municipality

  validates :name, presence: true
  validates :position, presence: true

  serialize :social_links, coder: JSON

  def term_status
    return "Term Limited" if term_limited?
    "Eligible for reelection in #{next_eligible_year}"
  end
end
