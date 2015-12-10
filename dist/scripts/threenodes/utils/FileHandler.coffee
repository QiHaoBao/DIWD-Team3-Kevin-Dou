define [
	'Underscore',
	'Backbone',
	'cs!threenodes/utils/Utils',
	'cs!threenodes/utils/CodeExporter',
	"libs/BlobBuilder.min",
	"libs/FileSaver.min",
	"libs/json2",
], (_, Backbone, Utils) ->
	#"use strict"

	namespace "ThreeNodes",
		FileHandler: class FileHandler extends Backbone.Events
			constructor: (@workflow) ->
        		_.extend(FileHandler::, Backbone.Events)

      replaceWorkflow: (workflow) =>
      	@workflow = workflow

			saveLocalFile: () =>
				bb = new BlobBuilder()
				result_string = @getLocalJson()
				bb.append(result_string)
				fileSaver = saveAs(bb.getBlob("application/json;charset=utf-8"), "nodes.json")
				# console.log fileSaver

			exportCode: () =>
				# get the json export and convert it to code
				json = @getLocalJson(false)
				exporter = new ThreeNodes.CodeExporter()
				res = exporter.toCode(json)

				bb = new BlobBuilder()
				bb.append(res)
				fileSaver = saveAs(bb.getBlob("text/plain;charset=utf-8"), "nodes.js")

			# defalt will return json_str
			getLocalJson: (stringify = true) =>
				res =
					uid: @workflow.nodes.indexer.getUID(false)
					workflow: @workflow.toJSON()
					nodes: jQuery.map(@workflow.nodes.models, (n, i) -> n.toJSON())
					connections: jQuery.map(@workflow.nodes.connections.models, (c, i) -> c.toJSON())
					groups: jQuery.map(@workflow.group_definitions.models, (g, i) -> g.toJSON())

				if stringify
					return JSON.stringify(res)
				else
					return res

			# todo
			loadFromJsonData: (txt) =>
				# Parse the json string
				loaded_data = JSON.parse(txt)

				# load workflow model
				workflow = new ThreeNodes.Workflow(loaded_data.workflow)

				@trigger 'JSONLoading', workflow

	        # First recreate the group definitions
				if loaded_data.groups
					for grp_def in loaded_data.groups
						workflow.group_definitions.create(grp_def)

    	    # Create the nodes
				for node in loaded_data.nodes
					if node.type != "Group"
					# Create a simple node
						workflow.nodes.createNode(node)
					else
    	        # If the node is a group we first need to get the previously created group definition
						def = workflow.group_definitions.getByGid(node.definition_id)
						if def
							node.definition = def
							grp = workflow.nodes.createGroup(node)
						else
							console.log "can't find the GroupDefinition: #{node.definition_id}"

			# Create the connections
				for connection in loaded_data.connections
					workflow.nodes.createConnectionFromObject(connection)

				workflow.nodes.indexer.uid = loaded_data.uid
				delay = (ms, func) => setTimeout func, ms
				delay 1, () =>
					workflow.nodes.renderAllConnections()

				workflow

			loadLocalFile: (e) =>
				# Clear the workspace first
				@trigger("ClearWorkspace")
				# Load the file
				file = e.target.files[0]
				reader = new FileReader()
				self = this
				reader.onload = (e) ->
					txt = e.target.result
					console.log(txt)
					# Call loadFromJsonData when the file is loaded
					self.loadFromJsonData(txt)
				reader.readAsText(file, "UTF-8")

			loadServerFile: () =>
				# Clear the workspace first
				@trigger("ClearWorkspace")
				console.log "calling [loadServerFile]"
				self = this
				$.ajax
 					type: "GET"
 					url: "/vistrails/load"
 					data:
 						workflowId: $("#dataId").attr('data-workflowId')

 					dataType: 'json'
 					
 					success: (response) ->
 						console.log "success"
 						console.log response
 						console.log typeof(response)
 						console.log JSON.stringify(response)
 						self.loadFromJsonData(JSON.stringify(response))

 					error: (response) ->
 						console.log "error"
 						console.log response
 						console.log typeof(response)
 						console.log JSON.stringify(response)
 						self.loadFromJsonData(JSON.stringify(response))


		# Execute event to give output
			executeAndSave: () =>
				#convert to JSON and send to Server
				json = @getLocalJson(false)
				res = @sendToServer(json)
				console.log res.responseText
				bb = new BlobBuilder()
				bb.append(res.responseText)
				fileSaver = saveAs(bb.getBlob("text/html;charset=utf-8"), "result.txt")

		# Send Data to the server
			sendToServer: (workflow) =>
				console.log "sending to server"
				data =
					action: 'execute'
					workflow: workflow
				$.ajax
					type: "POST"
					url: "/vistrails/save" #"http://einstein.sv.cmu.edu:9018/vistrails"
					data: 
						workflowId: $("#dataId").attr('data-workflowId')
						jsonString: @getLocalJson()
					dataType: 'json'
					success: (response) ->
						console.log "success"
					error: (xml) ->
						console.log "error case"
						console.log xml
						return "Error from Server"




