class DevelopmentProject < ApplicationRecord
  belongs_to :municipality

  validates :name, presence: true
  validates :project_type, inclusion: {
    in: %w[residential commercial industrial mixed-use],
    allow_nil: true
  }
  validates :status, inclusion: {
    in: %w[proposed approved in_progress completed],
    allow_nil: true
  }
end
