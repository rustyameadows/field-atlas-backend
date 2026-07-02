class PlaceListItem < ApplicationRecord
  belongs_to :place_list

  validates :place_id, presence: true

  scope :active, -> { where(deleted_at: nil) }
end
