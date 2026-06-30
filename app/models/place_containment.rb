class PlaceContainment < ApplicationRecord
  RELATIONSHIP_TYPES = %w[contains].freeze
  REVIEW_STATUSES = %w[auto verified rejected].freeze

  belongs_to :containing_place, class_name: "Place"
  belongs_to :source_record

  validates :relationship_type, :review_status, presence: true
  validates :relationship_type, inclusion: { in: RELATIONSHIP_TYPES }
  validates :review_status, inclusion: { in: REVIEW_STATUSES }
  validates :confidence, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
  validates :source_record_id, uniqueness: { scope: :containing_place_id }
end
