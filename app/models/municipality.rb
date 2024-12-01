class Municipality < ApplicationRecord
  has_many :council_members
  has_one :election_cycle
  has_one :development_score
  has_many :news_articles, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  def next_election_date
    election_cycle&.next_election_date
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
