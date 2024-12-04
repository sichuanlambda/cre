class ZoningController < ApplicationController
  def checker
    if params[:latitude].present? && params[:longitude].present?
      begin
        response = HTTParty.get(
          "https://sandbox-api.zoneomics.com/v2/zoneDetail",
          query: {
            api_key: ENV['ZONEOMICS_API_KEY'],
            lat: params[:latitude],
            lng: params[:longitude]
          }
        )

        Rails.logger.info("Using API Key: #{ENV['ZONEOMICS_API_KEY']}")
        Rails.logger.info("Full URL: #{response.request.last_uri.to_s}")
        Rails.logger.info("Zoneomics API Response: #{response.body}")

        if response.success?
          parsed_response = JSON.parse(response.body)
          if parsed_response["data"] && parsed_response["data"]["zone_details"]
            render json: {
              zoning: parsed_response["data"]["zone_details"]["zone_code"],
              name: parsed_response["data"]["zone_details"]["zone_name"]
            }
          else
            render json: { error: 'No zoning data found' }
          end
        else
          error_message = begin
            JSON.parse(response.body)["message"]
          rescue
            'API request failed'
          end
          render json: { error: error_message }, status: :service_unavailable
        end
      rescue => e
        Rails.logger.error("Zoning API Error: #{e.message}")
        render json: { error: 'Failed to fetch zoning data' }, status: :service_unavailable
      end
    else
      render :checker
    end
  end
end
