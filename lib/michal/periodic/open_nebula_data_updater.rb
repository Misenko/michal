# Updates data from OpenNebula sources
#
class Michal::Periodic::OpenNebulaDataUpdater
  attr_reader :batch, :opennebula, :timestamp, :token, :db_client

  def initialize(opennebula)
    @opennebula = opennebula
    @batch = Michal::Sidekiq::Batch.new Settings[:sources][opennebula][:'data-processing-timeout']
    @timestamp = Time.now.to_i
    @db_client = Michal::DbClient.new logger
  end

  # Updates all data
  #
  def update_data
    @token = Michal::Helpers::OpenNebulaHelper.generate_token(opennebula)

    # updates all types of data
    update_vms
    update_users
    update_datastores
    update_hosts

    # waits for the sidekiq workers to finish
    batch.wait

    # makes new data available and backups old one
    update_collections
  end

  private

  # Updates virtual machine data
  #
  def update_vms
    start_vm = 0
    ids = []
    ondm = Michal::DataLoaders::OpenNebula.new(opennebula, token, logger)

    vms = ondm.load_vms(start_vm, Settings[:sources][opennebula][:'batch-size'])
    until vms.count == 0
      vms.each { |vm| ids << vm.id }
      start_vm = ids.last + 1

      batch << VirtualMachinesWorker.perform_async(opennebula, timestamp, token, ids)

      ids.clear
      vms = ondm.load_vms(start_vm, Settings[:sources][opennebula][:'batch-size'])
    end
  end

  # Updates user data
  #
  def update_users
    batch << UsersWorker.perform_async(opennebula, timestamp, token)
  end

  # Updates datastore data
  #
  def update_datastores
    batch << DatastoresWorker.perform_async(opennebula, timestamp, token)
  end

  # Updates host data
  #
  def update_hosts
    batch << HostsWorker.perform_async(opennebula, timestamp, token)
  end

  # Changes old data collection for new one
  #
  def update_collections
    backup_current
    update_current
  end

  # Backups current data collection
  #
  def backup_current
    result = db_client.read_many(:collections, { name: opennebula, older: { '$size' => Settings[:sources][opennebula][:'backup-size'] } })
    remove_oldest unless result.count == 0

    document = db_client.read_one(:collections, { name: opennebula })

    db_client.update(:collections, { name: opennebula }, {'$push' => { older: document[:current]}}, { upsert: true }) if document
  end

  # Sets current collection to newly obtained data
  #
  def update_current
    db_client.update(:collections, { name: opennebula }, {'$set' => { current: "#{opennebula}-#{timestamp}"}}, { upsert: true })
  end

  # Removes the oldes data collection if more then 5 collections are stored
  #
  def remove_oldest
    document = db_client.update_and_return(:collections, { name: opennebula }, {'$pop' => { older: -1}})
    oldest = document[:older].first

    db_client.drop_collection(oldest)
  end
end
