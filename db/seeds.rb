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
