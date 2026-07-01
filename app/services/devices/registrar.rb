module Devices
  class Registrar
    PERMITTED_FIELDS = %i[name platform app_version build_number push_token push_environment].freeze

    def self.call(user:, attrs:)
      new(user: user, attrs: attrs).call
    end

    def initialize(user:, attrs:)
      @user = user
      @attrs = attrs.to_h.symbolize_keys
    end

    def call
      client_device_id = @attrs[:device_id].presence || @attrs[:client_device_id].presence
      if client_device_id.blank?
        device = Device.new
        device.errors.add(:client_device_id, "is required")
        raise ActiveRecord::RecordInvalid, device
      end

      device = @user.devices.find_or_initialize_by(client_device_id: client_device_id)
      PERMITTED_FIELDS.each do |field|
        device.public_send("#{field}=", @attrs[field]) if @attrs.key?(field)
      end
      device.platform ||= "ios"
      device.last_seen_at = Time.current
      device.revision += 1 if device.persisted? && device.changed?
      device.save!
      device
    end
  end
end
