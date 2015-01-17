#= require underscore
#= require jquery
#= require angular
#= require angular-route
#= require bootstrap
#= require highlight

angular.module('arturiaBinApp', ['ngRoute'])

.controller('RootCtrl', ['$scope', ($scope) ->
	$scope.languages = [
		{
			label: 'Bash'
			stack: 'bash4'
		}
		{
			label: 'C'
			stack: 'gcc4'
		}
		{
			label: 'C++'
			stack: 'g++4'
		}
		{
			label: 'Java'
			stack: 'openjdk7'
		}
		{
			label: 'Go'
			stack: 'go1'
		}
		{
			label: 'Python 2'
			stack: 'python2'
		}
		{
			label: 'Python 3'
			stack: 'python3'
		}
	]
])

.controller('IndexCtrl', ['$location', '$http', '$scope', ($location, $http, $scope) ->
	$scope.samples = [
		{
			stack: 'bash4'
			source: 'echo Hello, world!\n'
			input: ''
		}
		{
			stack: 'gcc4'
			source: '#include <stdio.h>\n\nint main() {\n\tprintf("Hello, world!\\n");\n\treturn 0;\n}\n'
			input: ''
		}
		{
			stack: 'g++4'
			source: '#include <iostream>\n\nusing namespace std;\n\nint main() {\n\tcout << "Hello, world!" << endl;\n\treturn 0;\n}\n'
			input: ''
		}
		{
			stack: 'openjdk7'
			source: ''
			input: ''
		}
		{
			stack: 'go1'
			source: 'package main\n\nimport "fmt"\n\nfunc main() {\n\tfmt.Println("Hello, world!")\n}\n'
			input: ''
		}
		{
			stack: 'python2'
			source: 'print \'Hello, world!\'\n'
			input: ''
		}
		{
			stack: 'python3'
			source: 'print(\'Hello, world!\')\n'
			input: ''
		}
	]
	
	$scope.stack = _.sample _.pluck $scope.languages, 'stack'
	_.extend $scope, _.sample _.where $scope.samples,
		stack: $scope.stack

	$scope.execute = ->
		$http.post("/api/snippets", {
			stack: $scope.stack
			source: $scope.source
			input: $scope.input
		})
		.success((data) ->
			$location.path("/s/#{data.id}")
		)
])

.controller('SnippetViewCtrl', ['$http', '$routeParams', '$scope', ($http, $routeParams, $scope) ->
	$scope.fetch = ->
		$http.get("/api/snippets/#{$routeParams.id}")
		.success((data) ->
			$scope.snippet = data
			$scope.language = _.findWhere($scope.languages,
				stack: $scope.snippet.stack
			).label

			if $scope.snippet.program.status not in ['exited', 'killed', 'failed']
				_.delay =>
					$scope.fetch()
				, 500
		)


	$scope.fetch()
])

.filter('highlight', ['$window', '$sce', ($window, $sce) ->
	(source) ->
		$sce.trustAsHtml $window.hljs.highlightAuto(source or '').value
])

.config(['$routeProvider', '$locationProvider', ($routeProvider, $locationProvider) ->
	$routeProvider
	.when('/', {
		templateUrl: '/tpls/index.html',
		controller: 'IndexCtrl'
	})
	.when('/s/:id', {
		templateUrl: '/tpls/snippetView.html',
		controller: 'SnippetViewCtrl'
	})
	.otherwise({
		redirectTo: '/'
	})
	$locationProvider.html5Mode(yes)
])
