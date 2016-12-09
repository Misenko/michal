# OpenNebula source class
#
class Michal::Sources::OpenNebula < Michal::Sources::Base
  attr_reader :collection

  def initialize(name, logger)
    super name, logger

    @collection = Collection.where(name: name).first.current
  end

  # Finds virtual machine for specified user within time range
  #
  # @param [String] username
  # @param [Fixnum] from date in UNIX epoch format
  # @param [Fixnum] to date in UNIX epoch format
  # @return [Array] found virtual machines
  def vms_for_user(username, from, to)
    OneVirtualMachine.with(collection: collection).where({'VM.UNAME' => username, 'VM.HISTORY_RECORDS.HISTORY.RSTIME' => {'$lte' => to}, '$or' => [{'VM.HISTORY_RECORDS.HISTORY.RETIME' => {'$gte' => from}}, {'VM.HISTORY_RECORDS.HISTORY.RETIME' => 0}]}).distinct('VM.DEPLOY_ID')
  end

  # Finds virtual machine for specified group within time range
  #
  # @param [String] group_name
  # @param [Fixnum] from date in UNIX epoch format
  # @param [Fixnum] to date in UNIX epoch format
  # @return [Array] found virtual machines
  def vms_for_group(group_name, from, to)
    OneVirtualMachine.with(collection: collection).where({'VM.GNAME' => group_name, 'VM.HISTORY_RECORDS.HISTORY.RSTIME' => {'$lte' => to}, '$or' => [{'VM.HISTORY_RECORDS.HISTORY.RETIME' => {'$gte' => from}}, {'VM.HISTORY_RECORDS.HISTORY.RETIME' => 0}]}).distinct('VM.DEPLOY_ID')
  end

  # Returns sum of CPUs for virtual machine in specified time
  #
  # @param [Array] vm_deploy_ids IDs of virtual machines
  # @param [Fixnum] time date in UNIX epoch format
  # @return [Hash] sum of CPUs
  def cpu_sum(vm_deploy_ids, time)
    match_operator = {'$match' => {'VM.DEPLOY_ID' => {'$in' => vm_deploy_ids}, 'VM.HISTORY_RECORDS.HISTORY.RSTIME' => {'$lte' => time}, '$or' => [{'VM.HISTORY_RECORDS.HISTORY.RETIME' => {'$gte' => time}}, {'VM.HISTORY_RECORDS.HISTORY.RETIME' => 0}] }}
    group_operator = {'$group' => {'_id' => nil, 'cpu' => { '$sum' => "$VM.TEMPLATE.CPU" } } }
    OneVirtualMachine.with(collection: collection).collection.aggregate([match_operator, group_operator])
  end

  # Returns map of users and sum of CPUs within time range
  #
  # @param [Fixnum] from date in UNIX epoch format
  # @param [Fixnum] to date in UNIX epoch format
  # @return [Hash] map of users and sum of CPUs
  def map_user_cpu(from, to)
    match_operator = {:$match => {'VM.DEPLOY_ID' => { :$ne => nil },'VM.HISTORY_RECORDS.HISTORY.RSTIME' => {'$lte' => to}, '$or' => [{'VM.HISTORY_RECORDS.HISTORY.RETIME' => {'$gte' => from}}, {'VM.HISTORY_RECORDS.HISTORY.RETIME' => 0}]}}
    group_operator = {:$group => {_id: "$VM.UNAME", cpu: { :$sum => "$VM.TEMPLATE.CPU" } } }
    OneVirtualMachine.with(collection: collection).collection.aggregate([match_operator, group_operator])
  end

  # Returns map of groups and sum of CPUs within time range
  #
  # @param [Fixnum] from date in UNIX epoch format
  # @param [Fixnum] to date in UNIX epoch format
  # @return [Hash] map of groups and sum of CPUs
  def map_group_cpu(from, to)
    match_operator = {:$match => {'VM.DEPLOY_ID' => { :$ne => nil },'VM.HISTORY_RECORDS.HISTORY.RSTIME' => {'$lte' => to}, '$or' => [{'VM.HISTORY_RECORDS.HISTORY.RETIME' => {'$gte' => from}}, {'VM.HISTORY_RECORDS.HISTORY.RETIME' => 0}]}}
    group_operator = {:$group => {_id: "$VM.GNAME", cpu: { :$sum => "$VM.TEMPLATE.CPU" } } }
    OneVirtualMachine.with(collection: collection).collection.aggregate([match_operator, group_operator])
  end

  # Returns map of users in a group and sum of CPUs within time range
  #
  # @param [String] group
  # @param [Fixnum] from date in UNIX epoch format
  # @param [Fixnum] to date in UNIX epoch format
  # @return [Hash] map of users and sum of CPUs
  def map_user_cpu_in_group(group, from, to)
    match_operator = {:$match => {'VM.DEPLOY_ID' => { :$ne => nil }, 'VM.GNAME' => group,'VM.HISTORY_RECORDS.HISTORY.RSTIME' => {'$lte' => to}, '$or' => [{'VM.HISTORY_RECORDS.HISTORY.RETIME' => {'$gte' => from}}, {'VM.HISTORY_RECORDS.HISTORY.RETIME' => 0}]}}
    group_operator = {:$group => {_id: "$VM.UNAME", cpu: { :$sum => "$VM.TEMPLATE.CPU" } } }
    OneVirtualMachine.with(collection: collection).collection.aggregate([match_operator, group_operator])
  end

  # Returns map of users and their virtual machines' IDs within time range
  #
  # @param [Fixnum] from date in UNIX epoch format
  # @param [Fixnum] to date in UNIX epoch format
  # @return [Hash] map of users and their virtual machines' IDs
  def map_user_vms(from, to)
    match_operator = {:$match => {'VM.DEPLOY_ID' => { :$ne => nil },'VM.HISTORY_RECORDS.HISTORY.RSTIME' => {'$lte' => to}, '$or' => [{'VM.HISTORY_RECORDS.HISTORY.RETIME' => {'$gte' => from}}, {'VM.HISTORY_RECORDS.HISTORY.RETIME' => 0}]}}
    group_operator = {:$group => {_id: "$VM.UNAME", vms: { :$addToSet => "$VM.DEPLOY_ID" } } }
    OneVirtualMachine.with(collection: collection).collection.aggregate([match_operator, group_operator])
  end

  # Returns map of groups and their virtual machines' IDs within time range
  #
  # @param [Fixnum] from date in UNIX epoch format
  # @param [Fixnum] to date in UNIX epoch format
  # @return [Hash] map of groups and their virtual machines' IDs
  def map_group_vms(from, to)
    match_operator = {:$match => {'VM.DEPLOY_ID' => { :$ne => nil },'VM.HISTORY_RECORDS.HISTORY.RSTIME' => {'$lte' => to}, '$or' => [{'VM.HISTORY_RECORDS.HISTORY.RETIME' => {'$gte' => from}}, {'VM.HISTORY_RECORDS.HISTORY.RETIME' => 0}]}}
    group_operator = {:$group => {_id: "$VM.GNAME", vms: { :$addToSet => "$VM.DEPLOY_ID" } } }
    OneVirtualMachine.with(collection: collection).collection.aggregate([match_operator, group_operator])
  end

  # Returns map of users in a group and their virtual machines' IDs within time
  # range
  #
  # @param [String] group
  # @param [Fixnum] from date in UNIX epoch format
  # @param [Fixnum] to date in UNIX epoch format
  # @return [Hash] map of users and their virtual machines' IDs
  def map_user_vms_in_group(group, from, to)
    match_operator = {:$match => {'VM.DEPLOY_ID' => { :$ne => nil },'VM.GNAME' => group, 'VM.HISTORY_RECORDS.HISTORY.RSTIME' => {'$lte' => to}, '$or' => [{'VM.HISTORY_RECORDS.HISTORY.RETIME' => {'$gte' => from}}, {'VM.HISTORY_RECORDS.HISTORY.RETIME' => 0}]}}
    group_operator = {:$group => {_id: "$VM.UNAME", vms: { :$addToSet => "$VM.DEPLOY_ID" } } }
    OneVirtualMachine.with(collection: collection).collection.aggregate([match_operator, group_operator])
  end

  # Returns number of newly started virtual machines within time range
  #
  # @param [Fixnum] from date in UNIX epoch format
  # @param [Fixnum] to date in UNIX epoch format
  # @return [Hash] number of newly started virtual machines
  def new_vm_count(from, to)
    first_rstime = 'VM.HISTORY_RECORDS.HISTORY.0.RSTIME'
    match_operator = {:$match => {'VM.DEPLOY_ID' => { :$ne => nil }, first_rstime => {'$lte' => to, '$gte' => from} } }
    group_operator = {:$group => { _id: nil, :count => { :$sum => 1 } } }
    OneVirtualMachine.with(collection: collection).collection.aggregate([match_operator, group_operator])
  end
end
