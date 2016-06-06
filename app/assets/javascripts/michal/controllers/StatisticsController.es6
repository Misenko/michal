michal.controller("StatisticsController", function($scope, $stateParams, Statistics) {
  Statistics.getList().then(function(response) {
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
