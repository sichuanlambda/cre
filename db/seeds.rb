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

  # Check each type of data individually
  missing_data = {
    development_projects: municipality.development_projects.empty?,
    zoning_maps: municipality.zoning_maps.empty?,
    zoning_code: municipality.zoning_code.nil?,
    image_url: municipality.image_url.nil?,
    council_members: municipality.council_members.empty?,
    news_articles: municipality.news_articles.empty?,
    municipal_resources: municipality.municipal_resources.empty?,
    development_score: !municipality.development_score
  }

  if missing_data.values.any?(true)
    retries = 0
    begin
      puts "Fetching missing data for #{municipality.name}..."
      puts "Missing: #{missing_data.select { |k,v| v }.keys.join(', ')}"

      data = MunicipalityDataService.generate_data_for_municipality(municipality)

      # Add skyline image if missing
      if missing_data[:image_url] && data["skyline_image_url"].present?
        puts "Adding skyline image..."
        municipality.update!(image_url: data["skyline_image_url"])
      end

      # Add council members if none exist
      if missing_data[:council_members] && data["council_members"].present?
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
      if missing_data[:development_score] && data["development_score"]
        puts "Creating development score..."
        municipality.create_development_score!(
          current_score: data["development_score"]["current_score"]
        )
      end

      # Add news articles if missing
      if missing_data[:news_articles] && data["news_articles"].present?
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

      # Add municipal resources if missing
      if missing_data[:municipal_resources] && data["municipal_resources"].present?
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

      # Add zoning maps if missing
      if missing_data[:zoning_maps] && data["zoning_maps"].present?
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

      # Add development projects if missing
      if missing_data[:development_projects] && data["development_projects"].present?
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
    puts "Skipping #{municipality.name} - all data is complete"
  end
end

CITY_IMAGES = {
  'Albuquerque' => 'https://images.pexels.com/photos/794641/pexels-photo-794641.jpeg?',
  'Atlanta' => 'https://images.pexels.com/photos/2815184/pexels-photo-2815184.jpeg',
  'Austin' => 'https://images.unsplash.com/photo-1588993608283-7f0eda4438be?q=80&w=2970&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  'Bakersfield' => 'https://images.pexels.com/photos/3751013/pexels-photo-3751013.jpeg', #fix
  'Berkeley' => 'https://images.unsplash.com/photo-1671709363686-a7899fb1238e?q=80&w=2970&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  'Boise' => 'https://images.unsplash.com/photo-1465244554671-e501f19a3bb3?q=80&w=2970&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  'Boston' => 'https://plus.unsplash.com/premium_photo-1694475423949-9685bb4fa0bc?q=80&w=2970&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  'Charlotte' => 'https://plus.unsplash.com/premium_photo-1682804225008-4cd4542e91d5?q=80&w=3175&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  'Chicago' => 'https://images.unsplash.com/photo-1467226632440-65f0b4957563?q=80&w=2887&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  'Cleveland' => 'https://images.pexels.com/photos/3751017/pexels-photo-3751017.jpeg', #fix
  'Columbus' => 'https://images.unsplash.com/photo-1568652463208-f8fe991eb6b9?q=80&w=3174&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  'Dallas' => 'https://plus.unsplash.com/premium_photo-1697729753410-667607f7afd4?q=80&w=3132&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  'Denver' => 'https://images.pexels.com/photos/9376507/pexels-photo-9376507.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2',
  'Detroit' => 'https://images.pexels.com/photos/702343/pexels-photo-702343.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2',
  'Flint' => 'https://images.pexels.com/photos/3751021/pexels-photo-3751021.jpeg',
  'Honolulu' => 'https://images.unsplash.com/photo-1684727906248-b36353278801?q=80&w=2960&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  'Houston' => 'https://plus.unsplash.com/premium_photo-1694475099470-b12dc8ce0798?q=80&w=2972&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  'Kansas City' => 'https://plus.unsplash.com/premium_photo-1697729864667-57f5f29e946b?q=80&w=2970&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  'Los Angeles' => 'https://plus.unsplash.com/premium_photo-1725408106567-a77bd9beff7c?q=80&w=2970&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  'Memphis' => 'https://images.pexels.com/photos/3751025/pexels-photo-3751025.jpeg',#fix
  'Miami' => 'https://images.unsplash.com/photo-1506966953602-c20cc11f75e3?q=80&w=3000&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  'Minneapolis' => 'https://plus.unsplash.com/premium_photo-1670176446913-ca025ebaf172?q=80&w=2969&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  'Nashville' => 'https://images.unsplash.com/photo-1556033681-83abea291a96?q=80&w=3064&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  'New Orleans' => 'https://images.unsplash.com/photo-1640583430339-f83d93e77413?q=80&w=3002&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  'New York City' => 'https://images.unsplash.com/photo-1700730287621-452087138d73?q=80&w=2970&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  'Oakland' => 'https://images.pexels.com/photos/3751029/pexels-photo-3751029.jpeg', #fix
  'Oklahoma City' => 'https://images.unsplash.com/photo-1519876217051-4449feb0b589?q=80&w=2912&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  'Phoenix' => 'https://images.pexels.com/photos/3751031/pexels-photo-3751031.jpeg', #fix
  'Plano' => 'https://images.pexels.com/photos/3751032/pexels-photo-3751032.jpeg', #fix
  'Portland' => 'https://images.pexels.com/photos/432361/pexels-photo-432361.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2',
  'Raleigh' => 'https://images.pexels.com/photos/29467679/pexels-photo-29467679/free-photo-of-aerial-view-of-raleigh-skyline-with-rail-lines.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2',
  'Richmond' => 'https://images.unsplash.com/photo-1631584085080-5dbd19558feb?q=80&w=2970&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  'Sacramento' => 'https://images.pexels.com/photos/29583198/pexels-photo-29583198/free-photo-of-sacramento-cityscape-featuring-cathedral-of-the-blessed-sacrament.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2',
  'Salt Lake City' => 'https://images.pexels.com/photos/3751036/pexels-photo-3751036.jpeg', #fix
  'San Diego' => 'https://images.pexels.com/photos/2157685/pexels-photo-2157685.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2',
  'San Francisco' => 'https://images.pexels.com/photos/3584437/pexels-photo-3584437.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2',
  'Seattle' => 'https://images.pexels.com/photos/3964406/pexels-photo-3964406.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2',
  'Spokane' => 'https://images.pexels.com/photos/9229457/pexels-photo-9229457.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2',
  'Springfield' => 'https://images.pexels.com/photos/3751039/pexels-photo-3751039.jpeg',
  'St. Paul' => 'https://images.pexels.com/photos/3751040/pexels-photo-3751040.jpeg',
  'Washington' => 'https://images.pexels.com/photos/208686/pexels-photo-208686.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2'
}

# Update municipalities with images
CITY_IMAGES.each do |city, image_url|
  municipality = Municipality.find_by(name: city)
  municipality&.update(image_url: image_url)
end

puts "Seed completed!"
