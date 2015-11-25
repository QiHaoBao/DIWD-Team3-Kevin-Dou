# DIWD-Team3-Kevin-Dou
# online-vistrails-backend
+ translate.py convert JSON to XML file which can be executed by vistrails
+ nohup.out records web message
+ XML2JSON convert XML file to JSON file which can be executed by online vistrails

## Run the backend server
To avoid getting the `cannot connect to x server` error, run with xvfb
```
export DISPLAY=localhost:1.0
nohup xvfb-run -a python rest.py 9018 & 
```

## problems need to solve
+ hardcode: matlabsouce and pythonsouce r/w into result.txt, the path is hardcode.
+ translate.py is too long. split into different python class or store module properties in database

## problems you may face
+ when there's error message like "vistrails output port does not exis", use this command: 
cd .vistrails/
cd autosave/
rm (file)
