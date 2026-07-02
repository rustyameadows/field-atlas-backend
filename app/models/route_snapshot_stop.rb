class RouteSnapshotStop < ApplicationRecord
  belongs_to :route_snapshot
  belongs_to :trip_stop, optional: true

  validates :kind, :title, presence: true

  scope :active, -> { where(deleted_at: nil) }
end
