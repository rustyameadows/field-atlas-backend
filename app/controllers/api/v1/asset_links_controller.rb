module Api
  module V1
    class AssetLinksController < BaseController
      before_action :authenticate_api_session!

      rescue_from ActiveRecord::RecordInvalid do |error|
        render_error("validation_failed", error.record.errors.full_messages.to_sentence, status: :unprocessable_entity)
      end

      def create
        asset = Asset.active.find(params[:asset_id])
        raise ForbiddenError, "Only the uploader can attach this asset." unless asset.uploaded_by_user_id == current_user.id

        link = nil
        ActiveRecord::Base.transaction do
          link = create_link!(asset, link_payload)
        end

        render json: { asset_link: Serializers.asset_link(link) }, status: :created
      end

      def update
        link = AssetLink.active.find(params[:id])
        resolver = ::Assets::AttachableResolver.new(user: current_user)
        raise ForbiddenError, "You do not have permission to update this asset link." unless resolver.writable_link?(link)

        payload = link_update_payload
        link.assign_attributes(payload)
        if link.changed?
          link.revision = link.revision.to_i + 1
          link.save!
          record_link_event!(link, "updated")
        end

        render json: { asset_link: Serializers.asset_link(link) }
      end

      def destroy
        link = AssetLink.active.find(params[:id])
        resolver = ::Assets::AttachableResolver.new(user: current_user)
        raise ForbiddenError, "You do not have permission to delete this asset link." unless resolver.writable_link?(link)

        soft_delete_link!(link)
        render json: { asset_link: Serializers.asset_link(link) }
      end

      private

      def create_link!(asset, payload)
        resolver = ::Assets::AttachableResolver.new(user: current_user)
        unless resolver.writable?(
          attachable_type: payload.fetch(:attachable_type),
          attachable_id: payload[:attachable_id],
          attachable_ref: payload[:attachable_ref] || {}
        )
          raise ForbiddenError, "You do not have permission to attach assets to this object."
        end

        link = AssetLink.create!(
          asset: asset,
          created_by_user: current_user,
          attachable_type: payload.fetch(:attachable_type),
          attachable_id: payload[:attachable_id],
          attachable_ref: payload[:attachable_ref] || {},
          role: payload[:role].presence || "gallery",
          caption: payload[:caption],
          sort_order: payload[:sort_order].presence || 0,
          metadata: payload[:metadata] || {}
        )
        record_link_event!(link, "created")
        link
      end

      def soft_delete_link!(link)
        return link if link.deleted_at.present?

        link.update!(deleted_at: Time.current, revision: link.revision.to_i + 1)
        resolver = ::Assets::AttachableResolver.new(user: current_user)
        Sync::DeletedRecordRecorder.record!(
          entity_type: "asset_link",
          entity_id: link.id,
          trip: resolver.trip_for(link),
          user: resolver.owner_user_for(link),
          deleted_by_user: current_user,
          deleted_by_device: current_device,
          reason: "deleted",
          revision: link.revision
        )
        link
      end

      def record_link_event!(link, action)
        resolver = ::Assets::AttachableResolver.new(user: current_user)
        Sync::EventRecorder.record!(
          link,
          action: action,
          actor_user: current_user,
          actor_device: current_device,
          trip: resolver.trip_for(link),
          user: resolver.owner_user_for(link)
        )
      end

      def link_payload
        params.require(:link).permit(
          :attachable_type,
          :attachable_id,
          :role,
          :caption,
          :sort_order,
          attachable_ref: {},
          metadata: {}
        ).to_h.with_indifferent_access
      end

      def link_update_payload
        params.require(:asset_link).permit(
          :role,
          :caption,
          :sort_order,
          metadata: {}
        ).to_h.with_indifferent_access
      end
    end
  end
end
