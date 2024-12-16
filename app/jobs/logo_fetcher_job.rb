class LogoFetcherJob < ApplicationJob
  require 'csv'
  require 'open-uri'
  require 'nokogiri'
  require 'redis'

  queue_as :default

  def perform(urls)
    total = urls.length
    processed = 0
    results = []

    # Use Redis directly instead of Rails cache
    redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1"))

    urls.each do |url|
      begin
        logo_url = fetch_logo(url)
        results << [url, logo_url]
      rescue => e
        results << [url, "NA"]
      ensure
        processed += 1
        status = {
          total: total,
          processed: processed,
          completed: processed == total,
          csv_url: processed == total ? generate_csv(results) : nil
        }.to_json

        Rails.logger.info "Writing to Redis key: logo_fetcher_job_#{job_id}"
        redis.set("logo_fetcher_job_#{job_id}", status)
        Rails.logger.info "Redis value after write: #{redis.get("logo_fetcher_job_#{job_id}")}"
      end
    end
  end

  private

  def generate_csv(results)
    csv_filename = "logos_#{Time.now.to_i}.csv"
    csv_path = Rails.root.join('public', 'downloads', csv_filename)

    Rails.logger.info "Generating CSV at: #{csv_path}"
    FileUtils.mkdir_p(Rails.root.join('public', 'downloads'))

    ::CSV.open(csv_path, 'wb') do |csv|
      Rails.logger.info "Writing CSV headers"
      csv << ['Website URL', 'Logo URL']
      Rails.logger.info "Writing #{results.length} results"
      results.each { |row| csv << row }
    end

    Rails.logger.info "CSV generation complete"
    "/downloads/#{csv_filename}"
  end

  def fetch_logo(url)
    # Clean up the URL if needed
    url = "https://#{url}" unless url.start_with?('http://', 'https://')

    # Fetch and parse the webpage
    doc = Nokogiri::HTML(URI.open(url))

    # Look for logo in common locations
    logo = nil

    # Method 1: Look for meta tags
    logo ||= doc.at_css('meta[property="og:image"]')&.[]('content')
    logo ||= doc.at_css('meta[name="twitter:image"]')&.[]('content')

    # Method 2: Look for common logo class names and IDs
    common_selectors = [
      '.logo img', '#logo img', 'header img[src*=logo]',
      'img[src*=logo]', 'img[alt*=logo]', '.header img',
      '.navbar-brand img', '.brand img'
    ]

    if logo.nil?
      common_selectors.each do |selector|
        found = doc.at_css(selector)
        if found && found['src']
          logo = found['src']
          break
        end
      end
    end

    # Make sure we have an absolute URL
    if logo
      begin
        logo = URI.join(url, logo).to_s
      rescue URI::InvalidURIError
        logo
      end
    end

    logo || 'NA'
  rescue StandardError => e
    'NA'
  end
end
