# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "Starting seed process..."

# Don't clear existing data
# Remove the destroy_all commands

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

  # Add retry logic for rate limits
  retries = 0
  begin
    # Only fetch data if something is missing
    if !municipality.council_members.exists? ||
       !municipality.development_score.present? ||
       !municipality.news_articles.exists? ||
       !municipality.municipal_resources.exists?

      puts "Fetching missing data for #{municipality.name}..."
      data = MunicipalityDataService.generate_data_for_municipality(municipality)

      # Add council members if none exist
      if !municipality.council_members.exists? && data["council_members"].present?
        puts "Adding council members..."
        data["council_members"].each do |member_data|
          reelection_info = data["reelection_dates"]&.find { |rd| rd && rd["council_member_name"] == member_data["name"] }

          municipality.council_members.find_or_create_by!(
            name: member_data["name"]
          ) do |member|
            member.position = member_data["position"].presence || "Council Member"
            member.social_links = member_data["social_links"] || {}
            member.next_election_date = reelection_info&.dig("next_election_date")
          end
        end
      end

      # Create development score if missing
      if !municipality.development_score && data["development_score"]
        puts "Creating development score..."
        municipality.create_development_score!(
          current_score: data["development_score"]["current_score"]
        )
      end

      # Add news articles if none exist
      if !municipality.news_articles.exists? && data["news_articles"].present?
        puts "Saving news articles..."
        relevant_topics = [
          'rezoning', 'zoning', 'city council', 'council vote', 'council election',
          'urban development', 'comprehensive plan', 'real estate development',
          'housing development', 'land use', 'planning commission',
          'building permits', 'property development', 'municipal development',
          'affordable housing', 'mixed-use development'
        ]

        data["news_articles"].each do |article_data|
          begin
            # Only create articles that match our relevant topics
            if relevant_topics.any? { |topic|
              (article_data[:title].to_s.downcase + article_data[:description].to_s.downcase).include?(topic)
            }
              municipality.news_articles.find_or_create_by!(url: article_data[:url]) do |article|
                article.title = article_data[:title]
                article.description = article_data[:description]
                article.published_at = article_data[:published_at] || Time.current
              end
            end
          rescue ActiveRecord::RecordInvalid => e
            puts "Skipping invalid article for #{municipality.name}: #{e.message}"
          end
        end
      end

      # Add municipal resources if none exist
      if !municipality.municipal_resources.exists? && data["municipal_resources"].present?
        puts "Saving municipal resources..."
        data["municipal_resources"].each do |category, resources|
          resources.each do |resource|
            begin
              municipality.municipal_resources.find_or_create_by!(url: resource["url"]) do |r|
                r.title = resource["title"]
                r.description = resource["description"]
                r.category = category
                r.last_updated = resource["last_updated"]
              end
            rescue ActiveRecord::RecordInvalid => e
              puts "Skipping invalid resource for #{municipality.name}: #{e.message}"
            end
          end
        end
      end
    else
      puts "Skipping #{municipality.name} - data is complete"
    end

  rescue StandardError => e
    retries += 1
    if retries <= 3 && e.message.include?('status 429')
      puts "Rate limited, waiting 60 seconds before retry #{retries}/3..."
      sleep 60
      retry
    else
      puts "Error fetching data for #{municipality.name}: #{e.message}"
    end
  end
end

puts "Seed completed!"
