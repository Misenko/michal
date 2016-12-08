# Sidekiq worker class for loading and storing virtual machine data
#
class VirtualMachinesWorker < OpenNebulaWorker
  def perform(opennebula, token, timestamp, done_vm_ids, ids)
    super opennebula, token, timestamp

    ids.each do |id|
      next if done_vm_ids.bsearch { |done_id| id - done_id }

      vm = open_nebula_data_miner.load_vm id
      store OneVirtualMachine, vm
    end
  end
end
