class RouteLeg < ApplicationRecord
  belongs_to :route_snapshot
  belongs_to :source_stop, class_name: "TripStop", optional: true
  belongs_to :destination_stop, class_name: "TripStop", optional: true
  has_many :steps, class_name: "RouteStep", dependent: :destroy

  scope :active, -> { where(deleted_at: nil) }
end
