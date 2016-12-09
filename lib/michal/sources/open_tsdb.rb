require 'memoir'

# OpenTSDB source class
#
class Michal::Sources::OpenTsdb < Michal::Sources::Base
  attr_reader :client, :metric, :parameters

  METRICES = {
    cpu_load: 'libvirt.vm.cpu.load',
    allocated_vcpu: 'libvirt.vm.max.vcpus',
    allocated_memory: 'libvirt.vm.max.memory',
    used_memory: 'libvirt.vm.memory',
    available_cpu: 'cpustat.count'
  }

  STATUSES = {
    ok: 200,
    bad_request: 400
  }

  MAX_POINTS = 500

  # Constructor
  #
  # @param [Sring] name OpenTSDB source name
  # @param [Logger] logger
  def initialize(name, logger)
    super name, logger

    hostname = Settings[:sources][name][:endpoint]
    port = Settings[:sources][name][:port]

    @client = Memoir::Client.new(hostname, port, logger)
  end

  # Runs query on OpenTSDB
  #
  # @param [String] metric
  # @param [Hash] parameters
  # @return [Array] returned data sets
  def query(metric, parameters)
    @metric = metric
    calculate_downsample(parameters) unless parameters[:downsample]

    query = Memoir::Query.new parameters[:aggregator], METRICES[metric]
    downsample = Memoir::Downsample.new Memoir::TimePeriod.new(parameters[:downsample], Memoir::Units::SECONDS), parameters[:downsample_aggregator]
    query.downsample = downsample
    parameters[:filters].each do |filter_params|
      filter = Memoir::Filter.new filter_params[:type], filter_params[:tagk], filter_params[:filter], filter_params[:group_by]
      query << filter
    end
    request = Memoir::Request.new parameters[:from], parameters[:to], ms_resolution: true
    request << query
    request.arrays = true

    client.dry_run request
    logger.debug client.connection
    response = client.run request

    logger.debug response

    fail Michal::Errors::DataMiners::OpenTsdbError, response.body unless response.status == STATUSES[:ok]

    response.data_sets
  end

  private

  def calculate_downsample(parameters)
    duration = parameters[:to] - parameters[:from]
    parameters[:downsample] = duration / MAX_POINTS
  end
end
