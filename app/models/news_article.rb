class NewsArticle < ApplicationRecord
  belongs_to :municipality

  validates :title, presence: true
  validates :url, presence: true, uniqueness: true
  validates :published_at, presence: true

  default_scope { order(published_at: :desc) }
end