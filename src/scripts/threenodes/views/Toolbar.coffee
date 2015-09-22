define [
  'Underscore',
  'Backbone',
  'text!templates/app_toolbar.tmpl.html',
], (_, Backbone, app_toolbar) ->
  #"use strict"

  namespace "ThreeNodes",
    # el should be passed in to the constructor
    Toolbar: class Toolbar extends Backbone.View
      initialize: ->
        @render()

      template: _.template app_toolbar

      render: ->
        html = @template()
        @$el.append html
        @

