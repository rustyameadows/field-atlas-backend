class SearchSession < ApplicationRecord
  belongs_to :user
  belongs_to :search_history_entry, optional: true
  has_many :result_snapshots, as: :owner, class_name: "SearchResultSnapshot", dependent: :destroy

  validates :query, presence: true

  scope :active, -> { where(deleted_at: nil) }
end
