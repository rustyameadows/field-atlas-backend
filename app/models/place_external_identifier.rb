class PlaceExternalIdentifier < ApplicationRecord
  IDENTIFIER_KINDS = %w[primary alternate synthetic].freeze
  REVIEW_STATUSES = %w[verified auto needs_review rejected].freeze
  ACTIVE_REVIEW_STATUSES = %w[verified auto].freeze

  belongs_to :place

  before_validation :normalize_values

  validates :provider, :identifier, :identifier_kind, :review_status, presence: true
  validates :identifier_kind, inclusion: { in: IDENTIFIER_KINDS }
  validates :review_status, inclusion: { in: REVIEW_STATUSES }
  validates :identifier, uniqueness: { scope: :provider }

  scope :active, -> { where(review_status: ACTIVE_REVIEW_STATUSES) }

  private

  def normalize_values
    self.provider = provider.to_s.strip.downcase
    self.identifier = identifier.to_s.strip
    self.identifier_kind = identifier_kind.presence || "primary"
    self.review_status = review_status.presence || "verified"
  end
end
