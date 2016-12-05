require 'sidekiq'

# Sidekiq worker class handling requests and statistic computation
#
class RequestWorker
  include ::Sidekiq::Worker

  sidekiq_options queue: Settings[:sidekiq][:queues].first, retry: 2, dead: false

  def perform(request_document_id, graph_index, serie_index, waiting_document_id)
    logger.debug "Options: #{[request_document_id, graph_index, serie_index]}"
    logger.debug "Settings: #{Settings}"

    request = load_request request_document_id
    graph = request[:graphs][graph_index]

    m = module_instance graph
    data = m.obtain_data(serie_index)
    store_data(data, request_document_id, graph_index, serie_index)
    remove_waiting(waiting_document_id)
  end

  private

  def module_instance(graph)
    module_name = "#{Michal::Modules.name}::#{graph[:module].camelize}"
    module_name.constantize.new graph, logger
  end

  def store_data(data, request_document_id, graph_index, serie_index)
    request = Statistic.find(request_document_id)
    request.graphs[graph_index][:series][serie_index].merge!(data)
    request.save
  end

  def load_request(request_document_id)
    Statistic.find(request_document_id)
  end

  def remove_waiting(waiting_document_id)
    Waiting.find(waiting_document_id).destroy
  end
end
