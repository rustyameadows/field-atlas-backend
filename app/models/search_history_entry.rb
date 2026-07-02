class SearchHistoryEntry < ApplicationRecord
  belongs_to :user
  has_many :search_sessions, dependent: :nullify

  validates :query, presence: true

  scope :active, -> { where(deleted_at: nil) }
end
