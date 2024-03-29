define [
  'Underscore',
  'Backbone',
  "text!templates/field_context_menu.tmpl.html",
  "text!templates/node_context_menu.tmpl.html",
  "text!templates/app_ui.tmpl.html",
  'cs!threenodes/views/sidebar/Sidebar',
  'cs!threenodes/views/MenuBar',
  'cs!threenodes/views/Breadcrumb',
  'cs!threenodes/views/DialogView',
  'cs!threenodes/views/SignupView',
  'cs!threenodes/models/Context',
  "RequestAnimationFrame",
  "Raphael",
  "libs/jquery.contextMenu",
  "jquery.ui",
  "libs/jquery.transform2d",
  "libs/jquery-scrollview/jquery.scrollview",
  "libs/jquery.layout-latest",
], (_, Backbone, _view_field_context_menu, _view_node_context_menu, _view_app_ui) ->
  ### UI View ###

  namespace "ThreeNodes",
    UI: class UI extends Backbone.View

      # Background svg used to draw the connections
      @svg: false
      @connecting_line = false

      initialize: (options) ->
        super

        @settings = options.settings
        @is_grabbing = false

        @workflow = options.workflow


        # Bind events
        $(window).resize(@onUiWindowResize)

        # Create the ui dom elements from template
        ui_tmpl = _.template(_view_app_ui, {})
        @$el.append(ui_tmpl)

        # Create breadcrumb view (for selecting current group/workspace)
        @breadcrumb = new ThreeNodes.Breadcrumb({el: $("#breadcrumb")})

        # Setup SVG for drawing connections
        ThreeNodes.UI.svg = Raphael("graph", 4000, 4000)
        ThreeNodes.UI.connecting_line = ThreeNodes.UI.svg.path("M0 -20 L0 -20").attr
          stroke: "#fff"
          'stroke-dasharray': "-"
          fill: "none"
          opacity: 0
          'stroke-width': "6"

        # Setup the sidebar and menu subviews
        @sidebar = new ThreeNodes.Sidebar({el: $("#sidebar")})
        @initMenubar()
        @initToolbar()
        @dialogView = new ThreeNodes.DialogView(model: @workflow.get('context'))
        @signupView = new ThreeNodes.SignupView(model: @workflow)
        @$('#dialog').append(@dialogView.render().el)
        @$('#dialog').append(@signupView.render().el)

        # Set the layout and show application
        @initLayout()
        @initDrop()
        @showApplication()

        # Fire the first resize event
        @onUiWindowResize()

        # Start main render loop
        @animate()

      onNodeListRebuild: (nodes) =>
        if @timeoutId
          clearTimeout(@timeoutId)
        # add a little delay since the event is fired multiple time on file load
        onTimeOut = () =>
          @sidebar.render(nodes)
        @timeoutId = setTimeout(onTimeOut, 10)

      initDrop: () =>
        self = this
        # Setup the drop area for the draggables created above
        $("#container").droppable
          accept: "#tab-new a.button, #library .definition"
          activeClass: "ui-state-active"
          hoverClass: "ui-state-hover"
          drop: (event, ui) ->
            offset = $("#container-wrapper").offset()
            definition = false

            if ui.draggable.hasClass("definition")
              nodename = "Group"
              container =  $("#library")
              definition = ui.draggable.data("model")
              offset.left -= container.offset().left
            else
              nodename = ui.draggable.attr("rel")
              container =  $("#sidebar .ui-layout-center")

            dx = ui.position.left + $("#container-wrapper").scrollLeft() - offset.left - 10
            dy = ui.position.top + $("#container-wrapper").scrollTop() - container.scrollTop() - offset.top
            #debugger
            self.trigger("CreateNode", {type: nodename, x: dx, y: dy, definition: definition, context: self.workflow.get('context').toJSON()})
            $("#sidebar").show()

        return this

      replaceWorkflow: (workflow)->
        @workflow = workflow
        @dialogView.remove()
        @dialogView = new ThreeNodes.DialogView(model: @workflow.get('context'))
        @$('#dialog').append(@dialogView.render().el)
        # using existing dom element for the view el has a drawback: when you remove
        # the subview, it will remove the corresponding dom element, and you can't
        # create another subview to replace it for the dom element has gone already



      clearWorkspace: () =>
        # Remove the nodes attributes from the sidebar
        @sidebar.clearWorkspace()

      # Setup menubar
      initMenubar: () =>
        menu_tmpl = _.template(ThreeNodes.MenuBar.template, {})
        $menu_tmpl = $(menu_tmpl).prependTo("body")
        @menubar = new ThreeNodes.MenuBar
          el: $menu_tmpl

        @menubar.on "ToggleAttributes", () => if @layout then @layout.toggle("west")
        @menubar.on "ToggleLibrary", () => if @layout then @layout.toggle("east")
        @menubar.on "ToggleTimeline", () => if @layout then @layout.toggle("south")

        return this

      initToolbar: () ->
        @toolbar = new ThreeNodes.Toolbar
          el: $('#timeline')

      # Setup layout
      initLayout: () =>
        @makeSelectable()
        @setupMouseScroll()
        @initContextMenus()
        @initBottomToolbox()
        @initDisplayModeSwitch()

        @layout = $('body').layout
          scrollToBookmarkOnLoad: false
          center:
            size: "100%"
          north:
            closable: false
            resizable: false
            slidable: false
            showOverflowOnHover: true
            size: 24
            resizerClass: "ui-layout-resizer-hidden"
            spacing_open: 0
            spacing_closed: 0
          east:
            minSize: 220
            initClosed: true
            onresize: (name, pane_el, state, opt, layout_name) =>
              @onUiWindowResize()
            onopen: (name, pane_el, state, opt, layout_name) =>
              @onUiWindowResize()
            onclose: (name, pane_el, state, opt, layout_name) =>
              @onUiWindowResize()
          west:
            minSize: 220
          south:
            minSize: 48
            size: 48
            onopen: (name, pane_el, state, opt, layout_name) =>
              @trigger("timelineResize", pane_el.innerHeight())
              @onUiWindowResize()
            onclose: (name, pane_el, state, opt, layout_name) =>
              @trigger("timelineResize", pane_el.innerHeight())
              @onUiWindowResize()
            onresize: (name, pane_el, state, opt, layout_name) =>
              @trigger("timelineResize", pane_el.innerHeight())
              @onUiWindowResize()

        # Set timeline height
        @trigger("timelineResize", 48)
        return this

      # Handle the nodes selection
      makeSelectable: () ->
        $("#container")
          .selectable
            filter: ".node"
            stop: (event, ui) =>
              $selected = $(".node.ui-selected")
              nodes = []
              anims = []
              # Add the nodes and their anims container to some arrays
              $selected.each () ->
                ob = $(this).data("object")
                ob.anim.objectTrack.name = ob.get("name")
                anims.push(ob.anim)
                nodes.push(ob)
              # Display the selected nodes in the sidebar
              @sidebar.renderNodes(nodes)
              # Display the selected nodes in the timeline
              @trigger("selectAnims", anims)
            unselected: (event, ui)->
              $(ui.unselected).find('*').blur()

          .click (e) ->
            $(@).find("*").not(e.target).blur()
        return @

      setupMouseScroll: () =>
        @scroll_target = $("#container-wrapper")

        # Return true if the click is made on the background, false otherwise
        is_from_target = (e) ->
          if e.target == $("#graph svg")[0]
            return true
          return false

        # Disable the context menu on the container so that we can drag with right click
        @scroll_target.bind "contextmenu", (e) -> return false

        # Handle start drag
        @scroll_target.mousedown (e) =>
          # Init drag only if middle or right click AND if the target element is the svg
          if is_from_target(e) && (e.which == 2 || e.which == 3)
            @is_grabbing = true
            @xp = e.pageX
            @yp = e.pageY
            return false

        # Hande drag when the mouse move
        @scroll_target.mousemove (e) =>
          if is_from_target(e) && (@is_grabbing == true)
            @scrollTo(@xp - e.pageX, @yp - e.pageY)
            @xp = e.pageX
            @yp = e.pageY

        # Handle stop drag
        @scroll_target.mouseout => @is_grabbing = false
        @scroll_target.mouseup (e) =>
          if is_from_target(e) && (e.which == 2 || e.which == 3)
            @is_grabbing = false

        return true

      scrollTo: (dx, dy) =>
        x = @scroll_target.scrollLeft() + dx
        y = @scroll_target.scrollTop() + dy
        @scroll_target.scrollLeft(x).scrollTop(y)

      switchDisplayMode: () =>
        @setDisplayMode(!@settings.player_mode)
        return this

      initDisplayModeSwitch: () =>
        $button = $("<div id='display-mode-switch'>Back</div>")
        $button.hide()
        $("body").append($button)
        $("#display-mode-switch").click (e) =>
          @trigger 'back'

      showBackButton: ->
        $('#display-mode-switch').show()

      hideBackButton: ->
        $('#display-mode-switch').hide()


      # Setup the bottom right dom container
      initBottomToolbox: () =>
        $("body").append("<div id='bottom-toolbox'></div>")
        $container = $("#bottom-toolbox")
        @initResizeSlider($container)

      # Initialize the little node zoom slider
      initResizeSlider: ($container) =>
        $container.append("<div id='zoom-slider'></div>")
        scale_graph = (val) ->
          factor = val / 100
          $("#container").css('transform', "scale(#{factor}, #{factor})")

        $("#zoom-slider").slider
          min: 25
          step: 25
          value: 100
          change: (event, ui) -> scale_graph(ui.value)
          slide: (event, ui) -> scale_graph(ui.value)

      initContextMenus: () =>
        menu_field_menu = _.template(_view_field_context_menu, {})
        $("body").append(menu_field_menu)

        node_menu = _.template(_view_node_context_menu, {})
        $("body").append(node_menu)

      # Display the app and hide the intro
      showApplication: () =>
        delay_intro = 500

        # Display/hide with some delay
        $("body > header").delay(delay_intro).hide()
        $("#sidebar").delay(delay_intro).show()
        $("#container-wrapper").delay(delay_intro).show()

        # Render the connections if needed
        @trigger("renderConnections")

      # Function called when the window is resized and if some panels are closed/opened/resized
      onUiWindowResize: () =>
        # Default minimum margins
        margin_bottom = 20
        margin_right = 25

        # Calculate the bottom and right margins if the corresponding panels are not closed
        if @layout.south.state.isClosed == false then margin_bottom += $("#timeline").innerHeight()
        if @layout.east.state.isClosed == false then margin_right += $("#library").innerWidth()

        # Apply the margins to some DOM elements
        $("#bottom-toolbox").attr("style", "bottom: #{margin_bottom}px !important; right: #{margin_right}px")
        $("#webgl-window").css
          right: margin_right

      animate: () =>
        @trigger("render")
        requestAnimationFrame( @animate )
