# Sidekiq worker class for loading and storing user data
#
class UsersWorker < OpenNebulaWorker
  def perform(opennebula, token, timestamp)
    super opennebula, token, timestamp

    pool = open_nebula_data_miner.load_users
    pool.each do |user|
      store user
    end
  end
end
