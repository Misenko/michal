class Api::V1::ModulesController < ApplicationController
  def show
    render json: modul_components(params[:name])
  end

  def index
    render json: available_modules
  end

  def request_params
    params.require(:name)
  end

  private

  def modul_components(name)
    class_name = "#{Michal::Modules.name}::#{name.camelize}"
    class_name.constantize.components
  end

  def available_modules
    constants = Michal::Modules.constants
    modules = []
    constants.each do |constant|
      clazz = Michal::Modules.const_get constant
      modules <<  { name: constant.to_s, title: clazz.title } if clazz.respond_to?('module?') && clazz.module? && clazz.respond_to?('name')
    end

    modules.sort_by { |m| m[:name] }
  end
end
