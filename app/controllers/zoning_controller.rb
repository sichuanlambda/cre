class ZoningController < ApplicationController
  def checker
    # If latitude and longitude parameters are present, make the API call
    if params[:latitude].present? && params[:longitude].present?
      begin
        response = HTTParty.get(
          "https://api.zoneomics.com/v2/zoning-point",
          query: {
            lat: params[:latitude],
            lng: params[:longitude]
          },
          headers: {
            'Authorization' => "Bearer #{ENV['ZONEOMICS_API_KEY']}"
          }
        )

        render json: response.body
      rescue => e
        Rails.logger.error("Zoning API Error: #{e.message}")
        render json: { error: 'Failed to fetch zoning data' }, status: :service_unavailable
      end
    else
      # If no parameters, just render the form
      render :checker
    end
  end
end
