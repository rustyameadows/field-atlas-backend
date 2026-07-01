class User < ApplicationRecord
  STATUSES = %w[active disabled deleted].freeze

  has_many :auth_identities, class_name: "UserAuthIdentity", dependent: :destroy
  has_many :api_sessions, dependent: :destroy
  has_many :devices, dependent: :destroy
  has_many :trip_members, dependent: :destroy
  has_many :member_trips, through: :trip_members, source: :trip
  has_many :owned_trips, class_name: "Trip", foreign_key: :owner_user_id, dependent: :restrict_with_exception

  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active", deleted_at: nil) }

  def active?
    status == "active" && deleted_at.nil?
  end
end
