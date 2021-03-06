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
  def vms_for_user(username, from, to, clusters)
    cluster_ids = OneCluster.with(collection: collection).in('CLUSTER.NAME': clusters).map { |document| document['CLUSTER']['ID'] }
    project_operator = { "$project" =>{"VM.DEPLOY_ID" => true, "VM.STATE" => true, "VM.UNAME" => true, "first_history" => { "$slice" => ["$VM.HISTORY_RECORDS.HISTORY", 1] }, "last_history" => {"$slice" => ["$VM.HISTORY_RECORDS.HISTORY", -1] },"VM" => {"HISTORY_RECORDS" => {"HISTORY" => {"RSTIME" => 1,"RETIME" => 1}}}}}
    match_operator = {"$match" => {'VM.UNAME' => username, "VM.DEPLOY_ID" => {"$ne" => nil}, "first_history.RSTIME" => {"$lte" => to}, "$and" => [{"$or" => [{"last_history.RETIME" => {"$gte" => from}}, {"VM.STATE" => {"$ne" => 6}}]}, {"$or" => [{"last_history.RETIME" => 0},{"VM.STATE" => 6}]}],"last_history.CID" => {"$in" => cluster_ids}}}
    another_project_operator = {"$project" => {"VM.DEPLOY_ID" => true}}

    OneVirtualMachine.with(collection: collection).collection.aggregate([project_operator, match_operator, another_project_operator])
  end

  # Finds virtual machine for specified group within time range
  #
  # @param [String] group_name
  # @param [Fixnum] from date in UNIX epoch format
  # @param [Fixnum] to date in UNIX epoch format
  # @return [Array] found virtual machines
  def vms_for_group(group_name, from, to, clusters)
    cluster_ids = OneCluster.with(collection: collection).in('CLUSTER.NAME': clusters).map { |document| document['CLUSTER']['ID'] }
    project_operator = { "$project" =>{"VM.DEPLOY_ID" => true, "VM.STATE" => true, "VM.GNAME" => true, "first_history" => { "$slice" => ["$VM.HISTORY_RECORDS.HISTORY", 1] }, "last_history" => {"$slice" => ["$VM.HISTORY_RECORDS.HISTORY", -1] },"VM" => {"HISTORY_RECORDS" => {"HISTORY" => {"RSTIME" => 1,"RETIME" => 1}}}}}
    match_operator = {"$match" => {'VM.GNAME' => group_name, "VM.DEPLOY_ID" => {"$ne" => nil}, "first_history.RSTIME" => {"$lte" => to}, "$and" => [{"$or" => [{"last_history.RETIME" => {"$gte" => from}}, {"VM.STATE" => {"$ne" => 6}}]}, {"$or" => [{"last_history.RETIME" => 0},{"VM.STATE" => 6}]}],"last_history.CID" => {"$in" => cluster_ids}}}
    another_project_operator = {"$project" => {"VM.DEPLOY_ID" => true}}

    OneVirtualMachine.with(collection: collection).collection.aggregate([project_operator, match_operator, another_project_operator])
  end

  # Returns sum of CPUs for virtual machine in specified time
  #
  # @param [Array] vm_deploy_ids IDs of virtual machines
  # @param [Fixnum] time date in UNIX epoch format
  # @return [Hash] sum of CPUs
  def cpu_sum(vm_deploy_ids, time, clusters)
    cluster_ids = OneCluster.with(collection: collection).in('CLUSTER.NAME': clusters).map { |document| document['CLUSTER']['ID'] }
    project_operator = { "$project" =>{"VM.DEPLOY_ID" => true, "VM.STATE" => true, "VM.TEMPLATE.CPU" => true, "first_history" => { "$slice" => ["$VM.HISTORY_RECORDS.HISTORY", 1] }, "last_history" => {"$slice" => ["$VM.HISTORY_RECORDS.HISTORY", -1] },"VM" => {"HISTORY_RECORDS" => {"HISTORY" => {"RSTIME" => 1,"RETIME" => 1}}}}}
    match_operator = {"$match" => {'VM.DEPLOY_ID' => {'$in' => vm_deploy_ids}, "first_history.RSTIME" => {"$lte" => time}, "$and" => [{"$or" => [{"last_history.RETIME" => {"$gte" => time}}, {"VM.STATE" => {"$ne" => 6}}]}, {"$or" => [{"last_history.RETIME" => 0},{"VM.STATE" => 6}]}],"last_history.CID" => {"$in" => cluster_ids}}}
    group_operator = {'$group' => {'_id' => nil, 'cpu' => { '$sum' => "$VM.TEMPLATE.CPU" } } }
    OneVirtualMachine.with(collection: collection).collection.aggregate([project_operator, match_operator, group_operator])
  end

  # # Returns map of users and sum of CPUs within time range
  # #
  # # @param [Fixnum] from date in UNIX epoch format
  # # @param [Fixnum] to date in UNIX epoch format
  # # @return [Hash] map of users and sum of CPUs
  # def map_user_cpu(from, to)
  #   match_operator = {:$match => {'VM.DEPLOY_ID' => { :$ne => nil },'VM.HISTORY_RECORDS.HISTORY.RSTIME' => {'$lte' => to}, '$or' => [{'VM.HISTORY_RECORDS.HISTORY.RETIME' => {'$gte' => from}}, {'VM.HISTORY_RECORDS.HISTORY.RETIME' => 0}]}}
  #   group_operator = {:$group => {_id: "$VM.UNAME", cpu: { :$sum => "$VM.TEMPLATE.CPU" } } }
  #   OneVirtualMachine.with(collection: collection).collection.aggregate([match_operator, group_operator])
  # end
  #
  # # Returns map of groups and sum of CPUs within time range
  # #
  # # @param [Fixnum] from date in UNIX epoch format
  # # @param [Fixnum] to date in UNIX epoch format
  # # @return [Hash] map of groups and sum of CPUs
  # def map_group_cpu(from, to)
  #   match_operator = {:$match => {'VM.DEPLOY_ID' => { :$ne => nil },'VM.HISTORY_RECORDS.HISTORY.RSTIME' => {'$lte' => to}, '$or' => [{'VM.HISTORY_RECORDS.HISTORY.RETIME' => {'$gte' => from}}, {'VM.HISTORY_RECORDS.HISTORY.RETIME' => 0}]}}
  #   group_operator = {:$group => {_id: "$VM.GNAME", cpu: { :$sum => "$VM.TEMPLATE.CPU" } } }
  #   OneVirtualMachine.with(collection: collection).collection.aggregate([match_operator, group_operator])
  # end
  #
  # # Returns map of users in a group and sum of CPUs within time range
  # #
  # # @param [String] group
  # # @param [Fixnum] from date in UNIX epoch format
  # # @param [Fixnum] to date in UNIX epoch format
  # # @return [Hash] map of users and sum of CPUs
  # def map_user_cpu_in_group(group, from, to)
  #   match_operator = {:$match => {'VM.DEPLOY_ID' => { :$ne => nil }, 'VM.GNAME' => group,'VM.HISTORY_RECORDS.HISTORY.RSTIME' => {'$lte' => to}, '$or' => [{'VM.HISTORY_RECORDS.HISTORY.RETIME' => {'$gte' => from}}, {'VM.HISTORY_RECORDS.HISTORY.RETIME' => 0}]}}
  #   group_operator = {:$group => {_id: "$VM.UNAME", cpu: { :$sum => "$VM.TEMPLATE.CPU" } } }
  #   OneVirtualMachine.with(collection: collection).collection.aggregate([match_operator, group_operator])
  # end
  #
  # # Returns map of users and their virtual machines' IDs within time range
  # #
  # # @param [Fixnum] from date in UNIX epoch format
  # # @param [Fixnum] to date in UNIX epoch format
  # # @return [Hash] map of users and their virtual machines' IDs
  # def map_user_vms(from, to)
  #   match_operator = {:$match => {'VM.DEPLOY_ID' => { :$ne => nil },'VM.HISTORY_RECORDS.HISTORY.RSTIME' => {'$lte' => to}, '$or' => [{'VM.HISTORY_RECORDS.HISTORY.RETIME' => {'$gte' => from}}, {'VM.HISTORY_RECORDS.HISTORY.RETIME' => 0}]}}
  #   group_operator = {:$group => {_id: "$VM.UNAME", vms: { :$addToSet => "$VM.DEPLOY_ID" } } }
  #   OneVirtualMachine.with(collection: collection).collection.aggregate([match_operator, group_operator])
  # end
  #
  # # Returns map of groups and their virtual machines' IDs within time range
  # #
  # # @param [Fixnum] from date in UNIX epoch format
  # # @param [Fixnum] to date in UNIX epoch format
  # # @return [Hash] map of groups and their virtual machines' IDs
  # def map_group_vms(from, to)
  #   match_operator = {:$match => {'VM.DEPLOY_ID' => { :$ne => nil },'VM.HISTORY_RECORDS.HISTORY.RSTIME' => {'$lte' => to}, '$or' => [{'VM.HISTORY_RECORDS.HISTORY.RETIME' => {'$gte' => from}}, {'VM.HISTORY_RECORDS.HISTORY.RETIME' => 0}]}}
  #   group_operator = {:$group => {_id: "$VM.GNAME", vms: { :$addToSet => "$VM.DEPLOY_ID" } } }
  #   OneVirtualMachine.with(collection: collection).collection.aggregate([match_operator, group_operator])
  # end
  #
  # # Returns map of users in a group and their virtual machines' IDs within time
  # # range
  # #
  # # @param [String] group
  # # @param [Fixnum] from date in UNIX epoch format
  # # @param [Fixnum] to date in UNIX epoch format
  # # @return [Hash] map of users and their virtual machines' IDs
  # def map_user_vms_in_group(group, from, to)
  #   match_operator = {:$match => {'VM.DEPLOY_ID' => { :$ne => nil },'VM.GNAME' => group, 'VM.HISTORY_RECORDS.HISTORY.RSTIME' => {'$lte' => to}, '$or' => [{'VM.HISTORY_RECORDS.HISTORY.RETIME' => {'$gte' => from}}, {'VM.HISTORY_RECORDS.HISTORY.RETIME' => 0}]}}
  #   group_operator = {:$group => {_id: "$VM.UNAME", vms: { :$addToSet => "$VM.DEPLOY_ID" } } }
  #   OneVirtualMachine.with(collection: collection).collection.aggregate([match_operator, group_operator])
  # end

  # Returns number of newly started virtual machines within time range
  #
  # @param [Fixnum] from date in UNIX epoch format
  # @param [Fixnum] to date in UNIX epoch format
  # @return [Hash] number of newly started virtual machines
  def new_vm_count(from, to, clusters)
    cluster_ids = OneCluster.with(collection: collection).in('CLUSTER.NAME': clusters).map { |document| document['CLUSTER']['ID'] }
    first_rstime = 'VM.HISTORY_RECORDS.HISTORY.0.RSTIME'
    match_operator = {:$match => {'VM.DEPLOY_ID' => { :$ne => nil }, first_rstime => {'$lte' => to, '$gte' => from}, "VM.HISTORY_RECORDS.HISTORY.0.CID" => {"$in" => cluster_ids} } }
    group_operator = {:$group => { _id: nil, :count => { :$sum => 1 } } }
    OneVirtualMachine.with(collection: collection).collection.aggregate([match_operator, group_operator])
  end

  def vms(from, to, clusters)
    cluster_ids = OneCluster.with(collection: collection).in('CLUSTER.NAME': clusters).map { |document| document['CLUSTER']['ID'] }
    project_operator = { "$project" =>{"VM.DEPLOY_ID" => true, "VM.STATE" => true, "first_history" => { "$slice" => ["$VM.HISTORY_RECORDS.HISTORY", 1] }, "last_history" => {"$slice" => ["$VM.HISTORY_RECORDS.HISTORY", -1] },"VM" => {"HISTORY_RECORDS" => {"HISTORY" => {"RSTIME" => 1,"RETIME" => 1}}}}}
    match_operator = {"$match" => {"VM.DEPLOY_ID" => {"$ne" => nil}, "first_history.RSTIME" => {"$lte" => to}, "$and" => [{"$or" => [{"last_history.RETIME" => {"$gte" => from}}, {"VM.STATE" => {"$ne" => 6}}]}, {"$or" => [{"last_history.RETIME" => 0},{"VM.STATE" => 6}]}],"last_history.CID" => {"$in" => cluster_ids}}}
    another_project_operator = {"$project" => {"VM.DEPLOY_ID" => true, "VM.HISTORY_RECORDS" => true}}

    OneVirtualMachine.with(collection: collection).collection.aggregate([project_operator, match_operator, another_project_operator])
  end

  def map_groups_vms(from, to, clusters)
    cluster_ids = OneCluster.with(collection: collection).in('CLUSTER.NAME': clusters).map { |document| document['CLUSTER']['ID'] }
    project_operator = { "$project" =>{"VM.DEPLOY_ID" => true, "VM.STATE" => true, "VM.GNAME" => true, "first_history" => { "$slice" => ["$VM.HISTORY_RECORDS.HISTORY", 1] }, "last_history" => {"$slice" => ["$VM.HISTORY_RECORDS.HISTORY", -1] },"VM" => {"HISTORY_RECORDS" => {"HISTORY" => {"RSTIME" => 1,"RETIME" => 1}}}}}
    match_operator = {"$match" => {"VM.DEPLOY_ID" => {"$ne" => nil}, "first_history.RSTIME" => {"$lte" => to}, "$and" => [{"$or" => [{"last_history.RETIME" => {"$gte" => from}}, {"VM.STATE" => {"$ne" => 6}}]}, {"$or" => [{"last_history.RETIME" => 0},{"VM.STATE" => 6}]}],"last_history.CID" => {"$in" => cluster_ids}}}
    another_project_operator = {"$project" => {"VM.DEPLOY_ID" => true, "VM.GNAME" => true, "VM.HISTORY_RECORDS" => true}}
    group_operator = {"$group" => {"_id" => "$VM.GNAME", "vms" => {"$addToSet" => "$VM"}}}

    OneVirtualMachine.with(collection: collection).collection.aggregate([project_operator, match_operator, another_project_operator, group_operator])
  end

  def map_users_vms(from, to, clusters)
    cluster_ids = OneCluster.with(collection: collection).in('CLUSTER.NAME': clusters).map { |document| document['CLUSTER']['ID'] }
    project_operator = { "$project" =>{"VM.DEPLOY_ID" => true, "VM.STATE" => true, "VM.UNAME" => true, "first_history" => { "$slice" => ["$VM.HISTORY_RECORDS.HISTORY", 1] }, "last_history" => {"$slice" => ["$VM.HISTORY_RECORDS.HISTORY", -1] },"VM" => {"HISTORY_RECORDS" => {"HISTORY" => {"RSTIME" => 1,"RETIME" => 1}}}}}
    match_operator = {"$match" => {"VM.DEPLOY_ID" => {"$ne" => nil}, "first_history.RSTIME" => {"$lte" => to}, "$and" => [{"$or" => [{"last_history.RETIME" => {"$gte" => from}}, {"VM.STATE" => {"$ne" => 6}}]}, {"$or" => [{"last_history.RETIME" => 0},{"VM.STATE" => 6}]}],"last_history.CID" => {"$in" => cluster_ids}}}
    another_project_operator = {"$project" => {"VM.DEPLOY_ID" => true, "VM.UNAME" => true, "VM.HISTORY_RECORDS" => true}}
    group_operator = {"$group" => {"_id" => "$VM.UNAME", "vms" => {"$addToSet" => "$VM"}}}

    OneVirtualMachine.with(collection: collection).collection.aggregate([project_operator, match_operator, another_project_operator, group_operator])
  end

  def map_vms_runtime(from, to, clusters)
    cluster_ids = OneCluster.with(collection: collection).in('CLUSTER.NAME': clusters).map { |document| document['CLUSTER']['ID'] }
    project_1 = { "$project" =>{"VM.DEPLOY_ID" => true, "VM.STATE" => true, "VM.UNAME" => true, "first_history" => { "$slice" => ["$VM.HISTORY_RECORDS.HISTORY", 1] }, "last_history" => {"$slice" => ["$VM.HISTORY_RECORDS.HISTORY", -1] },"VM" => {"HISTORY_RECORDS" => {"HISTORY" => {"RSTIME" => 1,"RETIME" => 1,"CID" => 1}}}}}
    match_1 = {"$match" => {"VM.DEPLOY_ID" => {"$ne" => nil}, "first_history.RSTIME" => {"$lte" => to}, "$and" => [{"$or" => [{"last_history.RETIME" => {"$gte" => from}}, {"VM.STATE" => {"$ne" => 6}}]}, {"$or" => [{"last_history.RETIME" => 0},{"VM.STATE" => 6}]}],"last_history.CID" => {"$in" => cluster_ids}}}
    unwind_1 = {"$unwind" => "$VM.HISTORY_RECORDS.HISTORY"}
    match_2 = {"$match" => {"VM.DEPLOY_ID" => {"$ne" => nil}, "VM.HISTORY_RECORDS.HISTORY.RSTIME" => {"$lte" => to}, "$and" => [{"$or" => [{"VM.HISTORY_RECORDS.HISTORY.RETIME" => {"$gte" => from}}, {"VM.STATE" => {"$ne" => 6}}]}, {"$or" => [{"VM.HISTORY_RECORDS.HISTORY.RETIME" => 0},{"VM.STATE" => 6}]}],"VM.HISTORY_RECORDS.HISTORY.CID" => {"$in" => cluster_ids}}}
    group_1 = {"$group" => {"_id" => "$VM.DEPLOY_ID", "diffs" => {"$addToSet" => {"$subtract" => [{"$min" => [{"$cond" => { "if" => {"$ne" => ["$VM.HISTORY_RECORDS.HISTORY.RETIME",0]}, "then" => "$VM.HISTORY_RECORDS.HISTORY.RETIME", "else" => to}},to]}, {"$max" => ["$VM.HISTORY_RECORDS.HISTORY.RSTIME",from]}]}}}}
    unwind_2 = {"$unwind" => "$diffs"}
    group_2 = {"$group" => {"_id" => "$_id", "lifetime" => {"$sum":"$diffs"}}}

    OneVirtualMachine.with(collection: collection).collection.aggregate([project_1, match_1, unwind_1, match_2, group_1, unwind_2, group_2])
  end

  def map_vms_allocated_cputime(from, to, clusters)
    cluster_ids = OneCluster.with(collection: collection).in('CLUSTER.NAME': clusters).map { |document| document['CLUSTER']['ID'] }
    project_1 = { "$project" =>{"VM.DEPLOY_ID" => true, "VM.STATE" => true, "VM.UNAME" => true, "VM.TEMPLATE.CPU" => true,"first_history" => { "$slice" => ["$VM.HISTORY_RECORDS.HISTORY", 1] }, "last_history" => {"$slice" => ["$VM.HISTORY_RECORDS.HISTORY", -1] },"VM" => {"HISTORY_RECORDS" => {"HISTORY" => {"RSTIME" => 1,"RETIME" => 1,"CID" => 1}}}}}
    match_1 = {"$match" => {"VM.DEPLOY_ID" => {"$ne" => nil}, "first_history.RSTIME" => {"$lte" => to}, "$and" => [{"$or" => [{"last_history.RETIME" => {"$gte" => from}}, {"VM.STATE" => {"$ne" => 6}}]}, {"$or" => [{"last_history.RETIME" => 0},{"VM.STATE" => 6}]}],"last_history.CID" => {"$in" => cluster_ids}}}
    unwind_1 = {"$unwind" => "$VM.HISTORY_RECORDS.HISTORY"}
    match_2 = {"$match" => {"VM.DEPLOY_ID" => {"$ne" => nil}, "VM.HISTORY_RECORDS.HISTORY.RSTIME" => {"$lte" => to}, "$and" => [{"$or" => [{"VM.HISTORY_RECORDS.HISTORY.RETIME" => {"$gte" => from}}, {"VM.STATE" => {"$ne" => 6}}]}, {"$or" => [{"VM.HISTORY_RECORDS.HISTORY.RETIME" => 0},{"VM.STATE" => 6}]}],"VM.HISTORY_RECORDS.HISTORY.CID" => {"$in" => cluster_ids}}}
    group_1 = {"$group" => {"_id" => "$VM.DEPLOY_ID", "diffs" => {"$addToSet" => {"$multiply" => [{"$subtract" => [{"$min" => [{"$cond" => { "if" => {"$ne" => ["$VM.HISTORY_RECORDS.HISTORY.RETIME",0]}, "then" => "$VM.HISTORY_RECORDS.HISTORY.RETIME", "else" => to}},to]}, {"$max" => ["$VM.HISTORY_RECORDS.HISTORY.RSTIME",from]}]}, "$VM.TEMPLATE.CPU"]}}}}
    unwind_2 = {"$unwind" => "$diffs"}
    group_2 = {"$group" => {"_id" => "$_id", "allocated_cputime" => {"$sum":"$diffs"}}}

    OneVirtualMachine.with(collection: collection).collection.aggregate([project_1, match_1, unwind_1, match_2, group_1, unwind_2, group_2])
  end
end
