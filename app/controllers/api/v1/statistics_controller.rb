class Api::V1::StatisticsController < ApplicationController
  before_action :set_statistic, only: [:show]

  def show
    respond_to do |format|
      format.json do
        logger.debug(@statistic.inspect)
        if @statistic.nil?
          render json: { message: 'No such statistic' }.to_json, status: :not_found
          return
        end

        if @statistic['ready']
          render json: @statistic.to_json
        else
          logger.debug("still processing")
          render json: { message: 'Your statistic is not ready yet, we\'re still looking for the right data'}.to_json, status: :partial_content
        end
      end
    end
  end

  def periodic
    respond_to do |format|
      format.json do
        @statistics = Statistic.where(periodic: true)
        render json: @statistics.map { |statistic| {name: statistic.name, url: statistic.url, last_update: statistic.last_update.strftime('%d.%m.%Y')} }
      end
    end
  end

  def index
    respond_to do |format|
      format.json do
        @statistics = Statistic.where(user: current_user)
        render json: @statistics.map { |statistic| {name: statistic.name, url: statistic.url, last_update: statistic.last_update.strftime('%d.%m.%Y')} }
      end
    end
  end

  def create
    respond_to do |format|
      format.json do
        logger.debug params
        db_client = Michal::DbClient.new logger
        @statistic = Statistic.new(statistic_params)

        @statistic.resource_id = SecureRandom.hex
        @statistic.url = statistic_url(@statistic.resource_id)
        @statistic.ready = false
        @statistic.graphs.each { |graph| convert_time! graph }
        @statistic.user = current_user

        @statistic.save && current_user.add_role(:owner, @statistic)

        @statistic.graphs.each_with_index do |graph, graph_index|
          graph_h = graph.deep_symbolize_keys
          graph_h[:series].each_with_index do |serie, serie_index|
            waiting_document_id = db_client.write_one(:waiting, {request_id: @statistic.id, graph: graph_index, serie: serie_index}).to_s
            RequestWorker.perform_async(@statistic.id.to_s, graph_index, serie_index, waiting_document_id)
          end
        end

        render json: { url: @statistic.url }
      end
    end
  end

  def statistic_params
    params.require(:statistic).permit([:email, :name, :periodic, :period]).tap do |whitelisted|
      whitelisted[:graphs] = params[:statistic][:graphs]
    end
  end

  private

  def set_statistic
    @statistic = Statistic.find_by resource_id: params[:resource_id]
  end

  def convert_time!(graph)
    if graph[:last]
      graph[:to] = Time.now.to_i
      graph[:from] = 1.send(graph[:last]).ago.to_i
    end
  end
end
