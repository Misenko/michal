michal.controller("InTimeOutputController", function($scope) {
  // converts units when dealing with memory values
  $scope.formatKiloBytes = function(kb,decimals) {
    if(kb == 0) return '0 KB';
    var k = 1024;
    var dm = decimals + 1 || 3;
    var sizes = ['KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    var i = Math.floor(Math.log(kb) / Math.log(k));
    return parseFloat((kb / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
  }

  // creates a graph visualization according to parameters
  $scope.chartFromGraph = function(graph){
    chart = {
      options: {
        chart: {
          zoomType: 'x'
        },
        xAxis: {
          type: 'datetime'
        },
        plotOptions: {
          series: {
            stacking: ''
          },
          area: {
            states: {
              hover: {
                lineWidth: 1
              }
            }
          }
        }
      },
      series: [],
      title: {
        text: graph.entity_type.desc_name + ": " + graph.entity_name
      },
      credits: {
        enabled: true
      },
      loading: false,
      size: {}
    }

    for(serie of graph.series){
      // randomize graph color
      serie.color = chance.color({format: 'rgb'});
      chart.series.push(serie);

      // formates memory values
      if(serie.metric == 'used_memory' || serie.metric == 'allocated_memory'){
        chart.options.yAxis = {
          labels: {
            formatter: function(){
              return $scope.formatKiloBytes(this.value);
            }
          }
        }
      }
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

    // handles multiple axes graphs
    if(graph.options && graph.options.multiple_axis){
      var axes = []
      var i = 0;
      for(serie of graph.series){
        var axis = {
          title: {
            text: serie.name
          }
        }

        if(serie.metric == 'used_memory' || serie.metric == 'allocated_memory'){
          axis.labels ={
            formatter: function(){
              return $scope.formatKiloBytes(this.value);
            }
          }
        }

        axes.push(axis);

        chart.series[i].yAxis = i;
        i++;
      }

      axes[0].opposite = true;
      chart.options.yAxis = axes;
    }

    return chart;
  }

  // assignes unique id to the graph
  $scope.chartId = _.uniqueId('chart_');
  $scope.chart = $scope.chartFromGraph($scope.$parent.graph)
  console.log($scope.chart)
});
