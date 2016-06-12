michal.controller("StatisticController", function($scope, $stateParams, Statistics, $state) {
  $scope.statisticId = $stateParams.statisticId;
  $scope.graphs = [];

  Statistics.one($scope.statisticId).get().then(function(response) {
    console.log(response);

    if(response.status != 200){
      $scope.message = response.data.message
      return;
    }

    var graphs = response.data.graphs;
    $scope.name = response.data.name;
    $scope.periodic = response.data.periodic;
    for (var graph of graphs){
      graph.url = 'modules/' + graph.module + '_output.html';
      $scope.graphs.push(graph);
    }
    console.log($scope.graphs);
  }, function(response){
    console.log("ERROR");
    console.log(response);
    $scope.message = response.data.message;
  });

  $scope.delete = function(){
    var params = {authenticity_token: $('meta[name="csrf-token"]').attr('content')}
    Statistics.one($scope.statisticId).remove(params).then(function(response) {
      $state.go('myStatistics');
    }, function(response){
      console.log("ERROR");
      console.log(response);
    });
  };
});
