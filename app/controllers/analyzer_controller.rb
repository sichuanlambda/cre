class AnalyzerController < ApplicationController
  def new
  end

  def analyze
    @website = params[:website]

    service = OpenAiService.new(@website)
    @result = service.analyze

    render :new
  end
end
