class UsersController < ApplicationController
  def index
    @user_count = User.count
    @active_user_count = User.active.count
    @users = User.preload(:devices, :owned_trips).order(created_at: :desc).limit(100)
  end

  def update
    user = User.find(params[:id])
    user.update!(user_params)
    redirect_to users_path
  end

  private

  def user_params
    params.require(:user).permit(:admin)
  end
end
