class Michal::Modules::InTime < Michal::Modules::Base
  METRICES = {
    cpu_load: { names: ['cpu_load'], desc_name: 'CPU Load' },
    allocated_cpu: { names: ['allocated_cpu'], desc_name: 'Allocated CPU' },
    allocated_vcpu: { names: ['allocated_vcpu'], desc_name: 'Allocated VCPU' },
    allocated_memory: { names: ['allocated_memory'], desc_name: 'Allocated Memory' },
    used_memory: { names: ['used_memory'], desc_name: 'Used Memory' },
    allocated_cpu_vs_cpu_load: { names: ['cpu_load', 'allocated_cpu'], desc_name: 'Allocated CPU vs. CPU Load' },
    allocated_cpu_vs_allocated_vcpu: { names: ['allocated_vcpu', 'allocated_cpu'], desc_name: 'Allocated CPU vs. Allocated VCPU' },
    used_memory_vs_allocated_memory: { names: ['used_memory', 'allocated_memory'], desc_name: 'Allocated Memory vs. Used Memory' },
    allocated_memory_vs_allocated_cpu: { names: ['allocated_memory', 'allocated_cpu'], desc_name: 'Allocated Memory vs. Allocated CPU', options: { multiple_axis: true } }
  }

  ENTITIES = {
    cluster: { name: 'clustername', desc_name: 'Cluster' },
    host: { name: 'host', desc_name: 'Host' },
    city: { name: 'city', desc_name: 'City' },
    vm_id: { name: 'deploy_id', desc_name: 'Virtual Machine ID' },
    user: { name: 'user', desc_name: 'User' },
    group: { name: 'group', desc_name: 'Group' }
  }

  OPENTSDB_BASED = [:cluster, :host, :city, :vm_id]
  MAX_DATA_POINTS = 300
  GRAPH_TYPE = 'area'

  class << self
    def module?
      true
    end

    def components
      {
        metrices: METRICES.map {|k,v| v },
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
      "In Time"
    end
  end

  def initialize(parameters, logger=nil)
    super parameters, logger

    @sources = {
      opentsdb: Michal::Sources::OpenTsdb.new(parameters[:sources][:opentsdb], logger),
      opennebula: Michal::Sources::OpenNebula.new(parameters[:sources][:opennebula], logger)
    }
  end

  # Obtains data for given series and its parameters
  #
  # @param [Fixnum] serie_index
  # @return [Hash] obtained data
  def obtain_data(serie_index)
    metric = parameters[:series][serie_index][:metric]
    send(metric, parameters)
  end

  private

  # Returns data about CPU load
  #
  # @param [Hash] parameters
  # @return [Hash] data
  def cpu_load(parameters)
    data_from_opentsdb(:cpu_load, METRICES[:cpu_load][:desc_name], parameters)
  end

  # Returns data about VCPUs
  #
  # @param [Hash] parameters
  # @return [Hash] data
  def allocated_vcpu(parameters)
    data_from_opentsdb(:allocated_vcpu, METRICES[:allocated_vcpu][:desc_name], parameters)
  end

  # Returns data about allocated memory
  #
  # @param [Hash] parameters
  # @return [Hash] data
  def allocated_memory(parameters)
    data_from_opentsdb(:allocated_memory, METRICES[:allocated_memory][:desc_name], parameters)
  end

  # Returns data about used memory
  #
  # @param [Hash] parameters
  # @return [Hash] data
  def used_memory(parameters)
    data_from_opentsdb(:used_memory, METRICES[:used_memory][:desc_name], parameters)
  end

  # Returns data about allocated CPUs
  #
  # @param [Hash] parameters
  # @return [Hash] data
  def allocated_cpu(parameters)
    name = METRICES[:allocated_cpu][:desc_name]
    vm_deploy_ids = []

    case parameters[:entity_type][:name]
    when ENTITIES[:cluster][:name], ENTITIES[:city][:name], ENTITIES[:host][:name]
      parameters[:aggregator] = Memoir::Aggregator::SUM
      parameters[:downsample_aggregator] = Memoir::Aggregator::SUM

      vm_filter = {}
      vm_filter[:type] = Memoir::FilterType::WILDCARD
      vm_filter[:tagk] = ENTITIES[:vm_id][:name]
      vm_filter[:filter] = '*'
      vm_filter[:group_by] = true

      entity_filter = {}
      entity_filter[:type] = Memoir::FilterType::LITERAL_OR
      entity_filter[:tagk] = parameters[:entity_type][:name]
      entity_filter[:filter] = parameters[:entity_name]
      entity_filter[:group_by] = false

      parameters[:filters] = [vm_filter, entity_filter]
      parameters[:downsample] = parameters[:to] - parameters[:from]

      meta_data = sources[:opentsdb].query(:cpu_load, parameters)
      meta_data.each do |data_set|
        vm_deploy_ids << data_set.tags[ENTITIES[:vm_id][:name]]
      end
    when ENTITIES[:vm_id][:name]
      vm_deploy_ids << parameters[:entity_name]
    when ENTITIES[:user][:name], ENTITIES[:group][:name]
      vm_deploy_ids = sources[:opennebula].send("vms_for_#{parameters[:entity_type][:name]}", parameters[:entity_name], parameters[:from], parameters[:to])
      vm_deploy_ids.compact!
    end

    data = []
    times = (parameters[:from]..parameters[:to]).spread(MAX_DATA_POINTS)
    times.each do |time|
      result = sources[:opennebula].cpu_sum(vm_deploy_ids, time)
      data << [time*1000, result.first['cpu']]
    end

    { data: data, type: GRAPH_TYPE, name: name }
  end

  private

  # Returns data from OpenTSDB source
  #
  # @param [String] metric
  # @param [String] name of entity
  # @param [Hash] parameters
  # @return [Hash] data
  def data_from_opentsdb(metric, name, parameters)
    parameters[:aggregator] = Memoir::Aggregator::SUM
    parameters[:downsample_aggregator] = Memoir::Aggregator::AVG
    filter = {}
    filter[:group_by] = false
    filter[:type] = Memoir::FilterType::LITERAL_OR

    if OPENTSDB_BASED.map { |symbol| ENTITIES[symbol][:name] }.include? parameters[:entity_type][:name]
      filter[:tagk] = parameters[:entity_type][:name]
      filter[:filter] = parameters[:entity_name]
      parameters[:filters] = [filter]
    else
      vm_ids = sources[:opennebula].send("vms_for_#{parameters[:entity_type][:name]}", parameters[:entity_name], parameters[:from], parameters[:to])
      filter[:tagk] = ENTITIES[:vm_id][:name]
      filter[:filter] = vm_ids.compact.join('|')

      opennebula_filter = {}
      #FIXME store the tag value somewhere else
      opennebula_filter[:tagk] = 'cloudsite'
      opennebula_filter[:filter] = parameters[:sources][:opennebula]
      opennebula_filter[:group_by] = false
      opennebula_filter[:type] = Memoir::FilterType::LITERAL_OR

      parameters[:filters] = [filter, opennebula_filter]
    end


    data = []
    unless filter[:filter].empty?
      data = sources[:opentsdb].query(metric, parameters)
      data = data.first.dps unless data.empty?
      data.map! { |pair| [pair[0], pair[1]/100] } if metric == :cpu_load
    end
    { data: data, type: GRAPH_TYPE, name: name }
  end
end
