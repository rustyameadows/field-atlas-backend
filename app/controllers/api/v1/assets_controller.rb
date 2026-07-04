module Api
  module V1
    class AssetsController < BaseController
      class_attribute :r2_client_factory, default: -> { ::Assets::R2Client.new }

      before_action :authenticate_api_session!

      rescue_from ActiveRecord::RecordInvalid do |error|
        render_error("validation_failed", error.record.errors.full_messages.to_sentence, status: :unprocessable_entity)
      end

      rescue_from ::Assets::R2Client::ConfigurationError do |error|
        render_error("storage_not_configured", error.message, status: :service_unavailable)
      end

      rescue_from ::Assets::R2Client::ObjectNotFound do |error|
        render_error("upload_not_found", error.message, status: :unprocessable_entity)
      end

      def upload_intents
        asset = nil
        links = []

        ActiveRecord::Base.transaction do
          asset = create_asset!
          Sync::EventRecorder.record!(asset, action: "created", actor_user: current_user, actor_device: current_device, user: current_user)
          links = create_initial_links!(asset)
        end

        upload = r2_client.presigned_upload(storage_key: asset.storage_key, content_type: asset.mime_type)
        render json: {
          asset: Serializers.asset(asset),
          links: links.map { |link| Serializers.asset_link(link) },
          upload: Serializers.transfer_intent(upload)
        }, status: :created
      end

      def complete
        asset = Asset.active.find(params[:id])
        raise ForbiddenError, "Only the uploader can complete this asset." unless asset.uploaded_by_user_id == current_user.id

        metadata = r2_client.object_metadata(storage_key: asset.storage_key)
        if metadata[:byte_size].present? && metadata[:byte_size].to_i != asset.byte_size.to_i
          return render_error("upload_size_mismatch", "Uploaded object size does not match the asset intent.", status: :unprocessable_entity)
        end
        if metadata[:mime_type].present? && metadata[:mime_type] != asset.mime_type
          return render_error("upload_type_mismatch", "Uploaded object content type does not match the asset intent.", status: :unprocessable_entity)
        end

        asset.ready!
        Sync::EventRecorder.record!(asset, action: "updated", actor_user: current_user, actor_device: current_device, user: current_user)
        render json: { asset: Serializers.asset(asset) }
      end

      def download_intents
        asset_ids = Array(params[:asset_ids]).map(&:to_s).reject(&:blank?)
        assets = Asset.ready.where(id: asset_ids).index_by(&:id)
        resolver = ::Assets::AttachableResolver.new(user: current_user)
        downloads = asset_ids.map do |asset_id|
          asset = assets[asset_id]
          raise ActiveRecord::RecordNotFound if asset.blank? || !resolver.visible_asset?(asset)

          intent = r2_client.presigned_download(storage_key: asset.storage_key)
          Serializers.download_intent(asset, intent)
        end

        render json: { downloads: downloads }
      end

      def destroy
        asset = Asset.active.find(params[:id])
        raise ForbiddenError, "Only the uploader can delete this asset." unless asset.uploaded_by_user_id == current_user.id

        ActiveRecord::Base.transaction do
          asset.links.active.find_each { |link| soft_delete_link!(link) }
          asset.update!(status: "deleted", deleted_at: Time.current, revision: asset.revision.to_i + 1)
          Sync::DeletedRecordRecorder.record!(
            entity_type: "asset",
            entity_id: asset.id,
            user: asset.uploaded_by_user,
            deleted_by_user: current_user,
            deleted_by_device: current_device,
            reason: "deleted",
            revision: asset.revision
          )
        end

        render json: { asset: Serializers.asset(asset) }
      end

      private

      def create_asset!
        payload = asset_payload
        Asset.create!(
          uploaded_by_user: current_user,
          client_id: payload[:client_id],
          asset_kind: payload.fetch(:asset_kind),
          mime_type: payload.fetch(:mime_type),
          original_filename: payload[:original_filename],
          byte_size: payload.fetch(:byte_size).to_i,
          checksum: payload[:checksum],
          storage_provider: "r2",
          storage_key: ::Assets::StorageKey.generate(user: current_user, original_filename: payload[:original_filename]),
          width: payload[:width],
          height: payload[:height],
          duration_ms: payload[:duration_ms],
          status: "awaiting_upload",
          metadata: payload[:metadata] || {}
        )
      end

      def create_initial_links!(asset)
        link_payloads.map { |payload| create_link!(asset, payload) }
      end

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

      def asset_payload
        params.require(:asset).permit(
          :client_id,
          :asset_kind,
          :mime_type,
          :original_filename,
          :byte_size,
          :checksum,
          :width,
          :height,
          :duration_ms,
          metadata: {}
        ).to_h.with_indifferent_access
      end

      def link_payloads
        Array(params[:links]).map do |raw_link|
          raw_link.respond_to?(:to_unsafe_h) ? raw_link.to_unsafe_h.with_indifferent_access : raw_link.to_h.with_indifferent_access
        end
      end

      def r2_client
        @r2_client ||= self.class.r2_client_factory.call
      end
    end
  end
end
