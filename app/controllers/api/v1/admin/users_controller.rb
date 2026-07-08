module Api
  module V1
    module Admin
      class UsersController < BaseController
        DEFAULT_LIMIT = 100
        MAX_LIMIT = 250

        before_action :authenticate_api_session!
        before_action :require_admin_user!

        def index
          @users = User.where(deleted_at: nil)
                       .includes(:profile_photo_asset)
                       .order(created_at: :desc, id: :desc)
                       .limit(limit)

          render json: {
            users: @users.map do |user|
              Serializers.admin_user(
                user,
                trip_count: trip_counts.fetch(user.id, 0),
                map_count: map_counts.fetch(user.id, 0),
                last_seen_at: last_seen_at_by_user_id[user.id]
              )
            end
          }
        end

        private

        def limit
          value = params[:limit].to_i
          value = DEFAULT_LIMIT if value <= 0
          [ value, MAX_LIMIT ].min
        end

        def trip_counts
          @trip_counts ||= Trip.active.where(owner_user_id: user_ids).group(:owner_user_id).count
        end

        def map_counts
          @map_counts ||= PlaceList.active.where(user_id: user_ids).group(:user_id).count
        end

        def last_seen_at_by_user_id
          @last_seen_at_by_user_id ||= Device.active.where(user_id: user_ids).group(:user_id).maximum(:last_seen_at)
        end

        def user_ids
          @user_ids ||= @users.map(&:id)
        end
      end
    end
  end
end
