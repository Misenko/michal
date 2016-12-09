require 'sidekiq'
require 'sidekiq-status'

# Sidekiq worker class for all OpenNebula workers
#
class OpenNebulaWorker
  include ::Sidekiq::Worker
  include ::Sidekiq::Status::Worker

  attr_reader :open_nebula_data_miner, :collection

  sidekiq_options queue: Settings[:sidekiq][:queues].first, retry: 2, dead: false

  def perform(opennebula, timestamp, token)
    @open_nebula_data_miner = Michal::DataLoaders::OpenNebula.new(opennebula, token, logger)
    @collection = "#{opennebula}-#{timestamp}"
  end

  private

  # Stores element into DB
  #
  # @param [OpenNebula::Element] element
  def store(clazz, data)
    element_hash = convert(data)

    object = clazz.new
    object.data = element_hash.values.first
    object.with(collection: collection).save
  end

  # Converts element from its xml form to json
  #
  # @param [OpenNebula::Element] element
  # @return [Hash] element in json form
  def convert(element)
    element_xml = element.to_xml
    element_hash = Hash.from_xml(element_xml)

    # change HISTORY_RECORDS with only one HISTORY element into array
    if element_hash['VM'] && element_hash['VM']['HISTORY_RECORDS'] && element_hash['VM']['HISTORY_RECORDS']['HISTORY'].kind_of?(Hash)
      element_hash['VM']['HISTORY_RECORDS']['HISTORY'] = [element_hash['VM']['HISTORY_RECORDS']['HISTORY']]
    end

    Michal::Helpers::FormatHelper.convert_numbers!(element_hash)
  end
end
