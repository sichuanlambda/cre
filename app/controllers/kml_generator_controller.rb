class KmlGeneratorController < ApplicationController
  def new
  end

  def create
    coordinates = parse_coordinates(params[:coordinates])

    unless coordinates
      flash[:error] = "Invalid coordinates format. Please paste coordinates directly from Google Maps."
      return redirect_to kml_generator_new_path
    end

    @building_specs = {
      lot_width: params[:lot_width].to_f,
      lot_depth: params[:lot_depth].to_f,
      front_setback: params[:front_setback].to_f,
      rear_setback: params[:rear_setback].to_f,
      side_setback: params[:side_setback].to_f,
      floor_area_ratio: params[:floor_area_ratio].to_f,
      max_height: params[:max_height].to_f
    }

    respond_to do |format|
      format.html do
        # Generate KML content
        kml_content = generate_kml(coordinates, @building_specs)

        # Send file to browser
        send_data kml_content,
                  filename: "building_envelope.kml",
                  type: "application/vnd.google-earth.kml+xml",
                  disposition: 'attachment'
      end

      format.turbo_stream do
        # Handle Turbo Stream format if needed
        redirect_to kml_generator_new_path
      end
    end
  end

  private

  def generate_kml(coordinates, specs)
    # Calculate building footprint coordinates
    footprint = calculate_building_footprint(coordinates, specs)

    # Generate KML format
    <<~KML
      <?xml version="1.0" encoding="UTF-8"?>
      <kml xmlns="http://www.opengis.net/kml/2.2">
        <Document>
          <Style id="buildingStyle">
            <PolyStyle>
              <color>7f0000ff</color>
              <outline>1</outline>
            </PolyStyle>
          </Style>
          <Placemark>
            <name>Building Envelope</name>
            <styleUrl>#buildingStyle</styleUrl>
            <Polygon>
              <extrude>1</extrude>
              <altitudeMode>relativeToGround</altitudeMode>
              <outerBoundaryIs>
                <LinearRing>
                  <coordinates>
                    #{format_coordinates(footprint, specs[:max_height])}
                  </coordinates>
                </LinearRing>
              </outerBoundaryIs>
            </Polygon>
          </Placemark>
        </Document>
      </kml>
    KML
  end

  def calculate_building_footprint(coordinates, specs)
    # Convert feet to degrees (approximate)
    lat_degree_per_foot = 1.0 / 364000.0
    lng_degree_per_foot = 1.0 / (364000.0 * Math.cos(coordinates[:latitude] * Math::PI / 180))

    # Calculate buildable area
    buildable_width = specs[:lot_width] - (specs[:side_setback] * 2)
    buildable_depth = specs[:lot_depth] - specs[:front_setback] - specs[:rear_setback]

    # Calculate corners (clockwise from northwest)
    [
      [coordinates[:latitude] + (buildable_depth/2 * lat_degree_per_foot),
       coordinates[:longitude] - (buildable_width/2 * lng_degree_per_foot)],
      [coordinates[:latitude] + (buildable_depth/2 * lat_degree_per_foot),
       coordinates[:longitude] + (buildable_width/2 * lng_degree_per_foot)],
      [coordinates[:latitude] - (buildable_depth/2 * lat_degree_per_foot),
       coordinates[:longitude] + (buildable_width/2 * lng_degree_per_foot)],
      [coordinates[:latitude] - (buildable_depth/2 * lat_degree_per_foot),
       coordinates[:longitude] - (buildable_width/2 * lng_degree_per_foot)]
    ]
  end

  def format_coordinates(footprint, height)
    # Format coordinates for KML (longitude,latitude,altitude)
    footprint.map { |point|
      "#{point[1]},#{point[0]},#{height}"
    }.join(" ") + " #{footprint[0][1]},#{footprint[0][0]},#{height}"
  end

  def parse_coordinates(coord_string)
    # Remove any whitespace and split by comma
    lat, lng = coord_string.gsub(/\s+/, '').split(',').map(&:to_f)

    # Return nil if coordinates are invalid
    return nil unless lat && lng && lat.between?(-90, 90) && lng.between?(-180, 180)

    { latitude: lat, longitude: lng }
  end
end
