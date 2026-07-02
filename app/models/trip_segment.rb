class TripSegment < ApplicationRecord
  belongs_to :trip
  belongs_to :parent_segment, class_name: "TripSegment", optional: true
  has_many :stops, class_name: "TripStop", dependent: :nullify
  has_many :route_snapshots, dependent: :nullify

  validates :title, presence: true

  scope :active, -> { where(deleted_at: nil) }
end
