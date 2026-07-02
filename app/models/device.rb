class Device < ApplicationRecord
  belongs_to :user
  has_many :api_sessions, dependent: :nullify

  validates :client_device_id, :platform, presence: true
  validates :client_device_id, uniqueness: { scope: :user_id }

  scope :active, -> { where(deleted_at: nil) }

  def mark_seen!
    update!(last_seen_at: Time.current)
  end
end
