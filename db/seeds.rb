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
  { name: "Kansas City", state: "MO", country: "USA" },
  { name: "Oklahoma City", state: "OK", country: "USA" },
  { name: "Denver", state: "CO", country: "USA" },
  { name: "Nashville", state: "TN", country: "USA" },
  { name: "Plano", state: "TX", country: "USA" },
  { name: "Boston", state: "MA", country: "USA" },
  { name: "Raleigh", state: "NC", country: "USA" }
]

puts "Creating/Updating municipalities..."
municipalities.each do |muni_data|
  municipality = Municipality.find_or_create_by!(name: muni_data[:name]) do |muni|
    muni.state = muni_data[:state]
    muni.country = muni_data[:country]
  end

  # Skip if municipality has complete data
  if municipality.council_members.any? &&
     municipality.development_score.present? &&
     municipality.news_articles.any?
    puts "Skipping #{municipality.name} - already has complete data"
    next
  end

  puts "Fetching data for #{municipality.name}..."
  data = MunicipalityDataService.generate_data_for_municipality(municipality)

  # Create council members if none exist
  if municipality.council_members.empty?
    puts "Creating council members..."
    data["council_members"].each do |member_data|
      puts "Processing member: #{member_data["name"]}"

      reelection_info = if data["reelection_dates"].is_a?(Array)
        data["reelection_dates"].find { |rd| rd && rd["council_member_name"] == member_data["name"] }
      else
        puts "Warning: Invalid reelection dates format for #{municipality.name}"
        nil
      end

      municipality.council_members.create!(
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
end

puts "Seed completed!"
