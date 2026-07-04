class AssetLink < ApplicationRecord
  ROLES = %w[cover cover_loop gallery attachment thumbnail annotation source other].freeze

  belongs_to :asset
  belongs_to :created_by_user, class_name: "User"

  validates :attachable_type, presence: true
  validates :role, inclusion: { in: ROLES }
  validates :sort_order, numericality: true
  validate :attachable_identifier_present

  scope :active, -> { where(deleted_at: nil) }

  def attachable_identifier
    attachable_id.presence || attachable_ref.presence
  end

  private

  def attachable_identifier_present
    return if attachable_id.present? || attachable_ref.present?

    errors.add(:base, "attachable_id or attachable_ref is required")
  end
end
