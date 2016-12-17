require 'opennebula'

# OpenNebula connector class
#
class Michal::DataLoaders::OpenNebula
  attr_reader :client

  def initialize(name, token, logger=nil)
    endpoint = Settings[:sources][name][:endpoint]
    auth = "#{Settings[:sources][name][:username]}:#{token}"
    @client = ::OpenNebula::Client.new auth, endpoint
  end

  # Loads number of virtual machines
  #
  # @param [Fixnum] from offset
  # @param [Fixnum] how_many number of virtual machines to load
  # @return [OpenNebula::VirtualMachinePool] pool of loaded virtual machines
  def load_vms(from, how_many)
    vm_pool = ::OpenNebula::VirtualMachinePool.new client
    Michal::Helpers::OpenNebulaHelper.handle_opennebula_error { vm_pool.info! ::OpenNebula::Pool::INFO_ALL, from, -how_many, ::OpenNebula::VirtualMachinePool::INFO_ALL_VM }

    vm_pool
  end

  # Loads virtual machine
  #
  # @param [Fixnum] id
  # @return [OpenNebula::VirtualMachine] loaded virtual machine
  def load_vm(id)
    load_element(::OpenNebula::VirtualMachine, id)
  end

  # Loads users
  #
  # @return [OpenNebula::UserPool] pool of loaded users
  def load_users
    user_pool = ::OpenNebula::UserPool.new client
    Michal::Helpers::OpenNebulaHelper.handle_opennebula_error { user_pool.info! }

    user_pool
  end

  # Load user
  #
  # @param [Fixnum] id
  # @return [OpenNebula::User] loaded user
  def load_user(id)
    load_element(::OpenNebula::User, id)
  end

  # Loads hosts
  #
  # @return [OpenNebula::HostPool] pool of loaded hosts
  def load_hosts
    host_pool = ::OpenNebula::HostPool.new client
    Michal::Helpers::OpenNebulaHelper.handle_opennebula_error { host_pool.info! }

    host_pool
  end

  # Load host
  #
  # @param [Fixnum] id
  # @return [OpenNebula::Host] loaded host
  def load_host(id)
    load_element(::OpenNebula::Host, id)
  end

  # Loads datastores
  #
  # @return [OpenNebula::DatastorePool] pool of loaded datastores
  def load_datastores
    datastore_pool = ::OpenNebula::DatastorePool.new client
    Michal::Helpers::OpenNebulaHelper.handle_opennebula_error { datastore_pool.info! }

    datastore_pool
  end

  # Load datastore
  #
  # @param [Fixnum] id
  # @return [OpenNebula::Datastore] loaded datastore
  def load_datastore(id)
    load_element(::OpenNebula::Datastore, id)
  end

  # Load cluster
  #
  # @param [Fixnum] id
  # @return [OpenNebula::Cluster] loaded cluster
  def load_cluster(id)
    load_element(::OpenNebula::Cluster, id)
  end

  # Loads clusters
  #
  # @return [OpenNebula::DatastorePool] pool of loaded clusters
  def load_clusters
    cluster_pool = ::OpenNebula::ClusterPool.new client
    Michal::Helpers::OpenNebulaHelper.handle_opennebula_error { cluster_pool.info! }

    cluster_pool
  end

  private

  def load_element(element_class, id)
    element = element_class.new(element_class.build_xml(id), client)
    Michal::Helpers::OpenNebulaHelper.handle_opennebula_error { element.info! }

    element
  end
end
