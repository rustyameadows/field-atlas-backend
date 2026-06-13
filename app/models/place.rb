class Place < ApplicationRecord
  KINDS = %w[park_unit trailhead campground route poi scenic_point].freeze
  STATUSES = %w[draft published hidden duplicate].freeze

  has_many :place_source_links, dependent: :destroy
  has_many :source_records, through: :place_source_links
  has_many :place_containments, foreign_key: :containing_place_id, dependent: :destroy, inverse_of: :containing_place
  has_many :contained_source_records, through: :place_containments, source: :source_record
  has_one :park_unit, dependent: :destroy

  validates :name, :slug, :kind, :status, presence: true
  validates :slug, uniqueness: true
  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }
end
