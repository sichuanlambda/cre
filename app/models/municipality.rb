class Municipality < ApplicationRecord
  has_many :council_members, dependent: :destroy
  has_many :news_articles, dependent: :destroy
  has_one :development_score, dependent: :destroy
  has_many :municipal_resources

  validates :name, presence: true, uniqueness: true

  geocoded_by :full_address
  after_validation :geocode, if: ->(obj) { obj.name_changed? || obj.state_changed? }

  def full_address
    [name, state, 'USA'].compact.join(', ')
  end

  def next_election_date
    council_members.maximum(:next_election_date)
  end

  def development_friendliness_rating
    development_score&.current_score || 0
  end

  def self.search(query)
    if query.present?
      where("name ILIKE ?", "%#{query}%")
    else
      all
    end
  end
end
