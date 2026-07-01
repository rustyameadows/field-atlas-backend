class PlaceList < ApplicationRecord
  belongs_to :user
  has_many :items, class_name: "PlaceListItem", dependent: :destroy

  validates :name, presence: true

  scope :active, -> { where(deleted_at: nil) }
end
