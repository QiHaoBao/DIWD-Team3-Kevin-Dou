CMUOnlineWorkflow
=================

# Developer Guide

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


## Documentation

### How VisTrials generates various ids

High level:

* nodes of the xml file in different levels go in parallel
* first level down: action id keeps increasing
* second level down: act id keeps increasing (be it `add`, `delete`, or `change`)
* third level down: for diff objs, their ids go in parallel: location, module, function, parameter, they all have their own id system (keeps increasing)
* prevId of action is just the previous action's id. Since it's increasing, just decrease one from the id of itself.
* session: increasing. The process between opening and closing a workflow is a single session.

Qestions: 

* if you change a obj after add, sometimes the id of the obj will increase by 2. Don't know why.
* what is cache of the module, is it always 1?
* what is pos of parameter and fuction? Is is always 0?

One example: 
```
<add id="3" objectId="1" parentObjId="1" parentObjType="module" what="location">
  <location id="1" x="-24.0" y="-42.0" />
</add>
```
How do you interpret this example?
`add` a `location` of id 1 to a `module` of id 1

* objectId refers to the id of location. `what='location'` tells us the object is a `location`
* parentObjId refers to the id of the module obj, it is where we add the `location` to. `parentObjType='module'` tells us that the parentObj is a `module`. 
* `objectId` and `parentObjId` are similar things, while `what` and `parentObjType` are similar things



Another example:
```
<change id="87" newObjId="4" oldObjId="2" parentObjId="2" parentObjType="function" what="parameter">
  <parameter alias="" id="4" name="&lt;no description&gt;" pos="0" type="org.vistrails.vistrails.basic:Integer" val="100" />
</change>
```

Change parameter (with id 2) of function (with id 2) to a new parameter (with id 4)











