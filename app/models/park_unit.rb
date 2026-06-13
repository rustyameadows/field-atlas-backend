class ParkUnit < ApplicationRecord
  belongs_to :place

  validates :agency, presence: true
  validates :place_id, uniqueness: true
end
