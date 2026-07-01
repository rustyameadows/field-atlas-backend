class TripStopOptionLink < ApplicationRecord
  belongs_to :trip
  belongs_to :parent_stop, class_name: "TripStop"
  belongs_to :candidate_stop, class_name: "TripStop"

  validates :group_id, presence: true
  validate :stops_belong_to_trip

  scope :active, -> { where(deleted_at: nil) }

  private

  def stops_belong_to_trip
    return if trip.blank? || parent_stop.blank? || candidate_stop.blank?

    errors.add(:parent_stop, "must belong to trip") if parent_stop.trip_id != trip_id
    errors.add(:candidate_stop, "must belong to trip") if candidate_stop.trip_id != trip_id
  end
end
