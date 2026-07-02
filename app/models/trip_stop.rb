class TripStop < ApplicationRecord
  KINDS = %w[idea route_stop waypoint possible_stop note].freeze
  KIND_ALIASES = {
    "open_idea" => "idea",
    "route_waypoint" => "waypoint"
  }.freeze

  belongs_to :trip
  belongs_to :segment, class_name: "TripSegment", foreign_key: :trip_segment_id, optional: true
  belongs_to :created_by_user, class_name: "User", optional: true
  belongs_to :created_by_device, class_name: "Device", optional: true
  belongs_to :canonical_place, class_name: "Place", optional: true

  has_many :parent_option_links, class_name: "TripStopOptionLink", foreign_key: :parent_stop_id, dependent: :destroy
  has_many :candidate_option_links, class_name: "TripStopOptionLink", foreign_key: :candidate_stop_id, dependent: :destroy

  validates :kind, inclusion: { in: KINDS }
  validates :title, presence: true

  before_validation :normalize_kind!

  scope :active, -> { where(deleted_at: nil) }

  def self.normalize_kind(value)
    normalized = value.to_s
    KIND_ALIASES.fetch(normalized, normalized)
  end

  private

  def normalize_kind!
    self.kind = self.class.normalize_kind(kind)
  end
end
