class ZoningRecord < ApplicationRecord
  belongs_to :municipality

  validates :record_type, inclusion: {
    in: %w[map rezoning_request incentive impact_fee],
    allow_nil: true
  }
  validates :title, presence: true
end
