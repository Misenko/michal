class HomeController < ApplicationController
  def index
    render 'index'
  end

  def show
    render 'index'
  end

  def invalid_api
    render json: { message: "Invalid API request" }.to_json, status: :not_found
  end
end
