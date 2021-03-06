michal.controller("NewVmCountInputController", function($scope, Modules, Sources, Graphs) {
  console.log($scope.$parent.row);

  $scope.graph = Graphs.get($scope.$parent.row.id);
  $scope.all_opennebula_sources = false;

  // handles source selection
  $scope.setOpenNebulaSources = function(){
    if($scope.all_opennebula_sources){
      $scope.graph.sources.opennebula = $scope.sources.opennebula;
    }else{
      $scope.graph.sources.opennebula = [$scope.selectedOpenNebulaSources];
    }
  }

  // makes a request on backend via API to obtain module's components and
  // creates GUI accordingly
  Modules.one('new_vm_count').get().then(function(response) {
    var components = response.data
    $scope.steps = components.steps;
    $scope.periods = components.periods;
    $scope.periods.push({name: null, desc_name: 'Date range'});

    $scope.graph.module = 'new_vm_count';
    $scope.graph.step = $scope.steps[0].name;
    $scope.graph.last = $scope.periods[0].name;
  });

  // makes a request on backend via API to obtain vailable sources
  Sources.list().then(function(response){
    var sources = response.data
    $scope.sources = sources;

    $scope.graph.series = [{}];
    $scope.graph.sources = {};
    $scope.selectedOpenNebulaSources = $scope.sources.opennebula[0];
    $scope.setOpenNebulaSources();
  });
});
