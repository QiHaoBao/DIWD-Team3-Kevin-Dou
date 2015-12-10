define [
  'Underscore',
  'Backbone',
  'jquery',
  'libs/namespace',
  "cs!threenodes/utils/Utils",
  'cs!threenodes/models/Workflow',
  'cs!threenodes/collections/Nodes',
  'cs!threenodes/collections/GroupDefinitions',
  'cs!threenodes/views/UI',
  'cs!threenodes/views/Toolbar',
  'cs!threenodes/views/Timeline',
  'cs!threenodes/views/GroupDefinitionView',
  'cs!threenodes/views/Workspace',
  'cs!threenodes/utils/AppWebsocket',
  'cs!threenodes/utils/FileHandler',
  'cs!threenodes/utils/UrlHandler',
  "cs!threenodes/utils/WebglBase",
  'libs/notify.min',
], (_, Backbone) ->
  #### App

  #"use strict"
  namespace "ThreeNodes",
    App: class App
      constructor: (options) ->
        # Default settings
        window.app = @
        settings =
          test: false
          player_mode: false
        @settings = $.extend(settings, options)

        _.extend(@, Backbone.Events)
        
        #loaded_data = JSON.parse($("#dataId").attr('data-jsonString'))
        @workflow = new ThreeNodes.Workflow()
               

        # a stack to store super workflow strs
        @superworkflows = []
        # a stack to store the plain JSON representation of subworkflow instance
        @enteredSubworkflows = []

        # Define renderer mouseX/Y for use in utils.Mouse node for instance
        ThreeNodes.renderer =
          mouseX: 0
          mouseY: 0

        # Disable websocket by default since this makes firefox sometimes throw an exception if the server isn't available
        # this makes the soundinput node not working
        websocket_enabled = false

        # Initialize some core classes
        @url_handler = new ThreeNodes.UrlHandler()
        @socket = new ThreeNodes.AppWebsocket(websocket_enabled)
        @webgl = new ThreeNodes.WebglBase()
        @file_handler = new ThreeNodes.FileHandler(@workflow)
        @workflow = @file_handler.loadFromJsonData($("#dataId").attr('data-jsonString'))
        @file_handler = new ThreeNodes.FileHandler(@workflow)

        # File and url events
        @file_handler.on("ClearWorkspace", () =>
          @clearWorkspace()
        , @)
        @file_handler.on 'JSONLoading', (workflow) =>
          console.log "[file_handler.on 'JSONLoading']"
          @replaceWorkflow(workflow)
        , @

        @url_handler.on("ClearWorkspace", () => @clearWorkspace())
        @url_handler.on("LoadJSON", @file_handler.loadFromJsonData)

        Backbone.Events.on 'openSubworkflow', @openSubworkflow, @
        Backbone.Events.on 'notify', @notify, @

        # Initialize the user interface and timeline
        @initUI()

        
        
        # Initialize the workspace view
        @workspace = new ThreeNodes.Workspace
          el: "#container"
          settings: @settings
        # Make the workspace display the global nodes and connections
        # todo:
        @workspace.render(@workflow.nodes)

        # Start the url handling
        #
        # Enabling the pushState method would require to redirect path
        # for the node.js server and github page (if possible)
        # for simplicity we disable it
        Backbone.history.start
          pushState: false


        return true


      clean: =>
        @file_handler.off null, null, @


      # options.$elem, options.position
      notify: (options) =>
        if !@workflow.get 'abstract'
          options.$elem.notify 'Executing...',
            className: 'success'
            autoHide: true
            autoHideDelay: 1000
            hideAnimation: 'fadeOut'
            hideDuration: 500
            position: options.position


      openSubworkflow: (subworkflow)->
        # inputNames: [], outputNames: []
        # key is field name
        inputNames = (key for key of subworkflow.fields.inputs)
        outputNames = (key for key of subworkflow.fields.outputs)
        @superworkflows.push @file_handler.getLocalJson(true)
        # @note: here run some risks in using the toJSON() method directly
        @enteredSubworkflows.push subworkflow.toJSON()
        # create a new workflow and drop the old one and related ui
        if subworkflow.get 'implementation'
          @loadNewSceneFromJSONString(subworkflow.get 'implementation')
        else
          # create input and output ports
          @createNewWorkflow(null)
          count = 0
          for inputName in inputNames
            @workflow.nodes.createNode({type:'InputPort', x: 3, y: 5 + 50 * count, name: inputName, definition: null, context: null})
            count++
          count = 0
          for outputName in outputNames
            @workflow.nodes.createNode({type:'OutputPort', x: 803, y: 5 + 50 * count, name: outputName, definition: null, context: null})
            count++
        @ui.showBackButton()
        # toggle the tabs to new
        @ui.sidebar.tabsNew()

      setWorkspaceFromDefinition: (definition) =>
        # always remove current edit node if it exists
        if @edit_node
          @edit_node.remove()
          delete @edit_node
          # maybe sync new modifications...

        if definition == "global"
          @workspace.render(@workflow.nodes)
          @ui.breadcrumb.reset()
        else
          # create a hidden temporary group node from this definition
          @edit_node = @workflow.nodes.createGroup
            type: "Group"
            definition: definition
            x: -9999
          @workspace.render(@edit_node.nodes)
          @ui.breadcrumb.set([definition])

      initUI: () =>
        if @settings.test == false
          # Create the main user interface view
          @ui = new ThreeNodes.UI
            el: $("body")
            settings: @settings
            workflow: @workflow


          # Link UI to render events
          @ui.on("render", (options) =>
            @workflow.nodes.render(options))
          @ui.on("renderConnections", (options) =>
            @workflow.nodes.renderAllConnections(options))

          # Setup the main menu events
          @ui.menubar.on("RemoveSelectedNodes", (options) =>
            @workflow.nodes.removeSelectedNodes(options))
          @ui.menubar.on("CreateNewWorkflow", (options) =>
            @createNewWorkflow(options))
          @ui.menubar.on("SaveFile", (options) =>
            @file_handler.saveLocalFile(options))
          @ui.menubar.on("ExportCode", (options) =>
            @file_handler.exportCode(options))
          @ui.menubar.on("LoadJSON", (options) =>
            @file_handler.loadFromJsonData(options))
          @ui.menubar.on("LoadFile", (options) =>
            @file_handler.loadLocalFile(options))
          @ui.menubar.on("ExportImage", (options) =>
            @webgl.exportImage(options))
          @ui.menubar.on("GroupSelectedNodes", (options) =>
            @workflow.group_definitions.groupSelectedNodes(options))
          # Added by Gautam
          @ui.menubar.on("Execute", @execute, @)

          # Setup toolbar events

          # @createNewWorkflow(wf) is expecting diff param than the `new` event is to
          # offer (eventName), so wrap it with another function
          @ui.toolbar.on 'new', =>
            @createNewWorkflow()
          # the `open` event should be set up separately,
          # cause the handler expects some event data
          @ui.toolbar.on 'open', @triggerLoadFile
          @ui.toolbar.on 'save', @file_handler.saveLocalFile
          @ui.toolbar.on 'sync', @file_handler.loadServerFile
          @ui.toolbar.on 'signup', @file_handler.sendToServer
          @ui.toolbar.on 'pipeline', @callWorkflowAPIs
          @ui.toolbar.on 'history', @callWorkflowAPIs
          @ui.toolbar.on 'search', @callWorkflowAPIs
          @ui.toolbar.on 'explore', @callWorkflowAPIs
          @ui.toolbar.on 'provenance', @callWorkflowAPIs
          @ui.toolbar.on 'mashup', @callWorkflowAPIs
          @ui.toolbar.on 'execute', @execute, @


          # Special events
          @ui.on("CreateNode", (options) =>
            @workflow.nodes.createNode(options))
          @initWorkflowEvents()

          #breadcrumb
          @ui.breadcrumb.on("click", @setWorkspaceFromDefinition)

          @ui.on 'back', @backToSuperworkflow, @


        else
          # If the application is in test mode add a css class to the body
          $("body").addClass "test-mode"


        return this


      initWorkflowEvents: =>
        @workflow.nodes.on("nodeslist:rebuild", (options) =>
          @ui.onNodeListRebuild(options)
        , @)

      execute: =>
        if @workflow.get 'abstract'
          @workflow.runWorkflow()
        else
          @file_handler.executeAndSave()

      triggerLoadFile: ->
        # handled in menubar view
        $("#main_file_input_open").click()

      callWorkflowAPIs: (eventName) =>
        data =
          action: eventName
          workflow: @file_handler.getLocalJson(false)
        $.post '/workflows', JSON.stringify(data), (msg) ->
          console.log msg
        return

      backToSuperworkflow: ()->
        # pop from stack the saved superworkflow
        if @superworkflows.length != 0
          implemented = not @workflow.get 'abstract'
          cur = @file_handler.getLocalJson(true)
          superworkflow = @superworkflows.pop()
          @loadNewSceneFromJSONString(superworkflow)
          # find the subworkflow module by nid and set the implementation attr
          # @note: the cid will change each time a new model is created.
          enteredSubworkflow = @enteredSubworkflows.pop()
          @workflow.nodes.get(enteredSubworkflow.nid).set({implementation: cur, implemented: implemented})
          if @superworkflows.length is 0 then @ui.hideBackButton()

      loadNewSceneFromJSONString: (wf)->
        @clearWorkspace()
        @file_handler.loadFromJsonData(wf)


      # replace old one with the new one, deal with all dependencies
      replaceWorkflow: (workflow) =>
        # Going to drop the old workflow model, first remove the corresponding view
        # stop listening events on this model
        @workflow.nodes.off null, null, @
        @workflow = workflow

        # Bind events on the new model
        @initWorkflowEvents();
        @ui.replaceWorkflow(@workflow)
        @file_handler.replaceWorkflow(@workflow)
        # Workspace has coupling with the workflow.nodes
        @workspace.render(workflow.nodes)


      # create a new workflow or use the provided workflow to replace the old one
      createNewWorkflow: (workflow) =>
        workflow = workflow || new ThreeNodes.Workflow()
        @clearWorkspace()
        @replaceWorkflow(workflow)
        @setWorkflowContext()

      setWorkflowContext: () =>
        @ui.dialogView.openDialog()

      clearWorkspace: () =>
        @workflow.clearWorkspace()
        if @ui then @ui.clearWorkspace()
        # @initTimeline()

      # create a new user, when user click 'login' button
      createNewUser: () =>
        @setUserProfile()

      setUserProfile: () =>
        @ui.signupView.openDialog()







