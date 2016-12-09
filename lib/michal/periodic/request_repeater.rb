# Repeats periodic requests
#
class Michal::Periodic::RequestRepeater
  # Repeats periodic requests
  #
  def repeate_requests
    periodic_requests = Statistic.where(periodic: true, ready: true)
    periodic_requests.each do |request|
      next unless repeate? request

      request.ready = false
      request.graphs.each { |graph| convert_time! graph }

      request.save
      request.graphs.each_with_index do |graph, graph_index|
        graph[:series].each_with_index do |serie, serie_index|
          waiting = Waiting.new
          waiting.graph = graph_index
          waiting.serie = serie_index
          waiting.statistic = @statistic
          waiting.save
          waiting_document_id = waiting.id
          RequestWorker.perform_async(request._id.to_s, graph_index, serie_index, waiting_document_id)
        end
      end
    end
  end

  private

  # Converts time from relative to specific
  #
  # @param [Hash] graph
  def convert_time!(graph)
    graph[:to] = Time.now.to_i
    graph[:from] = 1.send(graph[:last]).ago.to_i
  end

  # Determines whether request should be repeated
  #
  # @param [Hash] request
  def repeate?(request)
    last_update = request.last_update
    today = Time.now
    period = request.period

    last_update + 1.send(period.to_sym) <= today
  end
end
