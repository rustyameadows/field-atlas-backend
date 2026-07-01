class RouteSnapshot < ApplicationRecord
  belongs_to :trip
  belongs_to :trip_segment, optional: true
  belongs_to :created_by_user, class_name: "User", optional: true
  belongs_to :created_by_device, class_name: "Device", optional: true

  has_many :snapshot_stops, class_name: "RouteSnapshotStop", dependent: :destroy
  has_many :legs, class_name: "RouteLeg", dependent: :destroy

  validates :provider, presence: true

  scope :active, -> { where(deleted_at: nil) }
end
