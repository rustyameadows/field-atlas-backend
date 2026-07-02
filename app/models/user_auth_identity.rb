class UserAuthIdentity < ApplicationRecord
  PROVIDERS = %w[apple].freeze

  belongs_to :user

  validates :provider, inclusion: { in: PROVIDERS }
  validates :provider_subject, presence: true, uniqueness: { scope: :provider }
end
