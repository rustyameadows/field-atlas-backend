class UsersController < ApplicationController
  def index
    @user_count = User.count
    @active_user_count = User.active.count
    @users = User.preload(:devices, :owned_trips).order(created_at: :desc).limit(100)
  end
end
