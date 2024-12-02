# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Clear existing data
puts "Clearing existing data..."
CouncilMember.destroy_all
NewsArticle.destroy_all
DevelopmentScore.destroy_all
Municipality.destroy_all

# Create municipalities
municipalities = [
  { name: "Albuquerque", state: "NM", country: "USA" },
  { name: "Atlanta", state: "GA", country: "USA" },
  { name: "Austin", state: "TX", country: "USA" },
  { name: "Bakersfield", state: "CA", country: "USA" },
  { name: "Berkeley", state: "CA", country: "USA" },
  { name: "Boise", state: "ID", country: "USA" },
  { name: "Boston", state: "MA", country: "USA" },
  { name: "Charlotte", state: "NC", country: "USA" },
  { name: "Chicago", state: "IL", country: "USA" },
  { name: "Cleveland", state: "OH", country: "USA" },
  { name: "Columbus", state: "OH", country: "USA" },
  { name: "Dallas", state: "TX", country: "USA" },
  { name: "Denver", state: "CO", country: "USA" },
  { name: "Detroit", state: "MI", country: "USA" },
  { name: "Flint", state: "MI", country: "USA" },
  { name: "Honolulu", state: "HI", country: "USA" },
  { name: "Houston", state: "TX", country: "USA" },
  { name: "Kansas City", state: "MO", country: "USA" },
  { name: "Los Angeles", state: "CA", country: "USA" },
  { name: "Memphis", state: "TN", country: "USA" },
  { name: "Miami", state: "FL", country: "USA" },
  { name: "Minneapolis", state: "MN", country: "USA" },
  { name: "Nashville", state: "TN", country: "USA" },
  { name: "New Orleans", state: "LA", country: "USA" },
  { name: "New York City", state: "NY", country: "USA" },
  { name: "Oakland", state: "CA", country: "USA" },
  { name: "Oklahoma City", state: "OK", country: "USA" },
  { name: "Phoenix", state: "AZ", country: "USA" },
  { name: "Plano", state: "TX", country: "USA" },
  { name: "Portland", state: "OR", country: "USA" },
  { name: "Raleigh", state: "NC", country: "USA" },
  { name: "Richmond", state: "VA", country: "USA" },
  { name: "Sacramento", state: "CA", country: "USA" },
  { name: "Salt Lake City", state: "UT", country: "USA" },
  { name: "San Diego", state: "CA", country: "USA" },
  { name: "San Francisco", state: "CA", country: "USA" },
  { name: "Seattle", state: "WA", country: "USA" },
  { name: "Spokane", state: "WA", country: "USA" },
  { name: "Springfield", state: "OH", country: "USA" },
  { name: "St. Paul", state: "MN", country: "USA" },
  { name: "Washington", state: "DC", country: "USA" }
]

puts "Creating/Updating municipalities..."
municipalities.each do |muni_data|
  municipality = Municipality.find_or_create_by!(name: muni_data[:name]) do |muni|
    muni.state = muni_data[:state]
    muni.country = muni_data[:country]
    puts "Created new municipality: #{muni.name}, #{muni.state}"
  end

  # Skip only if municipality has all required data
  if municipality.council_members.exists? &&
     municipality.development_score.present? &&
     municipality.news_articles.exists?
    puts "Skipping #{municipality.name} - data is complete"
    next
  end

  puts "Fetching data for #{municipality.name}..."
  begin
    data = MunicipalityDataService.generate_data_for_municipality(municipality)

    # Add new council members without removing existing ones
    if data["council_members"].present?
      puts "Adding new council members..."
      data["council_members"].each do |member_data|
        reelection_info = data["reelection_dates"]&.find { |rd| rd && rd["council_member_name"] == member_data["name"] }

        municipality.council_members.find_or_create_by!(
          name: member_data["name"],
          position: member_data["position"].presence || "Council Member",
          social_links: member_data["social_links"] || {},
          next_election_date: reelection_info&.dig("next_election_date")
        )
      end
    end

    # Create development score if it doesn't exist
    if municipality.development_score.nil?
      puts "Creating development score..."
      municipality.create_development_score!(
        current_score: data["development_score"]["current_score"]
      )
    end

    # Create news articles if none exist
    if municipality.news_articles.empty?
      puts "Saving news articles..."
      data["news_articles"].each do |article_data|
        begin
          municipality.news_articles.create!(
            title: article_data[:title],
            description: article_data[:description],
            url: article_data[:url],
            published_at: article_data[:published_at] || Time.current
          )
        rescue ActiveRecord::RecordInvalid => e
          if e.message.include?('Url has already been taken')
            puts "Skipping duplicate article: #{article_data[:title]}"
            next
          end
        end
      end
    end
  rescue StandardError => e
    puts "Error fetching data for #{municipality.name}: #{e.message}"
  end
end

puts "Seed completed!"
