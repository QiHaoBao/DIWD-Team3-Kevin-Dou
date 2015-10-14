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
        @setUpEvents()

      template: _.template app_toolbar

      setUpEvents: ->
        _.each @$('li[data-event]'), (elem, idx) =>
          # console.log $(elem).data() is an obj: {event: "new"}
          $elem = $(elem)
          $elem.click =>
            @trigger $elem.data().event


      render: ->
        html = @template()
        @$el.append html
        @

