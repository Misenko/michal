michal.controller("LifetimeInputController", function($scope, Modules, Sources, Graphs) {
  console.log($scope.$parent.row);

  $scope.graph = Graphs.get($scope.$parent.row.id);
  $scope.all_opennebula_sources = false;
  $scope.graph.series = [];

  // handles metric selection
  $scope.updateMetric = function(){
    if(typeof $scope.selectedMetric == 'undefined'){
      return;
    }

    $scope.graph.series = [];
    $scope.graph.series.push({metric: $scope.selectedMetric.name})
  };

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
  Modules.one('lifetime').get().then(function(response) {
    var components = response.data
    $scope.periods = components.periods;
    $scope.periods.push({name: null, desc_name: 'Date range'});
    $scope.metrices = components.metrices;

    $scope.graph.module = 'lifetime';
    $scope.graph.last = $scope.periods[0].name;
    $scope.selectedMetric = $scope.metrices[0];
    $scope.updateMetric();
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
