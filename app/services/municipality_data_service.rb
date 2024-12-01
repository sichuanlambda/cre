class MunicipalityDataService
  def self.generate_data_for_municipality(municipality)
    data = {
      "council_members" => fetch_council_members(municipality),
      "election_cycle" => fetch_election_data(municipality),
      "development_score" => calculate_development_score(municipality),
      "news_articles" => fetch_news_articles(municipality)
    }

    save_news_articles(municipality, data["news_articles"])
    data
  end

  private

  def self.fetch_council_members(municipality)
    case municipality.name.downcase
    when /kansas city/
      doc = fetch_page("https://www.kcmo.gov/city-hall/city-council")
      parse_kc_council_members(doc)
    when /oklahoma city/
      doc = fetch_page("https://www.okc.gov/government/city-council")
      parse_okc_council_members(doc)
    when /denver/
      doc = fetch_page("https://www.denvergov.org/Government/Agencies-Departments-Offices/Agencies-Departments-Offices-Directory/Denver-City-Council")
      parse_denver_council_members(doc)
    else
      search_and_scrape_council_members(municipality)
    end
  end

  def self.parse_kc_council_members(doc)
    return [] unless doc

    doc.css('.council-member, .elected-official').map do |member|
      {
        "name" => member.css('h3, .name').text.strip,
        "position" => member.css('.title, .position').text.strip,
        "social_links" => extract_social_links(member),
        "first_term_start_year" => 2020, # Default for now, enhance with actual scraping
        "terms_served" => 1 # Default for now, enhance with actual scraping
      }
    end
  end

  def self.fetch_election_data(municipality)
    case municipality.name.downcase
    when /kansas city/
      {
        "next_election_date" => Date.new(2024, 4, 2),
        "last_election_date" => Date.new(2020, 4, 7),
        "cycle_years" => 4,
        "name" => "#{municipality.name} Municipal Elections"
      }
    when /oklahoma city/
      {
        "next_election_date" => Date.new(2024, 2, 13),
        "last_election_date" => Date.new(2020, 2, 11),
        "cycle_years" => 4,
        "name" => "#{municipality.name} Municipal Elections"
      }
    when /denver/
      {
        "next_election_date" => Date.new(2024, 4, 2),
        "last_election_date" => Date.new(2020, 4, 7),
        "cycle_years" => 4,
        "name" => "#{municipality.name} Municipal Elections"
      }
    else
      search_and_scrape_election_data(municipality)
    end
  end

  def self.fetch_news_articles(municipality)
    return [] unless ENV['NEWS_API_KEY']

    news_api = News.new(ENV['NEWS_API_KEY'])
    articles = news_api.get_everything(
      q: "#{municipality.name} city council OR mayor OR municipal",
      language: 'en',
      sortBy: 'publishedAt',
      pageSize: 10
    )

    articles.map do |article|
      {
        title: article.title,
        description: article.description,
        url: article.url,
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
        article.published_at = article_data[:published_at]
      end
    end
  end

  def self.calculate_development_score(municipality)
    # Implement actual scoring logic based on various factors
    { "current_score" => rand(60..95) }
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
end
