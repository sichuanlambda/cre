# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create test municipalities
municipalities = [
  { name: "Kansas City", state: "MO", country: "USA" },
  { name: "Oklahoma City", state: "OK", country: "USA" },
  { name: "Denver", state: "CO", country: "USA" }
]

municipalities.each do |muni_data|
  Municipality.find_or_create_by!(name: muni_data[:name]) do |muni|
    muni.state = muni_data[:state]
    muni.country = muni_data[:country]
  end
end

Municipality.find_each do |municipality|
  data = MunicipalityDataService.generate_data_for_municipality(municipality)

  # Create council members
  data["council_members"].each do |member_data|
    municipality.council_members.find_or_create_by!(name: member_data["name"]) do |member|
      member.position = member_data["position"]
      member.social_links = member_data["social_links"]
    end
  end

  # Create or update election cycle
  municipality.create_election_cycle!(
    next_election_date: data["election_cycle"]["next_election_date"],
    cycle_years: data["election_cycle"]["cycle_years"]
  )

  # Create or update development score
  municipality.create_development_score!(
    current_score: data["development_score"]["current_score"]
  )
end
