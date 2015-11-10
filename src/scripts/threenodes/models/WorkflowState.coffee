define [
  'Underscore',
  'Backbone',
  'cs!threenodes/utils/Utils',
  'cs!threenodes/models/Context',
  'cs!threenodes/collections/Fields',
], (_, Backbone, Utils) ->
  #"use strict"

  ### workflowState model ###

  namespace "ThreeNodes",
    WorkflowState: class WorkflowState extends Backbone.Model
      defaults:
        # A workflow is considered not abstract unless there is an abstract node in
        # the workflow
        abstract: false

      # Options.nodes
      # Options.context
      initialize: (options) =>
        options = options || {}

        settings =
          test: false
          player_mode: false
        @settings = settings

        # The nodes collection which contains all the nodes in the workflow
        @nodes = new ThreeNodes.NodesCollection(options.nodes, {settings: settings})
        @group_definitions = new ThreeNodes.GroupDefinitions([])


        # helper states, will not save to the server side, nor are they data attrs
        # or bound to the representation
        @workflow_state = false
        @running_nodes = []
        @waiting_nodes = []
        # How many nodes in this workflow are abstract
        # Invariants: will only change when you add/remove abstract node to/of the graph
        # or implement any abstract node in the graph; always non-negative
        @abstractCount = 0

        # Create a group node when selected nodes are grouped
        @group_definitions.bind "definition:created", @nodes.createGroup

        # When a group definition is removed delete all goup nodes using this definition
        @group_definitions.bind "remove", @nodes.removeGroupsByDefinition

        # Create views if the application is not in test mode
        if @settings.test == false
          # Create group definition views when a new one is created
          @group_definitions.bind "add", (definition) =>
            template = ThreeNodes.GroupDefinitionView.template
            tmpl = _.template(template, definition)
            $tmpl = $(tmpl).appendTo("#library")

            view = new ThreeNodes.GroupDefinitionView
              model: definition
              el: $tmpl
            view.bind "edit", @setWorkspaceFromDefinition
            view.render()

        # Increase abstractCount if an abstract node is added
        @nodes.on 'add', (node) =>
          if node instanceof ThreeNodes.nodes.models.AbstractTask &&
            !node.get 'implemented'
              @increaseAbstractCount()

        # Decrease abstractCount if an abstract node is removed
        @nodes.on 'remove', (node) =>
          if node instanceof ThreeNodes.nodes.models.AbstractTask &&
            !node.get 'implemented'
              @decreaseAbstractCount()

        # Decrease abstractCount if an abstract node is implemented
        @nodes.on 'change:implemented', (node) =>
          @decreaseAbstractCount()

        # nested model
        context = new ThreeNodes.Context(options.context)
        @set {context: context}

      decreaseAbstractCount: =>
        @abstractCount--
        if @abstractCount <= 0
          @set 'abstract', false

      increaseAbstractCount: =>
        @abstractCount++
        @set 'abstract', true


      #j start running the workflow if it is not running,
      # run next node if it is
      runWorkflow: =>
        if !@workflow_state
          @startRunningWorkflow()
        else
          @runNext()
        null


      startRunningWorkflow: =>
        # start_nodes: [] of node models
        start_nodes = @nodes.findStartNodesAndMarkReady()
        for node in start_nodes
          node.run()
        @workflow_state = true
        @running_nodes = start_nodes
        null

      runNext: =>
        # get nodes to run
        nodes_to_run = [].concat @waiting_nodes
        @waiting_nodes = []
        for node in @running_nodes
          # get nodes to run next
          nodes_to_run = nodes_to_run.concat node.next()
          # stop current running
          node.stop()
        @running_nodes = []

        # if the end of workflow, change the workflow_state
        if !nodes_to_run.length
          @workflow_state = false
        # else continue running
        else
          # run nodes_to_run
          for node in nodes_to_run
            if node.ready
              node.run()
              @running_nodes.push node
            else
              @waiting_nodes.push node
        null


      clearWorkspace: () =>
        @nodes.clearWorkspace()
        @group_definitions.removeAll()





