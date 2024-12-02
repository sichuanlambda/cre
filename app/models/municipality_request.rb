class MunicipalityRequest < ApplicationRecord
  validates :name, presence: true
end
