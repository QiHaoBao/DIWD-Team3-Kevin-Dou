define [
  'Underscore',
  'Backbone',
  "text!templates/node.tmpl.html",
  'cs!threenodes/views/FieldsView',
  "libs/jquery.contextMenu",
  "jquery.ui",
  'cs!threenodes/utils/Utils',
], (_, Backbone, _view_node_template) ->
  #"use strict"

  ### Node View ###
  namespace "ThreeNodes",
    NodeView: class NodeView extends Backbone.View
      className: "node"

      initialize: (options) ->
        # Setup the view DOM element
        @makeElement()

        @selectedField = null

        # Initialize mouse events
        if !options.isSubNode
          @makeDraggable()
        @initNodeClick()
        @initTitleClick()

        # Initialize the fields view
        @fields_view = new ThreeNodes.FieldsView
          node: @model
          collection: @model.fields
          el: $(".options", @$el)

        # Bind events
        @model.on('change', @render)
        #@model.on('postInit', @postInit)
        @model.on('remove', () => @remove())
        @model.on("node:computePosition", @computeNodePosition)
        @model.on("node:renderConnections", @renderConnections)
        @model.on("node:showAnimations", @highlighAnimations)
        @model.on("node:addSelectedClass", @addSelectedClass)
        @model.on("run", @run)
        @model.on("stop", @stop)
        #j the FieldsView class seems to be an unnecessary layer
        @fields_view.collection.on "select", @onFieldSelected, @

        # Render the node and "post init" the model
        @render()

        #@model.postInit()

      onFieldSelected: (field) ->
        @selectedField = field

      #j add css class to indicate this node run
      run: =>
        @$el.addClass("state-run")

      #j remove css class of running
      stop: =>
        @$el.removeClass("state-run")

      # Note some actions are repeated in @render
      makeElement: () =>
        # Compile the template file
        @template = _.template(_view_node_template, @model)
        @$el.html(@template)
        @$('.type').hide()

        # Add the node group name as a class to the node element for easier styling
        @$el.addClass("type-" + @model.constructor.group_name)

        # Add other dynamic classes
        @$el.addClass("node-" + @model.typename())

      render: () =>
        @$el.css
          left: parseInt @model.get("x")
          top: parseInt @model.get("y")
        @$el.find("> .head span").text(@model.get("name"))
        @$el.find("> .head span").show()
        if @model.get 'name' is @model.typename()
          @$('.type').show()

      highlighAnimations: () =>
        nodeAnimation = false
        for propTrack in @model.anim.objectTrack.propertyTracks
          $target = $('.inputs .field-' + propTrack.name , @$el)
          if propTrack.anims.length > 0
            $target.addClass "has-animation"
            nodeAnimation = true
          else
            $target.removeClass "has-animation"
        if nodeAnimation == true
          @$el.addClass "node-has-animation"
        else
          @$el.removeClass "node-has-animation"
        true

      addSelectedClass: () =>
        @$el.addClass("ui-selected")

      renderConnections: () =>
        @model.fields.renderConnections()
        if @model.nodes
          _.each @model.nodes.models, (n) ->
            n.fields.renderConnections()

      computeNodePosition: () =>
        pos = $(@el).position()
        offset = $("#container-wrapper").offset()
        @model.set
          x: pos.left + $("#container-wrapper").scrollLeft()
          y: pos.top + $("#container-wrapper").scrollTop()

      remove: () =>
        Backbone.Events.off null, null, @
        $(".field", this.el).destroyContextMenu()
        if @$el.data("draggable") then @$el.draggable("destroy")
        $(this.el).unbind()
        @undelegateEvents()
        if @fields_view then @fields_view.remove()
        delete @fields_view
        super

      #j refresh the nodesidebarview on every click, continuous selection
      # or not
      initNodeClick: () ->
        self = this
        $(@el).click (e) ->
          if e.metaKey == false
            $( ".node" ).removeClass("ui-selected")
            $(this).addClass("ui-selecting")
          else
            if $(this).hasClass("ui-selected")
              $(this).removeClass("ui-selected")
            else
              $(this).addClass("ui-selecting")
          selectable = $("#container").data("selectable")
          selectable.refresh()
          #j will fire the selectablestop event, initializing NodeSidebarView
          selectable._mouseStop(null)
          self.model.fields.renderSidebar()
          #j fire event to render NodeSidebarView
          # 1. thanks to event bubbling mechanism, @selectedField can
          # be set before the click event bubbles up from the fieldButton to
          # nodeView
          # 2. the selectablestop event fires first, so its handler will
          # be executed first than that of renderSiedebar. Thus the view will
          # be initialized before we call render on it
          Backbone.Events.trigger "renderSidebar", self.selectedField
          self.selectedField = null
        return @




      # dblclick to change the name of the node
      # will show type info if it is diff from the node name
      initTitleClick: () ->
        self = this
        @$el.find("> .head span").dblclick (e) ->
          that = this
          e.stopPropagation()
          prev = $(this).html()
          self.$el.find("> .head").append("<input type='text' />")
          $(this).hide()
          # one is span, the other one is input, they are different
          $input = self.$el.find("> .head input", )
          $input.val(prev)

          apply_input_result = () ->
            self.model.set('name', $input.val())
            # if name doesn't change, just restore the span
            if $input.val() is self.model.get 'name'
              $(that).show()
            # if name is diff from node type, show the type
            if $input.val() isnt self.model.typename()
              self.$el.find('.type').show()
            $input.remove()

          $input.blur (e) ->
            apply_input_result()

          $("#graph").click (e) ->
            apply_input_result()

          $input.keydown (e) ->
            # on enter
            if e.keyCode == 13
              apply_input_result()
        return @

      makeDraggable: () =>
        self = this

        nodes_offset = {top: 0, left: 0}
        selected_nodes = $([])

        $(this.el).draggable
          start: (ev, ui) ->
            if $(this).hasClass("ui-selected")
              selected_nodes = $(".ui-selected").each () ->
                $(this).data("offset", $(this).offset())
            else
              selected_nodes = $([])
              $(".node").removeClass("ui-selected")
            nodes_offset = $(this).offset()
          drag: (ev, ui) ->

            dt = ui.position.top - nodes_offset.top
            dl = ui.position.left - nodes_offset.left
            selected_nodes.not(this).each () ->
              el = $(this)
              offset = el.data("offset")
              dx = offset.top + dt
              dy = offset.left + dl
              el.css
                top: dx
                left: dy
              el.data("object").trigger("node:computePosition")
              el.data("object").trigger("node:renderConnections")

            self.renderConnections()
          stop: () ->
            selected_nodes.not(this).each () ->
              el = $(this).data("object")
              el.trigger("node:renderConnections")
            self.computeNodePosition()
            self.renderConnections()
        return @
