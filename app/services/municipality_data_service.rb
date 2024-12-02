class MunicipalityDataService
  def self.generate_data_for_municipality(municipality)
    data = {
      "council_members" => fetch_council_members(municipality),
      "reelection_dates" => fetch_reelection_dates(municipality),
      "development_score" => calculate_development_score(municipality),
      "news_articles" => fetch_news_articles(municipality)
    }

    save_news_articles(municipality, data["news_articles"])
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
    rescue JSON::ParseError => e
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
      q: "(development OR rezone OR \"public opposition\") AND (#{municipality.name}) AND (mayor OR \"city council\" OR municipal)",
      language: 'en',
      sortBy: 'publishedAt',
      pageSize: 5
    )

    articles.map do |article|
      {
        title: article.title,
        url: article.url
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
    {
      "twitter" => member_element.css('a[href*="twitter"]').first&.attr('href'),
      "linkedin" => member_element.css('a[href*="linkedin"]').first&.attr('href')
    }
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
end
