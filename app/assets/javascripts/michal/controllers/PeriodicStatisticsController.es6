michal.controller("PeriodicStatisticsController", function($scope, $stateParams, Statistics, $state) {
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

  $scope.delete = function(resourceId){
    var params = {authenticity_token: $('meta[name="csrf-token"]').attr('content')}
    Statistics.one(resourceId).remove(params).then(function(response) {
      $state.go('periodicStatistics',{},{reload: true});
    }, function(response){
      console.log("ERROR");
      console.log(response);
    });
  };
});
