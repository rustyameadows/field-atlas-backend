class DeletedRecord < ApplicationRecord
  belongs_to :trip, optional: true
  belongs_to :user, optional: true
  belongs_to :deleted_by_user, class_name: "User", optional: true
  belongs_to :deleted_by_device, class_name: "Device", optional: true

  validates :entity_type, :entity_id, :deleted_at, :reason, presence: true
end
