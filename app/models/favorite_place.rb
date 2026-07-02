class FavoritePlace < ApplicationRecord
  belongs_to :user

  validates :place_id, presence: true

  scope :active, -> { where(deleted_at: nil) }
end
