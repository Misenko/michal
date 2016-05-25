class Api::V1::SourcesController < ApplicationController
  def list
    render json: available_sources
  end

  private

  def available_sources
    sources = {}
    Settings[:sources].each do |source_name, source|
      unless sources.include? source[:type]
        sources[source[:type]] = []
      end

      sources[source[:type]] << source_name
    end

    sources
  end
end
