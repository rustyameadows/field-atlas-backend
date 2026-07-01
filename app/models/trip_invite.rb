class TripInvite < ApplicationRecord
  ROLES = %w[editor viewer].freeze
  STATUSES = %w[pending accepted revoked expired].freeze

  belongs_to :trip
  belongs_to :invited_by_user, class_name: "User"
  belongs_to :accepted_by_user, class_name: "User", optional: true

  validates :token, presence: true, uniqueness: true
  validates :role, inclusion: { in: ROLES }
  validates :status, inclusion: { in: STATUSES }

  before_validation :set_defaults

  def pending?
    status == "pending" && deleted_at.nil? && (expires_at.blank? || expires_at.future?)
  end

  def accept!(user)
    update!(accepted_by_user: user, accepted_at: Time.current, status: "accepted", revision: revision + 1)
  end

  private

  def set_defaults
    self.token ||= SecureRandom.urlsafe_base64(24)
    self.status ||= "pending"
    self.role ||= "editor"
  end
end
