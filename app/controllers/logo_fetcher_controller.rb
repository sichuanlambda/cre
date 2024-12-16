class LogoFetcherController < ApplicationController
  require 'open-uri'
  require 'nokogiri'
  require 'csv'
  require 'redis'

  def new
  end

  def bulk_process
    urls = params[:urls]
    return render json: { error: 'No URLs provided' }, status: :unprocessable_entity if urls.blank?

    job = LogoFetcherJob.perform_later(urls)
    render json: { job_id: job.job_id }
  end

  def job_status
    job_id = params[:id]
    redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1"))
    status = redis.get("logo_fetcher_job_#{job_id}")

    if status
      render json: JSON.parse(status)
    else
      render json: {
        processed: 0,
        total: 0,
        completed: false,
        csv_url: nil
      }
    end
  end

  private

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
