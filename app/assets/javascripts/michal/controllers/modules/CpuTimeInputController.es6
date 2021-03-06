michal.controller("CpuTimeInputController", function($scope, Modules, Sources, Graphs) {
  console.log($scope.$parent.row);

  $scope.graph = Graphs.get($scope.$parent.row.id);
  $scope.all_opennebula_sources = false;
  $scope.graph.series = [{}];

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
  Modules.one('cpu_time').get().then(function(response) {
    var components = response.data
    $scope.entities = components.entities;
    $scope.periods = components.periods;
    $scope.periods.push({name: null, desc_name: 'Date range'});

    $scope.graph.module = 'cpu_time';
    $scope.graph.entity_type = $scope.entities[0];
    $scope.graph.last = $scope.periods[0].name;
  });

  // makes a request on backend via API to obtain vailable sources
  Sources.list().then(function(response){
    var sources = response.data
    $scope.sources = sources;

    $scope.graph.sources = {};
    $scope.graph.sources.opentsdb = $scope.sources.opentsdb[0];
    $scope.selectedOpenNebulaSources = $scope.sources.opennebula[0];
    $scope.setOpenNebulaSources();
  });
});
