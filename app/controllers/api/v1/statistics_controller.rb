class Api::V1::StatisticsController < ApplicationController
  before_action :set_statistic, only: [:show, :destroy]

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

  def destroy
    respond_to do |format|
      format.json do
        logger.debug(@statistic.inspect)
        if @statistic.nil?
          render json: { message: 'No such statistic' }.to_json, status: :not_found
          return
        end

        @statistic.destroy
        render json: { message: 'Destroyed' }.to_json
      end
    end
  end

  def periodic
    respond_to do |format|
      format.json do
        render json: statistic_map(periodic: true)
      end
    end
  end

  def index
    respond_to do |format|
      format.json do
        render json: statistic_map(user: current_user)
      end
    end
  end

  def create
    respond_to do |format|
      format.json do
        logger.debug params
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
            waiting = Waiting.new
            waiting.graph = graph_index
            waiting.serie = serie_index
            waiting.statistic = @statistic
            waiting.save
            waiting_document_id = waiting.id
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

  def statistic_map(where={})
    @statistics = Statistic.where(where)
    @statistics.map do |statistic|
      last_update = statistic.last_update
      if last_update
        last_update = last_update.strftime('%d.%m.%Y')
      else
        last_update = "pending"
      end
      {name: statistic.name, url: statistic.url, last_update: last_update, resource_id: statistic.resource_id}
    end
  end

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
