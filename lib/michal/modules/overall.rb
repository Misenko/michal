class Michal::Modules::Overall < Michal::Modules::Base
  METRICES = {
    cpu_load: { names: ['cpu_load'], desc_name: 'CPU Load' },
    allocated_cpu: { names: ['allocated_cpu'], desc_name: 'Allocated CPU' },
    allocated_vcpu: { names: ['allocated_vcpu'], desc_name: 'Allocated VCPU' },
    allocated_memory: { names: ['allocated_memory'], desc_name: 'Allocated memory' },
    used_memory: { names: ['used_memory'], desc_name: 'Used memory' }
  }

  ENTITIES = {
    user: { name: 'user', desc_name: 'Users' },
    group: { name: 'group', desc_name: 'Groups' },
    group_user: { name: 'group_user', desc_name: 'Users per groups' },
  }

  GRAPH_TYPE = 'pie'

  class << self
    def module?
      false
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
      "Overall"
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
    metric = parameters[:series][serie_index][:metric]
    send(metric, parameters)
  end

  private

  # Returns data about allocated CPUs
  #
  # @param [Hash] parameters
  # @return [Hash] data
  def allocated_cpu(parameters)
    name = METRICES[:allocated_cpu][:desc_name]

    entity_type = parameters[:entity_type][:name]
    entity_type = ENTITIES[:group][:name] if parameters[:entity_type][:name] == ENTITIES[:group_user][:name]

    map = Hash.new(0)
    sources[:opennebula].each do |opennebula|
      results = opennebula.send("map_#{entity_type}_cpu", parameters[:from], parameters[:to])
      results.each { |result| map[result['_id']] += result['cpu'] }
    end

    data = []
    drilldown = []
    map.each do |key, value|
      result = {}
      result[:name] = key
      result[:y] = value
      if parameters[:entity_type][:name] == ENTITIES[:group_user][:name]
        drilldown_map = Hash.new(0)
        sources[:opennebula].each do |opennebula|
          results = opennebula.map_user_cpu_in_group(key, parameters[:from], parameters[:to])
          results.each { |r| drilldown_map[r['_id']] += r['cpu'] }
        end

        drilldown << {name: key, id: key, data: drilldown_map.to_a}
        result[:drilldown] = key
      end
      data << result
    end

    return_value = { data: data, type: GRAPH_TYPE, name: name }
    return_value[:drilldown] = drilldown if parameters[:entity_type][:name] == ENTITIES[:group_user][:name]

    return_value
  end

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

  private

  # Helper method for creating map of entity and specified value
  #
  # @param [String] metric
  # @param [Hash] parameters
  # @param [Array] send_args
  # @return [Hash] constructed map
  def entity_value_map(metric, parameters, *send_args)
    vms_from_opennebulas = {}

    sources[:opennebula].each do |opennebula|
      vms_from_opennebulas[opennebula] = Hash.new([])
      results = opennebula.send(*send_args)
      results.each { |result| vms_from_opennebulas[opennebula][result['_id']] |= result['vms'] }
    end

    parameters[:aggregator] = Memoir::Aggregator::MAX
    parameters[:downsample_aggregator] = Memoir::Aggregator::MAX
    parameters[:downsample] = parameters[:to] - parameters[:from]

    vms_filter = {}
    vms_filter[:group_by] = false
    vms_filter[:type] = Memoir::FilterType::LITERAL_OR
    #FIXME store the tag value somewhere else
    vms_filter[:tagk] = 'deploy_id'

    opennebula_filter = {}
    opennebula_filter[:group_by] = false
    opennebula_filter[:type] = Memoir::FilterType::LITERAL_OR
    #FIXME store the tag value somewhere else
    opennebula_filter[:tagk] = 'cloudsite'

    result_map = Hash.new(0)
    vms_from_opennebulas.each do |opennebula, data_map|
      opennebula_filter[:filter] = opennebula.name

      data_map.each do |entity, vms|
        vms_filter[:filter] = vms.compact.join('|')
        parameters[:filters] = [vms_filter, opennebula_filter]

        opentsdb_result = sources[:opentsdb].query(metric, parameters)
        dps = opentsdb_result.first.dps.first unless opentsdb_result.blank?
        value = dps.last unless dps.blank?
        next unless value

        value /= 100 if metric == :cpu_load

        result_map[entity] += value
      end
    end

    result_map
  end

  # Returns data from OpenTSDB source
  #
  # @param [String] metric
  # @param [String] name of entity
  # @param [Hash] parameters
  # @return [Hash] data
  def data_from_opentsdb(metric, name, parameters)
    group_user_entity = parameters[:entity_type][:name] == ENTITIES[:group_user][:name]
    entity_type = parameters[:entity_type][:name]
    entity_type = ENTITIES[:group][:name] if group_user_entity

    result_map = entity_value_map(metric, parameters, "map_#{entity_type}_vms", parameters[:from], parameters[:to])

    data = []
    drilldown = []
    result_map.each do |entity, value|
      data_row = {}
      data_row[:name] = entity
      data_row[:y] = value

      if group_user_entity
        inner_map = entity_value_map(metric, parameters, "map_user_vms_in_group", entity, parameters[:from], parameters[:to])
        drilldown << {name: entity, id: entity, data: inner_map.to_a}
        data_row[:drilldown] = entity
      end

      data << data_row
    end

    return_value = { data: data, type: GRAPH_TYPE, name: name }
    return_value[:drilldown] = drilldown if group_user_entity

    return_value
  end
end
