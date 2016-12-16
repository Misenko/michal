class Michal::Modules::Lifetime < Michal::Modules::Base
  GRAPH_TYPE = 'pie'

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
end
