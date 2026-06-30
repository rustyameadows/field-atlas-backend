class SourceDataset < ApplicationRecord
  FRESHNESS_MODES = %w[live_query cached_query scheduled_import].freeze
  STATUSES = %w[active disabled failed].freeze

  has_many :source_records, dependent: :destroy

  validates :provider, :name, :freshness_mode, :status, presence: true
  validates :freshness_mode, inclusion: { in: FRESHNESS_MODES }
  validates :status, inclusion: { in: STATUSES }
  validates :name, uniqueness: { scope: :provider }
end
