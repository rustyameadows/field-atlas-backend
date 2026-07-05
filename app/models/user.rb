class User < ApplicationRecord
  STATUSES = %w[active disabled deleted].freeze

  belongs_to :profile_photo_asset, class_name: "Asset", optional: true

  has_many :auth_identities, class_name: "UserAuthIdentity", dependent: :destroy
  has_many :api_sessions, dependent: :destroy
  has_many :devices, dependent: :destroy
  has_many :trip_members, dependent: :destroy
  has_many :member_trips, through: :trip_members, source: :trip
  has_many :owned_trips, class_name: "Trip", foreign_key: :owner_user_id, dependent: :restrict_with_exception

  before_validation :normalize_blank_profile_fields

  validates :status, inclusion: { in: STATUSES }
  validates :display_name, length: { maximum: 120 }, allow_nil: true
  validates :username, length: { maximum: 64 }, uniqueness: { case_sensitive: false }, allow_nil: true
  validates :bio, length: { maximum: 1_000 }, allow_nil: true
  validate :profile_photo_asset_is_ready_owned_image

  scope :active, -> { where(status: "active", deleted_at: nil) }

  def active?
    status == "active" && deleted_at.nil?
  end

  private

  def normalize_blank_profile_fields
    self.username = nil if username.blank?
    self.bio = nil if bio.blank?
    self.profile_photo_asset_id = nil if profile_photo_asset_id.blank?
  end

  def profile_photo_asset_is_ready_owned_image
    return if profile_photo_asset_id.blank?

    if profile_photo_asset.blank? ||
        profile_photo_asset.uploaded_by_user_id != id ||
        profile_photo_asset.asset_kind != "image" ||
        profile_photo_asset.status != "ready" ||
        profile_photo_asset.deleted_at.present?
      errors.add(:profile_photo_asset, "must be a ready image uploaded by the user")
    end
  end
end
