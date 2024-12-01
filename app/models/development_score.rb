class DevelopmentScore < ApplicationRecord
  belongs_to :municipality

  validates :current_score, numericality: { only_integer: true,
                                          greater_than_or_equal_to: 0,
                                          less_than_or_equal_to: 100 }

  def rating_description
    case current_score
    when 80..100 then "Very Development Friendly"
    when 60..79 then "Development Friendly"
    when 40..59 then "Moderately Development Friendly"
    when 20..39 then "Somewhat Development Resistant"
    else "Development Resistant"
    end
  end
end
