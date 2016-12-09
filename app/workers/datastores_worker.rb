# Sidekiq worker class for loading and storing datastore data
#
class DatastoresWorker < OpenNebulaWorker
  def perform(opennebula, token, timestamp)
    super opennebula, token, timestamp

    pool = open_nebula_data_miner.load_datastores
    pool.each do |datastore|
      store OneDatastore, datastore
    end
  end
end
