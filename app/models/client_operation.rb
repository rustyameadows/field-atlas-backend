class ClientOperation < ApplicationRecord
  belongs_to :device
  belongs_to :user

  validates :operation_id, :entity_type, :entity_id, :action, :received_at, presence: true
  validates :operation_id, uniqueness: { scope: :device_id }
end
