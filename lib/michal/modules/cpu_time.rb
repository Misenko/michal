class Michal::Modules::CpuTime < Michal::Modules::Base
  ENTITIES = {
    host: { name: 'host', desc_name: 'Host' },
    cluster: { name: 'clustername', desc_name: 'Cluster' },
    city: { name: 'city', desc_name: 'City' },
    users: { name: 'users', desc_name: 'Users' },
    groups: { name: 'groups', desc_name: 'Groups' } # ,
    # cluster_host: { name: 'cluster_host', desc_name: 'Hosts per cluster', subgraph: :host },
    # city_cluster: { name: 'city_cluster', desc_name: 'Clusters per city', subgraph: :cluster },
    # group_user: { name: 'group_user', desc_name: 'Users per groups', subgraph: :user }
  }

  GRAPH_TYPE = 'pie'

  class << self
    def module?
      true
    end

    def components
      {
        entities: ENTITIES.map {|k,v| v },
        periods: [
          { desc_name: 'Last day', name: 'day' },
          { desc_name: 'Last week', name: 'week' },
          { desc_name: 'Last month', name: 'month' },
          { desc_name: 'Last year', name: 'year'}
        ]
      }
    end

    def title
      "CPU Time"
    end
  end

  def initialize(parameters, logger=nil)
    super parameters, logger

    @sources = {
      opentsdb: Michal::Sources::OpenTsdb.new(parameters[:sources][:opentsdb], logger),
      opennebula: []
    }

    parameters[:sources][:opennebula].each do |opennebula|
      sources[:opennebula] << Michal::Sources::OpenNebula.new(opennebula, logger)
    end
  end

  # Obtains data for given series and its parameters
  #
  # @param [Fixnum] serie_index
  # @return [Hash] obtained data
  def obtain_data(serie_index)
    send("cpu_time_for_#{parameters[:entity_type][:name]}".to_sym)
  end

  private

  def  cpu_time_for_groups
    cpu_time_for_groups_and_users
  end

  def  cpu_time_for_users
    cpu_time_for_groups_and_users
  end

  def cpu_time_for_groups_and_users
    parameters[:aggregator] = Memoir::Aggregator::SUM
    parameters[:downsample_aggregator] = Memoir::Aggregator::MAX

    request_from = parameters[:from]
    request_to = parameters[:to]

    result_map = Hash.new(0)

    sources[:opennebula].each do |opennebula|
      entities = opennebula.send("map_#{parameters[:entity_type][:name]}_vms_with_clusters".to_sym, request_from, request_to, Settings[:sources][opennebula.name.to_sym][:clusters])
      entities.each do |entity|
        entity_name = entity['_id']

        entity['vms'].each do |vm|
          vm['HISTORY_RECORDS']['HISTORY'].each do |history|
            next if (history['RSTIME'] > request_to || history['RETIME'] < request_from)

            vm_id = vm['DEPLOY_ID']
            from = [history['RSTIME'], request_from].max
            to = [history['RETIME'], request_to].min
            to = request_to if to == 0

            next if (to - from) < 15

            parameters[:from] = from
            parameters[:to] = to
            parameters[:entity_type][:name] = 'deploy_id'

            value = max_values(opennebula, vm_id).zip(min_values(opennebula, vm_id)).inject(0) { |sum, x| sum + (x.first[:last] - x.last[:first]) }
            result_map[entity_name] += value
          end
        end
      end
    end

    result_data = result_map.keys.zip(result_map.values).map { |x| { name: x.first, y: x.last } }
    { data: result_data, type: GRAPH_TYPE, name: 'CPU Time' }
  end

  def cpu_time_for_most
    parameters[:aggregator] = Memoir::Aggregator::SUM
    parameters[:downsample_aggregator] = Memoir::Aggregator::MAX

    request_from = parameters[:from]
    request_to = parameters[:to]

    result_map = Hash.new(0)

    sources[:opennebula].each do |opennebula|
      vms = opennebula.vms_with_clusters(request_from, request_to, Settings[:sources][opennebula.name.to_sym][:clusters])
      vms.each do |vm|
        vm['VM']['HISTORY_RECORDS']['HISTORY'].each do |history|
          next if (history['RSTIME'] > request_to || history['RETIME'] < request_from)

          vm_id = vm['VM']['DEPLOY_ID']
          from = [history['RSTIME'], request_from].max
          to = [history['RETIME'], request_to].min
          to = request_to if to == 0

          next if (to - from) < 15

          parameters[:from] = from
          parameters[:to] = to

          tmp_data = max_values(opennebula, vm_id).zip(min_values(opennebula, vm_id)).map { |x| { name: x.first[:name], y: x.first[:last] - x.last[:first] } }
          tmp_data.each { |data| result_map[data[:name]] += data[:y] }
        end
      end
    end

    result_data = result_map.keys.zip(result_map.values).map { |x| { name: x.first, y: x.last } }
    { data: result_data, type: GRAPH_TYPE, name: 'CPU Time' }
  end

  def cpu_time_for_clustername
    cpu_time_for_most
  end

  def cpu_time_for_host
    cpu_time_for_most
  end

  def cpu_time_for_city
    cpu_time_for_most
  end

  def max_values(opennebula, vm_id)
    values Memoir::Aggregator::MAX, opennebula, vm_id
  end

  def min_values(opennebula, vm_id)
    values Memoir::Aggregator::MIN, opennebula, vm_id
  end

  def values(aggregator, opennebula, vm_id)
    parameters[:aggregator] = Memoir::Aggregator::SUM
    parameters[:downsample_aggregator] = aggregator
    result_data = []

    filter = {}
    filter[:type] = Memoir::FilterType::WILDCARD
    filter[:tagk] = parameters[:entity_type][:name]
    filter[:filter] = '*'
    filter[:group_by] = true

    vm_filter = {}
    vm_filter[:tagk] = 'deploy_id'
    vm_filter[:filter] = vm_id
    vm_filter[:group_by] = false
    vm_filter[:type] = Memoir::FilterType::LITERAL_OR

    # FIXME
    # Some of this years data are still missing 'cloudsite' tag so for now we use clusters to determine which OpenNebula was used
    # opennebula_filter = {}
    # opennebula_filter[:tagk] = 'cloudsite'
    # opennebula_filter[:filter] = opennebula.name
    # opennebula_filter[:group_by] = false
    # opennebula_filter[:type] = Memoir::FilterType::LITERAL_OR

    opennebula_filter = {}
    opennebula_filter[:tagk] = 'clustername'
    opennebula_filter[:filter] = opennebula.name == 'MetaCloud' ? 'dukan.ics.muni.cz' : 'warg.meta.zcu.cz'
    opennebula_filter[:group_by] = false
    opennebula_filter[:type] = Memoir::FilterType::LITERAL_OR

    parameters[:filters] = [filter, opennebula_filter, vm_filter]
    parameters[:downsample] = guess_downsample(parameters[:from], parameters[:to])
    data_set = sources[:opentsdb].query(:cpu_time, parameters)

    data_set.each do |result|
      entity = result.tags[parameters[:entity_type][:name]]

      result_data << { name: entity, first: result.dps.first.last, last: result.dps.last.last } unless result.dps.empty?
    end

    result_data
  end

  def guess_downsample(from, to)
    duration = to - from
    duration / 60
  end
end
