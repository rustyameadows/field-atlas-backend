class UserSetting < ApplicationRecord
  belongs_to :user

  validates :key, presence: true, uniqueness: { scope: :user_id }

  scope :active, -> { where(deleted_at: nil) }
end
