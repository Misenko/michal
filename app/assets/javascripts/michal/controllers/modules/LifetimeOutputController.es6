michal.controller("LifetimeOutputController", function($scope) {
  $scope.secondsToHours = function(seconds) {
    return +(seconds / 3600).toFixed(2);
  }

  $scope.chartFromGraph = function(graph){
    var chart = {
      options: {
        chart: {
          type: 'pie'
        },
        plotOptions: {
          pie: {
            dataLabels: {
              allowPointSelect: true,
              cursor: 'pointer',
              enabled: true,
              format: '<b>{point.name}</b>: {point.percentage:.2f} %'
            }
          }
        }
      },
      series: [],
      title: {
        text: graph.series[0].name + " from " + moment.unix(graph.from).format('DD.MM.YYYY') + " to " + moment.unix(graph.to).format('DD.MM.YYYY')
      }
    }

    for(var serie of graph.series){
      chart.series.push(serie);
    }

    // sets points' tooltip
    chart.options.tooltip = {
      pointFormatter: function(){
        if(this.series.userOptions.metric == 'cpu_time'){
          return 'CPU usage: ' + $scope.secondsToHours(this.y) + ' CPU hours';
        } else{
          return 'Nnumber of VMs: ' + this.y;
        }
      }
    }

    return chart;
  }

  // assignes unique id to the graph
  $scope.chartId = _.uniqueId('chart_');
  $scope.chart = $scope.chartFromGraph($scope.$parent.graph)
  console.log($scope.chart)
});
