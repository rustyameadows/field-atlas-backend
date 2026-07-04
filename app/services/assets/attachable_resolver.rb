module Assets
  class AttachableResolver
    SUPPORTED_TYPES = %w[Trip TripStop PlaceList PlaceListItem FavoritePlace Place DriveSession].freeze

    def self.trip_for_link(link)
      new(user: nil).trip_for(link)
    end

    def initialize(user:)
      @user = user
    end

    def writable?(attachable_type:, attachable_id:, attachable_ref: {})
      return false if @user.blank?

      record = resolve(attachable_type, attachable_id, attachable_ref)
      return false if record.blank? && attachable_type != "Place"

      case attachable_type
      when "Trip"
        record.editable_by?(@user)
      when "TripStop"
        record.trip.editable_by?(@user)
      when "PlaceList"
        record.user_id == @user.id
      when "PlaceListItem"
        record.place_list.user_id == @user.id
      when "FavoritePlace"
        record.user_id == @user.id
      when "Place"
        true
      when "DriveSession"
        record.user_id == @user.id
      else
        false
      end
    end

    def readable_link?(link)
      return false if @user.blank? || link.deleted_at.present?

      record = resolve(link.attachable_type, link.attachable_id, link.attachable_ref)
      return false if record.blank? && link.attachable_type != "Place"

      case link.attachable_type
      when "Trip"
        record.readable_by?(@user)
      when "TripStop"
        record.trip.readable_by?(@user)
      when "PlaceList"
        record.user_id == @user.id
      when "PlaceListItem"
        record.place_list.user_id == @user.id
      when "FavoritePlace"
        record.user_id == @user.id
      when "Place"
        link.created_by_user_id == @user.id || link.asset.uploaded_by_user_id == @user.id
      when "DriveSession"
        record.user_id == @user.id
      else
        false
      end
    end

    def writable_link?(link)
      return false if @user.blank? || link.deleted_at.present?
      return true if link.created_by_user_id == @user.id
      return false if link.attachable_type == "Place"

      writable?(
        attachable_type: link.attachable_type,
        attachable_id: link.attachable_id,
        attachable_ref: link.attachable_ref
      )
    end

    def visible_asset?(asset)
      return false if @user.blank? || asset.deleted_at.present?
      return true if asset.uploaded_by_user_id == @user.id

      asset.links.active.includes(:asset).any? { |link| readable_link?(link) }
    end

    def trip_for(link)
      record = resolve(link.attachable_type, link.attachable_id, link.attachable_ref)
      case record
      when Trip
        record
      when TripStop
        record.trip
      when DriveSession
        record.trip
      end
    end

    def owner_user_for(link)
      record = resolve(link.attachable_type, link.attachable_id, link.attachable_ref)
      case record
      when PlaceList
        record.user
      when PlaceListItem
        record.place_list.user
      when FavoritePlace, DriveSession
        record.user
      else
        link.created_by_user
      end
    end

    def resolve(attachable_type, attachable_id, attachable_ref = {})
      return unless SUPPORTED_TYPES.include?(attachable_type)
      return if attachable_id.blank? && attachable_type != "Place"

      attachable_type.constantize.find_by(id: attachable_id)
    rescue NameError
      nil
    end
  end
end
