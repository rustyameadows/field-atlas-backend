class UsersController < ApplicationController
  def index
    @user_count = User.count
    @active_user_count = User.active.count
    @users = User.preload(:devices, :owned_trips).order(created_at: :desc).limit(100)
  end

  def update
    user = User.find(params[:id])
    user.update!(admin: admin_param)
    redirect_to users_path
  end

  private

  def admin_param
    ActiveModel::Type::Boolean.new.cast(params.require(:user).fetch(:admin))
  end
end
