require 'net/http'
require 'uri'

class AnalyzerController < ApplicationController
  def new
  end

  def analyze
    @website = params[:website]
    @website = "https://#{@website}" unless @website.start_with?('http://', 'https://')

    begin
      uri = URI.parse(@website)
      response = Net::HTTP.get_response(uri)

      @analysis = {
        status: response.code,
        content_length: response.body.length,
        title: response.body.match(/<title>(.*?)<\/title>/i)&.captures&.first,
        description: response.body.match(/<meta\s+name="description"\s+content="(.*?)"/i)&.captures&.first
      }
    rescue => e
      @error = "Error analyzing website: #{e.message}"
    end

    respond_to do |format|
      format.turbo_stream
    end
  end
end
