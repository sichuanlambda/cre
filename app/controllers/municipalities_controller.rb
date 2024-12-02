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
end
