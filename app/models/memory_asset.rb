class MemoryAsset < ApplicationRecord
  belongs_to :user
  belongs_to :trip, optional: true
  belongs_to :drive_session, optional: true

  validates :kind, presence: true

  scope :active, -> { where(deleted_at: nil) }
end
