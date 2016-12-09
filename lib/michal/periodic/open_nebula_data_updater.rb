# Updates data from OpenNebula sources
#
class Michal::Periodic::OpenNebulaDataUpdater
  attr_reader :batch, :opennebula, :timestamp, :token

  def initialize(opennebula)
    @opennebula = opennebula
    @batch = Michal::Sidekiq::Batch.new Settings[:sources][opennebula][:'data-processing-timeout']
    @timestamp = Time.now.to_i
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
    update_clusters

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
    done_vm_ids = copy_done_vms
    until vms.count == 0
      vms.each { |vm| ids << vm.id }
      start_vm = ids.last + 1

      batch << VirtualMachinesWorker.perform_async(opennebula, timestamp, token, done_vm_ids, ids)

      ids.clear
      vms = ondm.load_vms(start_vm, Settings[:sources][opennebula][:'batch-size'])
    end
  end

  def copy_done_vms
    collection = Collection.where(name: opennebula).first
    return [] unless collection

    ids = OneVirtualMachine.with(collection: collection.current).where('VM.STATE' => 6).map do |vm|
      vm.clone.with(collection: "#{opennebula}-#{timestamp}").save
      vm['VM']['ID'].to_i
    end

    ids.sort
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

  # Updates cluster data
  #
  def update_clusters
    batch << ClustersWorker.perform_async(opennebula, timestamp, token)
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
    num_of_older = Collection.where({ name: opennebula, older: { '$size' => Settings[:sources][opennebula][:'backup-size'] } }).count
    remove_oldest unless num_of_older == 0

    document = Collection.where(name: opennebula).first
    Collection.where(name: opennebula).push(older: document[:current]) if document # upsert?
  end

  # Sets current collection to newly obtained data
  #
  def update_current
    Collection.where(name: opennebula).first_or_create.update(current: "#{opennebula}-#{timestamp}") # upsert?
  end

  # Removes the oldes data collection if more then 5 collections are stored
  #
  def remove_oldest
    oldest = Collection.where(name: opennebula).pop(older: -1)
    Collection.mongo_client[oldest].drop
  end
end
