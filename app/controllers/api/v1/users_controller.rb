class Api::V1::UsersController < ApplicationController
  def index
    respond_to do |format|
      format.json do
        if current_user
          render json: [{ name: current_user.name, email: current_user.email, admin: current_user.admin? }].to_json
        else
          render json: { message: "There is currently no user logged in" }.to_json, status: :not_found
        end
      end
    end
  end
end
