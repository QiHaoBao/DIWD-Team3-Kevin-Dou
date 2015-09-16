CMUOnlineWorkflow
=================

# Online VisTrails UI

## Development setup

This will automatically compile coffescript files to javascript, sass to css and haml to html.

* install node.js 0.8.x or later (http://nodejs.org/)
* install compass (http://compass-style.org/install/)
* install grunt (http://gruntjs.com/getting-started#installing-the-cli)
* go to root folder, `npm install -d`
* `node server.js`

## Build/Deploy
`node server.js build`  
A "dist" folder is created including the index.html file  
Copy this folder to serve and deploy the index.html file


## Legacy issues

### Load fields form JSON
It doesn't load directly from JSON file.

How it works:
FileHandler: loadFromJsonData --> @nodes.createNode --> new Node: initialize --> new Fields: initialize --> @addFields(@node.getFields()) --> and Node: getFields is hardcoded. 

This works because at that time node types and its fields are directly related. But this breaks when you add the feature of adding custom fields. 
BTW, field.toJSON() is also overridden so you should change it as well for every new attr you add. 

To work around this, a loadFields method is created on node model. node.getFields() will first call @loadFields() which loads fields of type `Any` from JSON data. Subclass will override getFields() but should still extend `super` to keep these `Any` fields. 

Note that in `_.extend(dest, *source)`, source will override destination if they both have properties of the same name. But here since custom added fields should not exist in hard-coded fields, it is still fine. 

Currently, for each new attribute added to the node model, you should also add it in the loadFields method. 

@todo: use _.omit() in @loadFields() to avoid this.













