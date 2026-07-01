class DriveSession < ApplicationRecord
  belongs_to :user
  belongs_to :trip, optional: true
  belongs_to :route_snapshot, optional: true
  has_many :memory_assets, dependent: :nullify

  scope :active, -> { where(deleted_at: nil) }
end
