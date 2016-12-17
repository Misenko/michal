michal.controller("CpuTimeOutputController", function($scope) {
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
        },
        drilldown: {
          series: []
        }
      },
      series: [],
      title: {
        text: graph.series[0].name + " of " + _.lowerFirst(graph.entity_type.desc_name) + " from " + moment.unix(graph.from).format('DD.MM.YYYY') + " to " + moment.unix(graph.to).format('DD.MM.YYYY')
      }
    }

    for(var serie of graph.series){
      if(typeof serie['drilldown'] != 'undefined'){
        for(var drilldown of serie['drilldown']){
          chart.options.drilldown.series.push(drilldown)
        }
      }
      chart.series.push(serie);
    }

    // sets points' tooltip
    chart.options.tooltip = {
      pointFormatter: function(){
        return this.series.name + ': ' + $scope.secondsToHours(this.y) + ' CPU hours';
      }
    }

    return chart;
  }

  // assignes unique id to the graph
  $scope.chartId = _.uniqueId('chart_');
  $scope.chart = $scope.chartFromGraph($scope.$parent.graph)
  console.log($scope.chart)
});
