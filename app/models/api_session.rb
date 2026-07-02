class ApiSession < ApplicationRecord
  belongs_to :user
  belongs_to :device, optional: true

  validates :access_token_digest, :refresh_token_digest, :expires_at, :refresh_expires_at, presence: true
  validates :access_token_digest, :refresh_token_digest, uniqueness: true

  scope :not_revoked, -> { where(revoked_at: nil) }

  def access_active?
    revoked_at.nil? && expires_at.future?
  end

  def refresh_active?
    revoked_at.nil? && refresh_expires_at.future?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end
end
