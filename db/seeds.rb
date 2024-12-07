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
puts "Creating/Updating municipalities..."

municipalities_data = [
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

municipalities_data.each do |data|
  municipality = Municipality.find_or_create_by!(
    name: data[:name],
    state: data[:state]
  )

  # Check if this municipality needs data
  needs_data = municipality.development_projects.empty? ||
               municipality.zoning_maps.empty? ||
               municipality.zoning_decisions.empty? ||
               municipality.zoning_code.nil? ||
               municipality.image_url.nil?

  if needs_data
    retries = 0
    begin
      puts "Fetching missing data for #{municipality.name}..."
      data = MunicipalityDataService.generate_data_for_municipality(municipality)

      # Add skyline image if missing
      if !municipality.image_url.present? && data["skyline_image_url"].present?
        puts "Adding skyline image..."
        municipality.update!(image_url: data["skyline_image_url"])
      end

      # Add council members if none exist
      if municipality.council_members.empty? && data["council_members"].present?
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
      if !municipality.news_articles.empty? && data["news_articles"].present?
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
      if !municipality.municipal_resources.empty? && data["municipal_resources"].present?
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

      # Add zoning maps if none exist
      if !municipality.zoning_maps.empty? && data["zoning_maps"].present?
        puts "Saving zoning maps..."
        data["zoning_maps"].each do |map|
          municipality.zoning_maps.find_or_create_by!(url: map["url"]) do |zm|
            zm.title = map["title"]
            zm.last_updated = map["last_updated"]
            zm.coverage_area = map["coverage_area"]
            zm.map_type = map["map_type"]
          end
        end
      end

      # Add zoning decisions if none exist
      # if !municipality.zoning_decisions.empty? && data["zoning_decisions"].present?
      #   puts "Saving zoning decisions..."
      #   data["zoning_decisions"].each do |decision|
      #     municipality.zoning_decisions.find_or_create_by!(
      #       decision_date: decision["decision_date"],
      #       location: decision["location"]
      #     ) do |zd|
      #       zd.decision_type = decision["type"]
      #       zd.description = decision["description"]
      #       zd.status = decision["status"]
      #     end
      #   end
      # end

      # Add development projects if none exist
      if !municipality.development_projects.empty? && data["development_projects"].present?
        puts "Saving development projects..."
        data["development_projects"].each do |project|
          begin
            municipality.development_projects.find_or_create_by!(name: project["name"]) do |p|
              p.project_type = project["project_type"]
              p.status = project["status"]
              p.description = project["description"]
              p.estimated_completion = project["estimated_completion"]
              p.estimated_cost = project["estimated_cost"]
              p.developer_name = project["developer_name"]
              p.project_url = project["project_url"]
              p.details = project["details"] || {}
            end
          rescue ActiveRecord::RecordInvalid => e
            puts "Skipping invalid project for #{municipality.name}: #{e.message}"
          end
        end
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
  else
    puts "Skipping #{municipality.name} - data is complete"
  end
end

puts "Seed completed!"
