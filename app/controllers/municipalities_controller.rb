class MunicipalitiesController < ApplicationController
  def index
    @municipalities = Municipality.includes(:council_members, :development_score, :news_articles)
                                  .search(params[:query])
  end

  def show
    @municipality = Municipality.includes(:council_members, :development_score, :news_articles)
                                .find(params[:id])
  end

  def search
    @results = Municipality.search(params[:query])
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to municipalities_path(query: params[:query]) }
    end
  end

  def request_new
    # For now, just save to MunicipalityRequest model
    MunicipalityRequest.create(
      name: params[:municipality_name]
    )

    redirect_to root_path, notice: 'Thank you for your request. We will review it shortly.'
  end

  def subscribe
    # For now, just save to Subscription model
    Subscription.create(
      email: params[:email]
    )

    redirect_to root_path, notice: 'Thank you for subscribing to municipality updates.'
  end
end
