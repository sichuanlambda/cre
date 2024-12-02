class MunicipalResource < ApplicationRecord
  belongs_to :municipality

  validates :title, presence: true
  validates :category, presence: true,
    inclusion: { in: %w[zoning_documents council_meetings permit_applications development_plans public_notices] }
end
