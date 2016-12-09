# Sidekiq worker class for loading and storing host data
#
class HostsWorker < OpenNebulaWorker
  def perform(opennebula, token, timestamp)
    super opennebula, token, timestamp

    pool = open_nebula_data_miner.load_hosts
    pool.each do |host|
      store OneHost, host
    end
  end
end
