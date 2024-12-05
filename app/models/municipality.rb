class Municipality < ApplicationRecord
  has_many :council_members, dependent: :destroy
  has_many :news_articles, dependent: :destroy
  has_one :development_score, dependent: :destroy
  has_many :municipal_resources

  if self.connection.table_exists?('development_projects')
    has_many :development_projects, dependent: :destroy
  end

  if self.connection.table_exists?('zoning_records')
    has_many :zoning_records, dependent: :destroy
  end

  validates :name, presence: true, uniqueness: true

  geocoded_by :full_address
  after_validation :geocode, if: ->(obj) { obj.name_changed? || obj.state_changed? }

  STATE_MAPPING = {
    'alabama' => 'AL', 'alaska' => 'AK', 'arizona' => 'AZ', 'arkansas' => 'AR',
    'california' => 'CA', 'colorado' => 'CO', 'connecticut' => 'CT', 'delaware' => 'DE',
    'florida' => 'FL', 'georgia' => 'GA', 'hawaii' => 'HI', 'idaho' => 'ID',
    'illinois' => 'IL', 'indiana' => 'IN', 'iowa' => 'IA', 'kansas' => 'KS',
    'kentucky' => 'KY', 'louisiana' => 'LA', 'maine' => 'ME', 'maryland' => 'MD',
    'massachusetts' => 'MA', 'michigan' => 'MI', 'minnesota' => 'MN', 'mississippi' => 'MS',
    'missouri' => 'MO', 'montana' => 'MT', 'nebraska' => 'NE', 'nevada' => 'NV',
    'new hampshire' => 'NH', 'new jersey' => 'NJ', 'new mexico' => 'NM', 'new york' => 'NY',
    'north carolina' => 'NC', 'north dakota' => 'ND', 'ohio' => 'OH', 'oklahoma' => 'OK',
    'oregon' => 'OR', 'pennsylvania' => 'PA', 'rhode island' => 'RI', 'south carolina' => 'SC',
    'south dakota' => 'SD', 'tennessee' => 'TN', 'texas' => 'TX', 'utah' => 'UT',
    'vermont' => 'VT', 'virginia' => 'VA', 'washington' => 'WA', 'west virginia' => 'WV',
    'wisconsin' => 'WI', 'wyoming' => 'WY'
  }

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
      query = query.downcase
      state_abbrev = STATE_MAPPING[query] || query.upcase

      where("LOWER(name) LIKE :query OR state = :state_abbrev",
            query: "%#{query}%",
            state_abbrev: state_abbrev)
    else
      all
    end
  end

  def active_projects
    return [] unless self.class.connection.table_exists?('development_projects')
    development_projects.where(status: ['approved', 'in_progress'])
  end

  def upcoming_projects
    return [] unless self.class.connection.table_exists?('development_projects')
    development_projects.where(status: 'proposed')
  end

  def rezoning_requests
    return [] unless self.class.connection.table_exists?('zoning_records')
    zoning_records.where(record_type: 'rezoning_request')
  end

  def development_incentives
    return [] unless self.class.connection.table_exists?('zoning_records')
    zoning_records.where(record_type: 'incentive')
  end

  def impact_fees
    return [] unless self.class.connection.table_exists?('zoning_records')
    zoning_records.where(record_type: 'impact_fee')
  end

  def zoning_maps
    return [] unless self.class.connection.table_exists?('zoning_records')
    zoning_records.where(record_type: 'map')
  end
end
