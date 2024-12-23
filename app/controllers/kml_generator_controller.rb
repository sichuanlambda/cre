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
      max_height: params[:max_height].to_f,
      roof_height: params[:roof_height].to_f,
      roof_style: params[:roof_style],
      roof_overhang: params[:roof_overhang].to_f
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

    # Convert heights from feet to meters
    building_height = specs[:roof_style] && specs[:roof_style] != 'none' ?
      (specs[:max_height] - specs[:roof_height]) * 0.3048 :
      specs[:max_height] * 0.3048

    # Generate base building KML
    building_kml = generate_building_kml(footprint, building_height)

    # Generate roof KML if needed
    roof_kml = if specs[:roof_style] && specs[:roof_style] != 'none'
      generate_roof_kml(footprint, specs)
    else
      ""
    end

    # Combine into final KMLc
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
          <Style id="roofStyle">
            <PolyStyle>
              <color>7f4b2213</color>
              <outline>1</outline>
            </PolyStyle>
          </Style>
          #{building_kml}
          #{roof_kml}
        </Document>
      </kml>
    KML
  end

  def generate_building_kml(footprint, height)
    <<~KML
      <Placemark>
        <name>Building Envelope</name>
        <styleUrl>#buildingStyle</styleUrl>
        <Polygon>
          <extrude>1</extrude>
          <altitudeMode>relativeToGround</altitudeMode>
          <outerBoundaryIs>
            <LinearRing>
              <coordinates>
                #{format_coordinates(footprint, height)}
              </coordinates>
            </LinearRing>
          </outerBoundaryIs>
        </Polygon>
      </Placemark>
    KML
  end

  def generate_roof_kml(footprint, specs)
    # Convert heights from feet to meters
    base_height = (specs[:max_height] - specs[:roof_height]) * 0.3048
    ridge_height = specs[:max_height] * 0.3048

    # Calculate roof footprint with overhang
    roof_footprint = calculate_roof_footprint(footprint, specs[:roof_overhang])

    case specs[:roof_style]
    when 'gabled'
      generate_gabled_roof_kml(roof_footprint, specs)
    when 'hipped'
      generate_hipped_roof_kml(roof_footprint, specs)
    when 'mansard'
      generate_mansard_roof_kml(roof_footprint, specs)
    else # flat roof
      generate_flat_roof_kml(roof_footprint, specs)
    end
  end

  def generate_gabled_roof_kml(footprint, specs)
    # Calculate ridge line (center of roof)
    ridge_points = [
      [(footprint[0][0] + footprint[1][0]) / 2, (footprint[0][1] + footprint[1][1]) / 2],
      [(footprint[2][0] + footprint[3][0]) / 2, (footprint[2][1] + footprint[3][1]) / 2]
    ]
    base_height = specs[:max_height] - specs[:roof_height]
    ridge_height = specs[:max_height]

    <<~KML
      <Placemark>
        <name>Roof</name>
        <styleUrl>#roofStyle</styleUrl>
        <MultiGeometry>
          <!-- Front slope -->
          <Polygon>
            <extrude>1</extrude>
            <altitudeMode>relativeToGround</altitudeMode>
            <outerBoundaryIs>
              <LinearRing>
                <coordinates>
                  #{format_coordinates([footprint[0], footprint[1]], base_height)}
                  #{format_coordinates(ridge_points, ridge_height)}
                  #{format_coordinates([footprint[0]], base_height)}
                </coordinates>
              </LinearRing>
            </outerBoundaryIs>
          </Polygon>
          <!-- Back slope -->
          <Polygon>
            <extrude>1</extrude>
            <altitudeMode>relativeToGround</altitudeMode>
            <outerBoundaryIs>
              <LinearRing>
                <coordinates>
                  #{format_coordinates([footprint[2], footprint[3]], base_height)}
                  #{format_coordinates([ridge_points[1]], ridge_height)}
                  #{format_coordinates([footprint[2]], base_height)}
                </coordinates>
              </LinearRing>
            </outerBoundaryIs>
          </Polygon>
        </MultiGeometry>
      </Placemark>
    KML
  end

  def generate_hipped_roof_kml(footprint, specs)
    # Calculate peak point (center of roof)
    peak_point = [
      footprint.map { |p| p[0] }.sum / 4,
      footprint.map { |p| p[1] }.sum / 4
    ]
    base_height = specs[:max_height] - specs[:roof_height]
    ridge_height = specs[:max_height]

    <<~KML
      <Placemark>
        <name>Roof</name>
        <styleUrl>#roofStyle</styleUrl>
        <MultiGeometry>
          <!-- Four triangular faces -->
          #{(0..3).map { |i|
            next_i = (i + 1) % 4
            <<~FACE
              <Polygon>
                <extrude>1</extrude>
                <altitudeMode>relativeToGround</altitudeMode>
                <outerBoundaryIs>
                  <LinearRing>
                    <coordinates>
                      #{format_coordinates([footprint[i], footprint[next_i]], base_height)}
                      #{format_coordinates([peak_point], ridge_height)}
                      #{format_coordinates([footprint[i]], base_height)}
                    </coordinates>
                  </LinearRing>
                </outerBoundaryIs>
              </Polygon>
            FACE
          }.join}
        </MultiGeometry>
      </Placemark>
    KML
  end

  def generate_mansard_roof_kml(footprint, specs)
    inset = specs[:roof_overhang] * 0.8 # 80% of overhang for mansard slope
    base_height = specs[:max_height] - specs[:roof_height]
    top_height = specs[:max_height]

    # Calculate inset points for top surface
    inset_points = footprint.map do |point|
      [
        point[0] + (inset / 364000.0),
        point[1] + (inset / (364000.0 * Math.cos(point[0] * Math::PI / 180)))
      ]
    end

    <<~KML
      <Placemark>
        <name>Roof</name>
        <styleUrl>#roofStyle</styleUrl>
        <MultiGeometry>
          <!-- Top surface -->
          <Polygon>
            <extrude>1</extrude>
            <altitudeMode>relativeToGround</altitudeMode>
            <outerBoundaryIs>
              <LinearRing>
                <coordinates>
                  #{format_coordinates(inset_points, top_height)}
                </coordinates>
              </LinearRing>
            </outerBoundaryIs>
          </Polygon>
          <!-- Four sloped faces -->
          #{(0..3).map { |i|
            next_i = (i + 1) % 4
            <<~FACE
              <Polygon>
                <extrude>1</extrude>
                <altitudeMode>relativeToGround</altitudeMode>
                <outerBoundaryIs>
                  <LinearRing>
                    <coordinates>
                      #{format_coordinates([footprint[i]], base_height)}
                      #{format_coordinates([footprint[next_i]], base_height)}
                      #{format_coordinates([inset_points[next_i]], top_height)}
                      #{format_coordinates([inset_points[i]], top_height)}
                      #{format_coordinates([footprint[i]], base_height)}
                    </coordinates>
                  </LinearRing>
                </outerBoundaryIs>
              </Polygon>
            FACE
          }.join}
        </MultiGeometry>
      </Placemark>
    KML
  end

  def generate_flat_roof_kml(footprint, specs)
    <<~KML
      <Placemark>
        <name>Roof</name>
        <styleUrl>#roofStyle</styleUrl>
        <Polygon>
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
    KML
  end

  def calculate_roof_footprint(footprint, overhang)
    # Convert overhang to degrees
    lat_overhang = overhang / 364000.0
    lng_overhang = overhang / (364000.0 * Math.cos(footprint[0][0] * Math::PI / 180))

    footprint.map do |point|
      [
        point[0] + lat_overhang,
        point[1] + lng_overhang
      ]
    end
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

  def format_coordinates(points, height)
    # Format coordinates for KML (longitude,latitude,altitude)
    points.map { |point|
      "#{point[1]},#{point[0]},#{height}"
    }.join(" ")
  end

  def parse_coordinates(coord_string)
    # First try the decimal format
    if coord_string.match?(/^-?\d+\.?\d*,\s*-?\d+\.?\d*$/)
      lat, lng = coord_string.gsub(/\s+/, '').split(',').map(&:to_f)
      return { latitude: lat, longitude: lng } if valid_coordinates?(lat, lng)
    end

    # Try Google Earth DMS format (e.g., 35°29'06"N 97°32'28"W)
    if coord_string.match?(/^\d+°\d+'\d+"[NS]\s+\d+°\d+'\d+"[EW]$/)
      begin
        lat_dms, lng_dms = coord_string.split(/\s+/)
        lat = convert_dms_to_decimal(lat_dms)
        lng = convert_dms_to_decimal(lng_dms)
        return { latitude: lat, longitude: lng } if valid_coordinates?(lat, lng)
      rescue
        return nil
      end
    end

    nil
  end

  def convert_dms_to_decimal(dms)
    # Extract numbers and direction
    match = dms.match(/(\d+)°(\d+)'(\d+)"([NSEW])/)
    return nil unless match

    degrees, minutes, seconds, direction = match.captures

    # Convert to decimal
    decimal = degrees.to_f + (minutes.to_f / 60) + (seconds.to_f / 3600)

    # Make negative if South or West
    decimal *= -1 if direction == 'S' || direction == 'W'

    decimal
  end

  def valid_coordinates?(lat, lng)
    lat && lng && lat.between?(-90, 90) && lng.between?(-180, 180)
  end
end
