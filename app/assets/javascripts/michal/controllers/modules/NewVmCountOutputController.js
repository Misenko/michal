michal.controller("NewVmCountOutputController", function($scope) {
  // creates a graph visualization according to parameters
  $scope.chartFromGraph = function(graph){
    chart = {
      options: {
        chart: {
          type: 'line'
        },
        xAxis: {
          type: 'category'
        },
        yAxis: {
          title: {
            text: 'No. of new virtual machines'
          }
        },
        legend: {
            enabled: false
        },
        plotOptions: {
          line: {
            dataLabels: {
              enabled: true
            },
            enableMouseTracking: false
          }
        }
      },
      series: [],
      title: {
        text: "Number of new virtual machines from " + moment.unix(graph.from).format('DD.MM.YYYY') + " to " + moment.unix(graph.to).format('DD.MM.YYYY')
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

      chart.options.xAxis.title = {
        enabled: true,
        text: serie.name
      }
    }

    return chart;
  }

  // assignes unique id to the graph
  $scope.chartId = _.uniqueId('chart_');
  $scope.chart = $scope.chartFromGraph($scope.$parent.graph)
  console.log($scope.chart)
});
