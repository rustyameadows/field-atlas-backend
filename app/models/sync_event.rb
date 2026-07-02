class SyncEvent < ApplicationRecord
  belongs_to :trip, optional: true
  belongs_to :user, optional: true
  belongs_to :actor_user, class_name: "User", optional: true
  belongs_to :actor_device, class_name: "Device", optional: true

  validates :entity_type, :entity_id, :action, :record_revision, :occurred_at, presence: true
end
