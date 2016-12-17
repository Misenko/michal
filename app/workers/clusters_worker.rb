# Sidekiq worker class for loading and storing cluster data
#
class ClustersWorker < OpenNebulaWorker
  def perform(opennebula, token, timestamp)
    super opennebula, token, timestamp

    pool = open_nebula_data_miner.load_clusters
    pool.each do |cluster|
      store OneCluster, cluster
    end
  end
end
