class Asset < ApplicationRecord
  KINDS = %w[image video audio document text model_3d archive other].freeze
  STORAGE_PROVIDERS = %w[r2].freeze
  STATUSES = %w[awaiting_upload ready failed deleted].freeze

  belongs_to :uploaded_by_user, class_name: "User"
  has_many :links, class_name: "AssetLink", dependent: :destroy

  validates :asset_kind, inclusion: { in: KINDS }
  validates :mime_type, presence: true
  validates :byte_size, numericality: { greater_than_or_equal_to: 0 }
  validates :storage_provider, inclusion: { in: STORAGE_PROVIDERS }
  validates :storage_key, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :client_id, uniqueness: { scope: :uploaded_by_user_id, allow_blank: true }

  scope :active, -> { where(deleted_at: nil) }
  scope :ready, -> { active.where(status: "ready") }

  def ready!
    update!(status: "ready", revision: revision.to_i + 1)
  end
end
