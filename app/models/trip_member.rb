class TripMember < ApplicationRecord
  ROLES = %w[owner editor viewer].freeze
  STATUSES = %w[active removed].freeze

  belongs_to :trip
  belongs_to :user

  validates :role, inclusion: { in: ROLES }
  validates :status, inclusion: { in: STATUSES }
  validates :user_id, uniqueness: { scope: :trip_id }

  before_validation :set_defaults

  scope :active, -> { where(status: "active", deleted_at: nil) }

  def owner?
    role == "owner" && active?
  end

  def editor_or_owner?
    active? && (role == "owner" || role == "editor")
  end

  def active?
    status == "active" && deleted_at.nil?
  end

  def remove!
    update!(status: "removed", deleted_at: Time.current, revision: revision + 1)
  end

  private

  def set_defaults
    self.status ||= "active"
    self.role ||= "viewer"
    self.joined_at ||= Time.current
  end
end
