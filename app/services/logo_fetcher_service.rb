require 'open-uri'
require 'nokogiri'
require 'httparty'

class LogoFetcherService
  def self.fetch_and_upload(website_url)
    new(website_url).fetch_and_upload
  end

  def initialize(website_url)
    @website_url = ensure_valid_url(website_url)
    Rails.logger.info "Initialized LogoFetcherService with URL: #{@website_url}"
  end

  def fetch_and_upload
    Rails.logger.info "Starting fetch process"
    logo_url = find_logo_url
    Rails.logger.info "Found logo URL: #{logo_url}"

    if logo_url
      { status: 'success', logo_url: logo_url }
    else
      { status: 'error', message: 'Could not find logo' }
    end
  rescue StandardError => e
    Rails.logger.error "Error in fetch_and_upload: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    { status: 'error', message: e.message }
  end

  private

  def ensure_valid_url(url)
    return url if url.start_with?('http://', 'https://')
    "https://#{url}"
  end

  def find_logo_url
    Rails.logger.info "Fetching HTML from #{@website_url}"
    doc = Nokogiri::HTML(URI.open(@website_url))
    Rails.logger.info "Successfully fetched HTML"

    # Common logo selectors
    selectors = [
      'link[rel*="icon"][href*=".png"]',
      'link[rel*="icon"][href*=".jpg"]',
      'link[rel*="apple-touch-icon"]',
      'link[rel*="logo"]',
      'meta[property="og:image"]',
      'meta[name="twitter:image"]',
      'img[src*="logo"]',
      'img[alt*="logo"]',
      'img[class*="logo"]'
    ]

    Rails.logger.info "Searching for logo using selectors"
    potential_logos = doc.css(selectors.join(', '))
    Rails.logger.info "Found #{potential_logos.length} potential logos"

    highest_quality_logo = nil
    highest_quality_score = 0

    potential_logos.each do |element|
      url = element['href'] || element['content'] || element['src']
      next unless url

      begin
        absolute_url = URI.join(@website_url, url).to_s
        Rails.logger.info "Checking potential logo URL: #{absolute_url}"

        quality_score = assess_logo_quality(absolute_url)
        if quality_score > highest_quality_score
          highest_quality_score = quality_score
          highest_quality_logo = absolute_url
          Rails.logger.info "New highest quality logo found: #{absolute_url} (score: #{quality_score})"
        end
      rescue URI::InvalidURIError => e
        Rails.logger.warn "Invalid URL found: #{url} - #{e.message}"
        next
      end
    end

    highest_quality_logo
  end

  def assess_logo_quality(url)
    score = 0
    score += 5 if url.match?(/logo/i)
    score += 3 if url.match?(/\.(png|svg)$/i)
    score += 2 if url.match?(/\.(jpg|jpeg)$/i)
    score += 1 if url.match?(/icon/i)
    score
  end
end
