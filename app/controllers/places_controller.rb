class PlacesController < ApplicationController
  def index
    @query = params[:q].to_s
    @within = params[:within].to_s
    @within_place_id = params[:within_place_id].to_s
    @sources = params[:sources].presence || "field_atlas,nps"
    @types = params[:types].presence || "park_unit,nps_place,campground,visitor_center,parking_lot"
    @limit = params[:limit].presence || Places::Search::DEFAULT_LIMIT
    @search_params = dashboard_search_params
    @search_response = Places::Search.new(@search_params).call
    @api_url = api_v1_search_path(@search_params)
    @place_count = Place.count
    @source_record_count = SourceRecord.count
    @canonical_places = Place.includes(:external_identifiers, place_source_links: :source_record).order(:name).limit(100)
    @latest_source_records = SourceRecord.order(fetched_at: :desc, updated_at: :desc).limit(25)
  end

  private

  def dashboard_search_params
    {
      q: @query.presence,
      within: @within.presence,
      within_place_id: @within_place_id.presence,
      sources: @sources,
      types: @types,
      limit: @limit
    }.compact
  end
end
