class LogoFetcherController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:fetch] # For testing only - remove in production

  def new
    # Just renders the form
  end

  def fetch
    Rails.logger.info "Received parameters: #{params.inspect}"
    website_url = params[:website_url] || params.dig(:logo_fetcher, :website_url)
    Rails.logger.info "Processing website_url: #{website_url}"

    if website_url.present?
      result = LogoFetcherService.fetch_and_upload(website_url)
      render json: result
    else
      render json: {
        status: 'error',
        message: 'Website URL is required'
      }, status: :unprocessable_entity
    end
  end
end
