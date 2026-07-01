class SearchResultSnapshot < ApplicationRecord
  belongs_to :owner, polymorphic: true

  validates :place_id, presence: true

  scope :active, -> { where(deleted_at: nil) }
end
