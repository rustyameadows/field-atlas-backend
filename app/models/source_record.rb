class SourceRecord < ApplicationRecord
  belongs_to :source_dataset
  has_many :place_source_links, dependent: :destroy
  has_many :places, through: :place_source_links

  before_validation :set_normalized_name
  before_validation :set_payload_hash

  validates :provider, :record_type, :source_id, :name, :normalized_name, :payload_hash, :fetched_at, presence: true
  validates :source_id, uniqueness: { scope: [ :provider, :record_type ] }

  scope :for_sources, ->(providers) { where(provider: providers) if providers.present? }
  scope :with_query, ->(query) {
    if query.blank?
      all
    else
      normalized = normalize_name(query)
      where("normalized_name LIKE ?", "%#{sanitize_sql_like(normalized)}%")
    end
  }

  def to_search_result(freshness: "stored")
    coordinate = normalized_payload.fetch("coordinate", {})
    canonical_id = canonical_place_id
    {
      id: "source:#{provider}:#{record_type}:#{source_id}",
      result_type: "source_record",
      canonical_place_id: canonical_id,
      source: provider,
      source_id: source_id,
      name: name,
      subtitle: normalized_payload["subtitle"],
      category: normalized_payload["category"],
      geometry_type: coordinate.present? ? "point" : nil,
      coordinate: coordinate.presence,
      source_freshness: {
        mode: freshness,
        fetched_at: fetched_at&.iso8601
      }
    }.compact
  end

  def coordinate
    value = normalized_payload.fetch("coordinate", nil)
    return if value.blank?

    {
      lat: value.fetch("lat").to_f,
      lng: value.fetch("lng").to_f
    }
  end

  def inside_bbox?(bbox)
    return true if bbox.blank?

    point = coordinate
    return false if point.blank?

    min_lng, min_lat, max_lng, max_lat = bbox
    point[:lng].between?(min_lng, max_lng) && point[:lat].between?(min_lat, max_lat)
  end

  def inside_radius?(center, radius_meters)
    return true if center.blank? || radius_meters.blank?

    point = coordinate
    return false if point.blank?

    Places::Geo.distance_meters(point[:lat], point[:lng], center.fetch(:lat), center.fetch(:lng)) <= radius_meters
  end

  def self.normalize_name(value)
    value.to_s.downcase.squish
  end

  private

  def canonical_place_id
    place_source_links.where.not(review_status: "rejected").order(confidence: :desc).pick(:place_id)
  end

  def set_normalized_name
    self.normalized_name = self.class.normalize_name(name)
  end

  def set_payload_hash
    self.payload_hash = Digest::SHA256.hexdigest(::JSON.generate(raw_payload || {}))
  end
end
