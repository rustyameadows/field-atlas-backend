class PlaceSourceLink < ApplicationRecord
  MATCH_TYPES = %w[source_id manual name_geometry provider_crosswalk].freeze
  REVIEW_STATUSES = %w[auto verified rejected].freeze

  belongs_to :place
  belongs_to :source_record

  validates :match_type, :review_status, presence: true
  validates :match_type, inclusion: { in: MATCH_TYPES }
  validates :review_status, inclusion: { in: REVIEW_STATUSES }
  validates :confidence, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
  validates :source_record_id, uniqueness: { scope: :place_id }
end
