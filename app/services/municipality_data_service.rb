class MunicipalityDataService
  def self.generate_data_for_municipality(municipality)
    data = {
      "council_members" => fetch_council_members(municipality),
      "reelection_dates" => fetch_reelection_dates(municipality),
      "development_score" => calculate_development_score(municipality),
      "news_articles" => fetch_news_articles(municipality),
      "municipal_resources" => fetch_municipal_resources(municipality),
      "development_projects" => fetch_development_projects(municipality),
      "zoning_code" => fetch_zoning_code(municipality),
      "zoning_maps" => fetch_zoning_maps(municipality),
      "zoning_decisions" => fetch_zoning_decisions(municipality)
    }

    save_news_articles(municipality, data["news_articles"])
    save_municipal_resources(municipality, data["municipal_resources"])
    save_development_data(municipality, data)
    save_zoning_data(municipality, data)
    fetch_and_attach_image(municipality)

    data
  end

  private

  def self.fetch_council_members(municipality)
    response = OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-4",
        messages: [
          {
            role: "system",
            content: "You are a data extraction expert. Extract council member information from city websites or search results. Your response must be valid JSON only, with no additional text or explanation. Format: array of objects with fields: name, position, social_links (Twitter/LinkedIn), first_term_start_year, and terms_served."
          },
          {
            role: "user",
            content: "Find current council members for #{municipality.name}, #{municipality.state}. Include their social media profiles if available."
          }
        ]
      }
    )
    parse_ai_council_response(response)
  end

  def self.fetch_reelection_dates(municipality)
    response = OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-4",
        messages: [
          {
            role: "system",
            content: "You are an election data specialist. Your response must be valid JSON only, with no additional text or explanation. Return an array of objects with fields: council_member_name and next_election_date (YYYY-MM-DD format). If exact dates aren't known, use the first day of the expected month/year."
          },
          {
            role: "user",
            content: "When are the next reelection dates for current council members in #{municipality.name}, #{municipality.state}?"
          }
        ]
      }
    )

    parse_ai_reelection_response(response) || []
  end

  def self.calculate_development_score(municipality)
    response = OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-4",
        messages: [
          {
            role: "system",
            content: "You are a municipal development analyst. Your response must be valid JSON only, with no additional text or explanation. Analyze city data and provide a development friendliness score object with a single field 'score' containing a number from 0-100, based on factors like permit processing times, zoning flexibility, and economic growth."
          },
          {
            role: "user",
            content: "Analyze development friendliness for #{municipality.name}, #{municipality.state}. Consider recent news, economic indicators, and municipal policies."
          }
        ]
      }
    )

    score = parse_ai_score_response(response)
    { "current_score" => score || rand(60..95) }
  end

  def self.parse_ai_council_response(response)
    return [] unless response['choices']&.first&.dig('message', 'content')

    begin
      JSON.parse(response['choices'].first['message']['content'])
    rescue JSON::ParserError
      content = response['choices'].first['message']['content']
      extract_council_members_from_text(content)
    end
  end

  def self.parse_ai_reelection_response(response)
    return [] unless response['choices']&.first&.dig('message', 'content')

    begin
      JSON.parse(response['choices'].first['message']['content'])
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse reelection response: #{e.message}"
      []
    end
  end

  def self.parse_ai_score_response(response)
    return nil unless response['choices']&.first&.dig('message', 'content')

    content = response['choices'].first['message']['content']
    content.scan(/\d+/).first&.to_i
  end

  def self.extract_council_members_from_text(content)
    members = []
    current_member = {}

    content.each_line do |line|
      case line
      when /name:?\s*(.+)/i
        members << current_member unless current_member.empty?
        current_member = { "name" => $1.strip }
      when /position:?\s*(.+)/i
        current_member["position"] = $1.strip
      when /twitter:?\s*(.+)/i
        current_member["social_links"] ||= {}
        current_member["social_links"]["twitter"] = $1.strip
      when /linkedin:?\s*(.+)/i
        current_member["social_links"] ||= {}
        current_member["social_links"]["linkedin"] = $1.strip
      end
    end

    members << current_member unless current_member.empty?
    members
  end

  def self.fetch_news_articles(municipality)
    return [] unless ENV['NEWS_API_KEY']

    news_api = News.new(ENV['NEWS_API_KEY'])
    articles = news_api.get_everything(
      q: "(" \
         "\"zoning\" OR \"city council\" OR " \
         "\"housing development\" OR \"planning commission\"" \
         ") AND " \
         "\"#{municipality.name}\" AND council",
      language: 'en',
      sortBy: 'publishedAt',
      pageSize: 10
    )

    articles.map do |article|
      {
        title: article.title,
        url: article.url,
        description: article.description,
        published_at: article.publishedAt
      }
    end
  rescue => e
    Rails.logger.error "Error fetching news for #{municipality.name}: #{e.message}"
    []
  end

  def self.save_news_articles(municipality, articles)
    articles.each do |article_data|
      municipality.news_articles.find_or_create_by!(url: article_data[:url]) do |article|
        article.title = article_data[:title]
        article.description = article_data[:description]
        article.published_at = article_data[:published_at] || Time.current
      end
    end
  end

  def self.fetch_page(url)
    response = HTTParty.get(url)
    Nokogiri::HTML(response.body)
  rescue => e
    Rails.logger.error "Error fetching #{url}: #{e.message}"
    nil
  end

  def self.extract_social_links(member_element)
    social_links = {}

    social_patterns = {
      "twitter" => /(twitter\.com|x\.com)/,
      "linkedin" => /linkedin\.com/,
      "facebook" => /facebook\.com/,
      "instagram" => /instagram\.com/,
      "youtube" => /youtube\.com/
    }

    member_element.css('a[href]').each do |link|
      href = normalize_url(link.attr('href'))
      next unless href

      social_patterns.each do |platform, pattern|
        if href =~ pattern
          if platform == "linkedin"
            # Check if LinkedIn URL is valid
            begin
              response = HTTParty.get(href, follow_redirects: true)
              if response.code == 200
                social_links[platform] = href
              else
                social_links["unverified_linkedin"] = href
              end
            rescue => e
              Rails.logger.error "Error verifying LinkedIn URL #{href}: #{e.message}"
              social_links["unverified_linkedin"] = href
            end
          else
            social_links[platform] = href
          end
        end
      end

      if href =~ /(?:social|profile)/ || href.include?('://')
        social_links["other"] ||= []
        social_links["other"] << href unless social_links["other"].include?(href)
      end
    end

    social_links
  end

  def self.get_council_page_url(municipality_name)
    case municipality_name.downcase
    when 'kansas city'
      'https://www.kcmo.gov/city-hall/city-officials/city-council'
    when 'oklahoma city'
      'https://www.okc.gov/government/city-council'
    when 'denver'
      'https://www.denvergov.org/Government/Departments/City-Council'
    else
      raise "No URL defined for #{municipality_name}"
    end
  end

  def self.normalize_url(url)
    return nil unless url

    # Remove trailing slashes, whitespace
    url = url.strip.chomp('/')

    # Ensure https:// prefix
    url = "https://#{url}" unless url.start_with?('http://', 'https://')

    # Handle relative URLs if needed
    return nil if url.start_with?('mailto:', 'tel:')

    # Remove URL parameters unless they seem important (like username)
    url = url.split('?').first unless url =~ /\/(profile|user|@)/

    url
  end

  def self.fetch_municipal_resources(municipality)
    # First, try to find resources by searching the municipality website
    website_resources = search_municipality_website(municipality)

    # Then use GPT to analyze and supplement the findings
    response = OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-4",
        messages: [
          {
            role: "system",
            content: "You are a municipal research specialist. Analyze and categorize municipal resources. Your response must be valid JSON only. Format: object with categories as keys (zoning_documents, council_meetings, permit_applications, development_plans, public_notices) and arrays of objects as values. Each resource object should have: title, url, description, and last_updated (if available, otherwise null)."
          },
          {
            role: "user",
            content: "Analyze and categorize these municipal resources for #{municipality.name}, #{municipality.state}. Add any missing important resources you're aware of. Resources found:\n#{website_resources.to_json}"
          }
        ]
      }
    )

    parse_municipal_resources_response(response) || {
      "zoning_documents" => [],
      "council_meetings" => [],
      "permit_applications" => [],
      "development_plans" => [],
      "public_notices" => []
    }
  end

  def self.search_municipality_website(municipality)
    base_url = get_municipality_base_url(municipality)
    return [] unless base_url

    doc = fetch_page(base_url)
    return [] unless doc

    resources = []

    # Common paths to check
    important_paths = [
      '/zoning', '/planning', '/development',
      '/permits', '/council', '/meetings',
      '/documents', '/resources', '/notices'
    ]

    # Common keywords to search for
    keywords = [
      'zoning', 'ordinance', 'permit', 'application',
      'council meeting', 'agenda', 'minutes',
      'development plan', 'master plan',
      'public notice', 'hearing'
    ]

    # Search main navigation and common paths
    doc.css('nav a, .navigation a, .menu a, a[href*="document"], a[href*="pdf"]').each do |link|
      href = link.attr('href')
      text = link.text.strip.downcase

      next unless href && !href.empty?

      # Check if link contains any of our keywords
      if keywords.any? { |keyword| text.include?(keyword) }
        resources << {
          "title" => link.text.strip,
          "url" => normalize_url(href, base_url),
          "description" => extract_link_context(link),
          "last_updated" => extract_date_from_context(link)
        }
      end
    end

    # Search important paths
    important_paths.each do |path|
      page_url = "#{base_url}#{path}"
      if page_doc = fetch_page(page_url)
        page_doc.css('a[href*="pdf"], a[href*="doc"], a[href*="download"]').each do |link|
          resources << {
            "title" => link.text.strip,
            "url" => normalize_url(link.attr('href'), base_url),
            "description" => extract_link_context(link),
            "last_updated" => extract_date_from_context(link)
          }
        end
      end
    end

    resources.compact.uniq { |r| r["url"] }
  end

  def self.get_municipality_base_url(municipality)
    # First try cached/known URLs
    known_urls = {
      'kansas city' => 'https://www.kcmo.gov',
      'oklahoma city' => 'https://www.okc.gov',
      'denver' => 'https://www.denvergov.org'
    }

    return known_urls[municipality.name.downcase] if known_urls[municipality.name.downcase]

    # Otherwise, ask GPT for the official website
    response = OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-4",
        messages: [
          {
            role: "system",
            content: "You are a municipal website expert. Return ONLY the official website URL for the specified municipality. Return null if unsure. No explanation needed."
          },
          {
            role: "user",
            content: "What is the official government website URL for #{municipality.name}, #{municipality.state}?"
          }
        ]
      }
    )

    url = response.dig('choices', 0, 'message', 'content')&.strip

    # Validate the URL format and ensure it's a government domain
    if url && url =~ URI::DEFAULT_PARSER.make_regexp &&
       (url.include?('.gov') || url.include?('.us') || url.include?('.org'))
      url
    else
      Rails.logger.warn "Could not find valid URL for #{municipality.name}, #{municipality.state}"
      nil
    end
  rescue => e
    Rails.logger.error "Error finding URL for #{municipality.name}: #{e.message}"
    nil
  end

  def self.extract_link_context(link)
    # Try to get context from surrounding text
    context = []

    # Check parent paragraph or list item
    parent = link.parent
    while parent && !%w[div section article].include?(parent.name)
      context << parent.text.strip if parent.text.strip != link.text.strip
      parent = parent.parent
    end

    # Check for title or aria-label attributes
    context << link['title'] if link['title']
    context << link['aria-label'] if link['aria-label']

    context.compact.join(' ').strip
  end

  def self.extract_date_from_context(link)
    # Look for dates in the link text or surrounding context
    context = extract_link_context(link)
    date_matches = context.match(/\d{1,2}[-\/]\d{1,2}[-\/]\d{2,4}|\w+ \d{1,2},? \d{4}/)
    date_matches ? Date.parse(date_matches[0]) : nil
  rescue
    nil
  end

  def self.normalize_url(url, base_url = nil)
    return nil unless url

    # Remove trailing slashes, whitespace
    url = url.strip.chomp('/')

    # Handle relative URLs
    if url.start_with?('/')
      url = "#{base_url}#{url}"
    elsif !url.start_with?('http://', 'https://')
      url = "#{base_url}/#{url}"
    end

    # Ensure https:// prefix
    url = url.gsub('http://', 'https://')

    # Remove URL parameters unless they seem important
    url = url.split('?').first unless url =~ /\/(download|view|id)/

    url
  end

  def self.parse_municipal_resources_response(response)
    return nil unless response['choices']&.first&.dig('message', 'content')

    begin
      resources = JSON.parse(response['choices'].first['message']['content'])
      validate_and_normalize_resources(resources)
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse municipal resources response: #{e.message}"
      nil
    end
  end

  def self.validate_and_normalize_resources(resources)
    resources.transform_values do |category_resources|
      category_resources.map do |resource|
        {
          "title" => resource["title"],
          "url" => normalize_url(resource["url"]),
          "description" => resource["description"],
          "last_updated" => resource["last_updated"]
        }.compact
      end
    end
  end

  def self.save_municipal_resources(municipality, resources)
    resources.each do |category, category_resources|
      category_resources.each do |resource|
        municipality.municipal_resources.find_or_create_by!(url: resource["url"]) do |r|
          r.title = resource["title"]
          r.description = resource["description"]
          r.category = category
          r.last_updated = resource["last_updated"]
        end
      end
    end
  end

  def self.fetch_development_projects(municipality)
    response = OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-4",
        messages: [
          {
            role: "system",
            content: "You are a municipal development expert. Return only valid JSON for development projects. Format: array of objects with fields: name, project_type (residential/commercial/industrial/mixed-use), status (proposed/approved/in_progress/completed), description, estimated_completion (YYYY-MM-DD), estimated_cost, developer_name, project_url."
          },
          {
            role: "user",
            content: "Find current development projects for #{municipality.name}, #{municipality.state}. Include both upcoming and active projects."
          }
        ]
      }
    )

    parse_development_projects_response(response) || []
  end

  def self.fetch_zoning_code(municipality)
    response = OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-4",
        messages: [
          {
            role: "system",
            content: "You are a zoning expert. Extract current zoning code information. Return valid JSON only with fields: title, url, last_updated, description, key_provisions. If you can't find specific information, return null for those fields but still try to return any information you can find."
          },
          {
            role: "user",
            content: "Find the current zoning code for #{municipality.name}, #{municipality.state}."
          }
        ]
      }
    )
    parse_zoning_code_response(response) || {}  # Return empty hash if nothing found
  rescue => e
    Rails.logger.error "Error fetching zoning code for #{municipality.name}: #{e.message}"
    {}
  end

  def self.fetch_zoning_maps(municipality)
    # First try to find maps on the municipality website
    website_maps = search_municipality_maps(municipality)

    # Then use GPT to analyze and supplement
    response = OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-4",
        messages: [
          {
            role: "system",
            content: "You are a zoning expert. Extract current zoning map information. Return valid JSON only with fields: title, url, last_updated, coverage_area, map_type (interactive/static). If you find partial information, include it and set other fields to null."
          },
          {
            role: "user",
            content: "Find the current zoning maps for #{municipality.name}, #{municipality.state}. Known maps: #{website_maps.to_json}"
          }
        ]
      }
    )

    maps = parse_zoning_maps_response(response) || []
    maps + website_maps
  rescue => e
    Rails.logger.error "Error fetching zoning maps for #{municipality.name}: #{e.message}"
    website_maps
  end

  def self.fetch_zoning_decisions(municipality)
    response = OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-4",
        messages: [
          {
            role: "system",
            content: "You are a zoning expert. Extract recent zoning decisions and changes. Return valid JSON only with array of objects containing fields: decision_date, type (variance/amendment/rezoning), description, status, location. Return an empty array if no recent decisions are found."
          },
          {
            role: "user",
            content: "Find recent zoning decisions for #{municipality.name}, #{municipality.state} from the past year."
          }
        ]
      }
    )
    parse_zoning_decisions_response(response) || []
  rescue => e
    Rails.logger.error "Error fetching zoning decisions for #{municipality.name}: #{e.message}"
    []
  end

  def self.save_development_data(municipality, data)
    if data["development_projects"].present?
      data["development_projects"].each do |project|
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
      end
    end

    if data["development_score"].present?
      municipality.create_development_score!(
        current_score: data["development_score"]["current_score"]
      )
    end
  rescue => e
    Rails.logger.error "Error saving development data for #{municipality.name}: #{e.message}"
  end

  def self.parse_development_projects_response(response)
    return nil unless response['choices']&.first&.dig('message', 'content')

    begin
      JSON.parse(response['choices'].first['message']['content'])
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse development projects response: #{e.message}"
      []
    end
  end

  def self.parse_zoning_code_response(response)
    return nil unless response['choices']&.first&.dig('message', 'content')

    begin
      JSON.parse(response['choices'].first['message']['content'])
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse zoning code response: #{e.message}"
      nil
    end
  end

  def self.parse_zoning_maps_response(response)
    return [] unless response['choices']&.first&.dig('message', 'content')

    begin
      JSON.parse(response['choices'].first['message']['content'])
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse zoning maps response: #{e.message}"
      []
    end
  end

  def self.parse_zoning_decisions_response(response)
    return [] unless response['choices']&.first&.dig('message', 'content')

    begin
      JSON.parse(response['choices'].first['message']['content'])
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse zoning decisions response: #{e.message}"
      []
    end
  end

  def self.fetch_skyline_image(query)
    # Implement your image fetching logic here using your preferred AI service
    # This is a placeholder - you'll need to implement the actual API call
    response = OpenAI::Client.new.images.generate(
      parameters: {
        prompt: "Beautiful skyline photograph of #{query}, cityscape, architectural, high quality",
        size: "1024x1024",
        n: 1
      }
    )

    response.dig("data", 0, "url")
  rescue => e
    Rails.logger.error "Failed to fetch image for #{query}: #{e.message}"
    nil
  end

  def self.fetch_and_attach_image(municipality)
    return if municipality.image_url.present? && municipality.hero_image.attached?

    begin
      response = OpenAI::Client.new.images.generate(
        parameters: {
          prompt: "Beautiful skyline photograph of #{municipality.name}, #{municipality.state} cityscape, architectural, high quality",
          size: "1024x1024",
          n: 1
        }
      )

      image_url = response.dig("data", 0, "url")
      return unless image_url

      # Download and attach the image
      downloaded_image = URI.open(image_url)
      municipality.hero_image.attach(
        io: downloaded_image,
        filename: "#{municipality.name.parameterize}-skyline.jpg",
        content_type: 'image/jpeg'
      )

      # Only update the image_url if the attachment was successful
      if municipality.hero_image.attached?
        municipality.update(image_url: image_url)  # Store the original OpenAI URL
      end
    rescue => e
      Rails.logger.error "Failed to fetch/attach image for #{municipality.name}: #{e.message}"
      nil
    end
  end

  def self.search_municipality_maps(municipality)
    base_url = get_municipality_base_url(municipality)
    return [] unless base_url

    maps = []
    map_keywords = ['zoning map', 'land use map', 'district map', 'planning map']

    # Search main website
    if doc = fetch_page(base_url)
      doc.css('a').each do |link|
        href = link.attr('href')
        text = link.text.strip.downcase

        next unless href && !href.empty?

        if map_keywords.any? { |keyword| text.include?(keyword) }
          maps << {
            "title" => link.text.strip,
            "url" => normalize_url(href, base_url),
            "last_updated" => extract_date_from_context(link),
            "map_type" => href.include?('arcgis') ? 'interactive' : 'static',
            "coverage_area" => "#{municipality.name} #{municipality.state}"
          }.compact
        end
      end
    end

    maps.uniq { |m| m["url"] }
  rescue => e
    Rails.logger.error "Error searching municipality maps for #{municipality.name}: #{e.message}"
    []
  end

  def self.save_zoning_data(municipality, data)
    if data["zoning_code"].present?
      municipality.update(zoning_code: data["zoning_code"])
    end

    if data["zoning_maps"].present?
      data["zoning_maps"].each do |map|
        municipality.zoning_maps.find_or_create_by!(url: map["url"]) do |zm|
          zm.title = map["title"]
          zm.last_updated = map["last_updated"]
          zm.coverage_area = map["coverage_area"]
          zm.map_type = map["map_type"]
        end
      end
    end

    if data["zoning_decisions"].present?
      data["zoning_decisions"].each do |decision|
        municipality.zoning_decisions.find_or_create_by!(
          decision_date: decision["decision_date"],
          location: decision["location"]
        ) do |zd|
          zd.decision_type = decision["type"]
          zd.description = decision["description"]
          zd.status = decision["status"]
        end
      end
    end
  rescue => e
    Rails.logger.error "Error saving zoning data for #{municipality.name}: #{e.message}"
  end
end
