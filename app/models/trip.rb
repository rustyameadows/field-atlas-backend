class Trip < ApplicationRecord
  belongs_to :owner_user, class_name: "User"
  belongs_to :created_by_device, class_name: "Device", optional: true

  has_many :members, class_name: "TripMember", dependent: :destroy
  has_many :invites, class_name: "TripInvite", dependent: :destroy
  has_many :segments, class_name: "TripSegment", dependent: :destroy
  has_many :stops, class_name: "TripStop", dependent: :destroy
  has_many :option_links, class_name: "TripStopOptionLink", dependent: :destroy
  has_many :route_snapshots, dependent: :destroy

  validates :title, presence: true

  scope :active, -> { where(deleted_at: nil) }

  def active_member_for(user)
    return if user.blank?

    members.active.find_by(user: user)
  end

  def owned_by?(user)
    user.present? && owner_user_id == user.id && deleted_at.nil?
  end

  def readable_by?(user)
    owned_by?(user) || active_member_for(user).present?
  end

  def editable_by?(user)
    owned_by?(user) || active_member_for(user)&.editor_or_owner?
  end

  def manageable_by?(user)
    owned_by?(user) || active_member_for(user)&.owner?
  end
end
