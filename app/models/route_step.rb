class RouteStep < ApplicationRecord
  belongs_to :route_leg

  validates :instructions, presence: true

  scope :active, -> { where(deleted_at: nil) }
end
