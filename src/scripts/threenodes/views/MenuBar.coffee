
define [
  'Underscore',
  'Backbone',
  "text!templates/app_menubar.tmpl.html",
], (_, Backbone, _view_menubar) ->
  #"use strict"

  ###
  The menubar uses jQuery UI Menubar 1.9m6
  No ducumentation available. Get source code from github and look into the Demos
  folder
  ###
  namespace "ThreeNodes",
    MenuBar: class MenuBar extends Backbone.View
      @template: _view_menubar

      initialize: () ->
        # jQuery 1.9m6 menubar
        @$el.menubar
          autoExpand: true

        self = this
        $("a", @$el).click (event) ->
          if $(this).next().is("ul")
            return false

          url = $(this).attr('href').substr(1)
          self.onLinkClick(event, this, url)

        $("#main_file_input_open").change (e) =>
          @trigger("LoadFile", e)

      onLinkClick: (event, link, url) =>
        data_event = $(link).data("event")
        data_attr = $(link).data("eventData")

        if data_event
          #event.preventDefault()

          @trigger(data_event, data_attr)

          # exceptions and special event handling
          switch data_event
            when "ClearWorkspace"
              Backbone.history.navigate("", false)
            when "OpenFile"
              $("#main_file_input_open").click()
          return true

        # sends "normal" urls to the router
        return true

