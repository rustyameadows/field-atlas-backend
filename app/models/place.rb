class Place < ApplicationRecord
  KINDS = %w[park_unit trailhead campground route poi scenic_point].freeze
  STATUSES = %w[draft published hidden duplicate].freeze

  has_many :place_source_links, dependent: :destroy
  has_many :source_records, through: :place_source_links
  has_many :external_identifiers, class_name: "PlaceExternalIdentifier", dependent: :destroy
  has_many :place_containments, foreign_key: :containing_place_id, dependent: :destroy, inverse_of: :containing_place
  has_many :contained_source_records, through: :place_containments, source: :source_record
  has_one :park_unit, dependent: :destroy

  validates :name, :slug, :kind, :status, presence: true
  validates :slug, uniqueness: true
  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }

  def source_ids_by_provider
    source_ids = Hash.new { |hash, key| hash[key] = [] }

    external_identifiers.active.order(:provider, :id).each do |external_identifier|
      source_ids[external_identifier.provider] << external_identifier.identifier
    end

    place_source_links.where.not(review_status: "rejected").includes(:source_record).order(:id).each do |link|
      source_record = link.source_record
      source_ids[source_record.provider] << source_record.source_id
    end

    source_ids.transform_values { |identifiers| identifiers.uniq }
  end
end
