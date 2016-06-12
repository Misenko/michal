michal.controller("PeriodicStatisticsController", function($scope, $stateParams, Statistics) {
  Statistics.periodic().then(function(response) {
    console.log(response);

    if(response.status != 200){
      $scope.message = response.data.message
      return;
    }

    $scope.statistics = response.data
  }, function(response){
    console.log("ERROR");
    console.log(response);
    $scope.message = response.data.message;
  });
});
