# Sidekiq worker class for loading and storing virtual machine data
#
class VirtualMachinesWorker < OpenNebulaWorker
  def perform(opennebula, token, timestamp, ids)
    super opennebula, token, timestamp

    ids.each do |id|
      vm = open_nebula_data_miner.load_vm id
      store OneVirtualMachine, vm
    end
  end
end
