michal.controller("NewStatisticController", function($scope, $stateParams, Statistics, Modules, Graphs, changeCase) {
  $scope.sent = false;
  $scope.sendEmail = false;
  $scope.periods = [
    { name: "day", desc: "Daily"},
    { name: "week", desc: "Weekly"},
    { name: "month", desc: "Monthly"},
    { name: "year", desc: "Yearly"},
  ];
  $scope.request = {};
  $scope.request.name = "";
  $scope.request.periodic = false;
  $scope.request.period = "day";
  $scope.error = false;
  $scope.rows = [];
  $scope.maxDate = new Date();
  Graphs.cleanGraphs();

  // allows to add another graph into the statistic
  $scope.addRow = function(){
    $scope.rows.push(
      {url: 'module_picker.html',
      id: _.uniqueId('row-')}
    );
  };

  $scope.removeRow = function(row){
    Graphs.removeGraph(row);
    index = $scope.rows.indexOf(row);
    $scope.rows.splice(index, 1);
  };

  $scope.addRow();

  $scope.selectModule = function(row, module){
    row.url = 'modules/' + changeCase.snakeCase(module) + '_input.html';
    Graphs.newGraph(row);
  };

  // submits the request
  $scope.submit = function(){
    // generates statistic name if doesn't exitst
    if($scope.request.name == ""){
      $scope.request.name = 'Statistic-' + chance.hash({length:5});
    }
    $scope.request.graphs = Graphs.allGraphs();
    // if periodic selected checks whether it's possible
    if($scope.request.periodic){
      for(graph of $scope.request.graphs){
        if(typeof graph['last'] == 'undefined' || graph['last'] == null){
          $scope.error = true;
          return;
        }
      }
    }
    $scope.error = false;

    // converts dates into UNIXC epoch format
    for(graph of $scope.request.graphs){
      if(typeof graph['from'] != 'undefined'){
        graph.from = moment(graph.from).unix()
      }

      if(typeof graph['to'] != 'undefined'){
        graph.to = moment(graph.to).unix()
      }
    }

    console.log($scope.request)
    params = {statistic: $scope.request, authenticity_token: $('meta[name="csrf-token"]').attr('content')}
    Statistics.post(params).then(function(response) {
      $scope.statisticUrl = response.data.url
      $scope.sent = true;
    });
  };

  Modules.getList().then(function(response){
    $scope.modules = response.data;
  });
});
