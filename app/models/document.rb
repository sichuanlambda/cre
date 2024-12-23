class Document < ApplicationRecord
  belongs_to :user
  has_one_attached :file
  has_many :embeddings, dependent: :destroy

  validates :name, presence: true
  validates :file, presence: true

  # Document types we'll support
  VALID_TYPES = %w[lease contract proposal offering_memo].freeze
  validates :document_type, inclusion: { in: VALID_TYPES }

  def process_for_embeddings
    ExtractEmbeddingsJob.perform_later(self)
  end
end
