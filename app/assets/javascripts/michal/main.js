var michal = angular.module('michal', ['ngMaterial', 'ngMessages', 'highcharts-ng', 'restangular', 'ui.router', 'templates', 'change-case', 'ngMdIcons', 'ui.gravatar']);

// gravatar module configuration
angular.module('ui.gravatar').config([
  'gravatarServiceProvider', function(gravatarServiceProvider) {
    gravatarServiceProvider.defaults = {
      size     : 50,
      "default": 'retro'
    };
    // Use https endpoint
    gravatarServiceProvider.secure = true;
  }
]);

// angular material design module configuration
angular.module('ngMaterial')
.config(['$mdThemingProvider', function($mdThemingProvider) {
  $mdThemingProvider.theme('default')
  .primaryPalette('amber')
  .accentPalette('deep-orange')
  .warnPalette('brown');
}]);

// ui.router module configuration
// defines which controllers will manage which urls
michal.config(function($stateProvider, $urlRouterProvider, $locationProvider) {
  $stateProvider
  .state('index', {
    url: '/',
    templateUrl: 'index.html'
  })
  .state('statistics' ,{
    url: '/statistics',
    templateUrl: 'statistics.html',
    controller: 'StatisticsController'
  })
  .state('newStatistic' ,{
    url: '/statistics/new',
    templateUrl: function ($stateParams){
      return 'new_statistic.html';
    },
    controller: 'NewStatisticController',
    redirectTo: 'index',
  })
  .state('statistic' ,{
    url: '/statistics/:statisticId',
    templateUrl: 'statistic.html',
    controller: 'StatisticController'
  });

  $urlRouterProvider.otherwise('/');
  $locationProvider.html5Mode({
    enabled: true,
    requireBase: false
  });
});

// restangular module configuration
// used for easy API calls management
michal.config(function(RestangularProvider) {
  RestangularProvider.setBaseUrl('/api/v1');
  RestangularProvider.setRequestSuffix('.json');
  RestangularProvider.setFullResponse(true);
});

// creates a service for modules API in backend
michal.factory('Modules', function(Restangular) {
  return Restangular.service('modules');
});

// creates a service for statistics API in backend
michal.factory('Statistics', function(Restangular) {
  return Restangular.service('statistics');
});

// creates a service for users API in backend
michal.factory('Users', function(Restangular) {
  return Restangular.service('users');
});

// creates a service for sources API in backend
michal.factory('Sources', function(Restangular) {
  return Restangular.withConfig(function(config){
    config.addElementTransformer('sources',true,function(worker){
      worker.addRestangularMethod('list','get', 'list');
      return worker;
    });
  }).service('sources');
});

// creates a service handling graph management
michal.factory('Graphs', function(){
  var graphs = new Map();
  var service = {};

  service.newGraph = function(row){
    graph = {};
    graphs.set(row.id, graph);
  };

  service.removeGraph = function(row){
    graphs.delete(row.id);
  };

  service.get = function(rowId){
    return graphs.get(rowId);
  };

  service.allGraphs = function(){
    return [...graphs.values()];
  };

  service.cleanGraphs = function(){
    graphs = new Map();
  };

  return service;
});

// main frontend controller
michal.controller("ctrl", ['$scope', 'Users', function($scope, Users){
  Users.getList().then(function(response){
    $scope.user = response.data[0];
  }, function(response){
    console.log("ERROR");
    console.log(response);
    $scope.message = response.data.message;
  });
}]);
