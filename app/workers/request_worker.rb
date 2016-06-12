require 'sidekiq'

# Sidekiq worker class handling requests and statistic computation
#
class RequestWorker
  include ::Sidekiq::Worker

  attr_reader :db_client

  sidekiq_options queue: Settings[:sidekiq][:queues].first, retry: 2, dead: false

  def perform(request_document_id, graph_index, serie_index, waiting_document_id)
    @db_client = Michal::DbClient.new logger

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
    update_hash = prepare_update(data, graph_index, serie_index)
    db_client.update(:statistics, {_id: BSON::ObjectId(request_document_id)}, {'$set' => update_hash}, { upsert: true })
  end

  def load_request(request_document_id)
    db_client.read_one(:statistics, {_id: BSON::ObjectId(request_document_id)})
  end

  def remove_waiting(waiting_document_id)
    db_client.delete_one(:waiting, {_id: BSON::ObjectId(waiting_document_id)})
  end

  def prepare_update(data, graph_index, serie_index)
    prefix = "graphs.#{graph_index}.series.#{serie_index}."
    Hash[data.map{ |k,v| ["#{prefix}#{k}", v]}]
  end
end
