michal.controller("OverallOutputController", function($scope) {
  // FIXME function only in one place
  // converts units when dealing with memory values
  $scope.formatKiloBytes = function(kb,decimals) {
    if(kb == 0) return '0 KB';
    var k = 1024;
    var dm = decimals + 1 || 3;
    var sizes = ['KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    var i = Math.floor(Math.log(kb) / Math.log(k));
    return parseFloat((kb / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
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
              format: '<b>{point.name}</b>: {point.percentage:.1f} %'
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
        var output = this.series.name + ': ';
        if(this.series.userOptions.metric == 'used_memory' || this.series.userOptions.metric == 'allocated_memory'){
          return output + $scope.formatKiloBytes(this.y);
        } else{
          return output + this.y;
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
