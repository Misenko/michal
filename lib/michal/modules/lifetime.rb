class Michal::Modules::Lifetime < Michal::Modules::Base
  GRAPH_TYPE = 'pie'

  METRICES = {
    count: { name: 'count', desc_name: 'VM count' },
    cpu_time: { name: 'cpu_time', desc_name: 'CPU Time' }
  }

  TIME_BLOCKS = [
    { name: '&lt; 1 hour', condition: Proc.new { |seconds| seconds < 1.hour } },
    { name: '&lt; 1 day', condition: Proc.new { |seconds| seconds < 1.day } },
    { name: '&lt; 1 week', condition: Proc.new { |seconds| seconds < 1.week } },
    { name: '&lt; 1 month', condition: Proc.new { |seconds| seconds < 1.month } },
    { name: '&gt;= 1 month', condition: Proc.new { |seconds| seconds >= 1.month } }
  ]

  class << self
    def module?
      true
    end

    def components
      {
        metrices: METRICES.map {|k,v| v },
        periods: [
          { desc_name: 'Last day', name: 'day' },
          { desc_name: 'Last week', name: 'week' },
          { desc_name: 'Last month', name: 'month' },
          { desc_name: 'Last year', name: 'year'}
        ]
      }
    end

    def title
      "Lifetime"
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
    send("lifetime_for_#{parameters[:series][serie_index][:metric]}")
  end

  def lifetime_for_count
    result_map = Hash.new(0)

    sources[:opennebula].each do |opennebula|
      vms = opennebula.map_vms_runtime_with_clusters(parameters[:from], parameters[:to], Settings[:sources][opennebula.name.to_sym][:clusters])
      vms.each do |vm|
        TIME_BLOCKS.each do |timeblock|
          if timeblock[:condition].call(vm['lifetime'])
            result_map[timeblock[:name]] += 1
            break
          end
        end
      end
    end
    result_data = result_map.keys.zip(result_map.values).map { |x| { name: x.first, y: x.last } }
    { data: result_data, type: GRAPH_TYPE, name: 'Proportion of short/long-lived VMs' }
  end

  def lifetime_for_cpu_time
    request_from = parameters[:from]
    request_to = parameters[:to]

    cpu_time_map = Hash.new(0)
    result_map = Hash.new(0)

    sources[:opennebula].each do |opennebula|
      vms = opennebula.vms_with_clusters(parameters[:from], parameters[:to], Settings[:sources][opennebula.name.to_sym][:clusters])
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
          tmp_data.each { |data| cpu_time_map[data[:name]] += data[:y] }
        end
      end
    end

    sources[:opennebula].each do |opennebula|
      vms = opennebula.map_vms_runtime_with_clusters(request_from, request_to, Settings[:sources][opennebula.name.to_sym][:clusters])
      vms.each do |vm|
        TIME_BLOCKS.each do |timeblock|
          if timeblock[:condition].call(vm['lifetime'])
            result_map[timeblock[:name]] += cpu_time_map[vm['_id']]
            break
          end
        end
      end
    end

    result_data = result_map.keys.zip(result_map.values).map { |x| { name: x.first, y: x.last } }
    { data: result_data, type: GRAPH_TYPE, name: 'CPU usage broken down by VM short/long-livedness' }
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

    vm_filter = {}
    vm_filter[:tagk] = 'deploy_id'
    vm_filter[:filter] = vm_id
    vm_filter[:group_by] = true
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

    parameters[:filters] = [opennebula_filter, vm_filter]
    parameters[:downsample] = guess_downsample(parameters[:from], parameters[:to])
    data_set = sources[:opentsdb].query(:cpu_time, parameters)

    data_set.each do |result|
      result_data << { name: vm_id, first: result.dps.first.last, last: result.dps.last.last } unless result.dps.empty?
    end

    result_data
  end

  def guess_downsample(from, to)
    duration = to - from
    duration / 60
  end
end
