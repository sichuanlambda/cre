class MunicipalitiesController < ApplicationController
  def index
    @municipalities = Municipality.all.order(:name)

    # Get municipalities with development scores
    municipalities_with_scores = Municipality.joins(:development_score)
                                          .select('municipalities.*, development_scores.current_score')
                                          .order('development_scores.current_score DESC')

    # Top municipalities by development score
    @top_municipalities = municipalities_with_scores.first(6)

    # Bottom municipalities by development score
    @bottom_municipalities = municipalities_with_scores.last(6).reverse

    # Map municipalities (those with lat/long coordinates)
    @map_municipalities = Municipality.where.not(latitude: nil, longitude: nil)
  end

  def show
    @municipality = Municipality.find(params[:id])
    @council_members = @municipality.council_members
    @development_score = @municipality.development_score
    @active_projects = @municipality.active_projects
    @upcoming_projects = @municipality.upcoming_projects
    @news_articles = @municipality.news_articles.order(published_at: :desc)
    @rezoning_requests = @municipality.rezoning_requests
    @development_incentives = @municipality.development_incentives
    @impact_fees = @municipality.impact_fees
    @zoning_maps = @municipality.zoning_maps
  end

  def search
    @results = Municipality.search(params[:query])
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to municipalities_path(query: params[:query]) }
    end
  end

  def request_new
    MunicipalityRequest.create(
      name: params[:municipality_name],
      email: params[:email]
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
