class Michal::Modules::NewVmCount < Michal::Modules::Base
  GRAPH_TYPE = 'line'

  STEPS = {
    day: { desc_name: 'Day', name: 'day', format: '%j' },
    week: { desc_name: 'Week', name: 'week', format: '%V' },
    month: { desc_name: 'Month', name: 'month', format: '%m' }
  }

  class << self
    def module?
      true
    end

    def components
      {
        steps: STEPS.map {|k,v| v },
        periods: [
          { desc_name: 'Last day', name: 'day' },
          { desc_name: 'Last week', name: 'week' },
          { desc_name: 'Last month', name: 'month' },
          { desc_name: 'Last year', name: 'year'}
        ]
      }
    end

    def title
      "New Virtual Machine Count"
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
    step = parameters[:step]

    range_start = Time.at(parameters[:from].to_i).send("beginning_of_#{step}").to_i
    range_end = Time.at(parameters[:to].to_i).send("end_of_#{step}").to_i

    data = []

    (range_start..range_end).step(1.send(step)).each do |date|
      count = 0
      sources[:opennebula].each do |opennebula|
        result = opennebula.new_vm_count(date, date + 1.send(step)).first
        count += result['count'] if result
      end

      data << {name: Time.at(date).strftime(STEPS[step.to_sym][:format]), y: count}
    end

    { data: data, type: GRAPH_TYPE, name: STEPS[step.to_sym][:desc_name] }
  end
end
