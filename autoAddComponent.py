#!/usr/bin/env python
import json

with open("config.json") as fp:
	config_obj = json.load(fp)

comp_name = raw_input("Please input component name: ")
comp_mapping = raw_input("Please input mapping name. (Default: %s): " % comp_name) or comp_name
config_obj['name_mapping'][comp_name] = comp_mapping


comp_ver = raw_input("Please input component version (Default: 2.1): ") or "2.1"
config_obj["version_mapping"][comp_name] = comp_ver


comp_package = "org.vistrails.vistrails."
comp_package += raw_input("Please input package name (Default: basic) ") or "basic"
config_obj["package_mapping"][comp_name] = comp_package


in_count = input("Please input the number of in ports: ") or 0
out_count = input("Please input the number of out ports: ") or 0

in_port_name = [""] * in_count
if (in_count > 0):
	keep_default = raw_input("Keep Default name for in port?[Y/N]: ") or 'Y'
	if (keep_default == 'N'):
		for i in range(in_count):
			in_port_name[i] = raw_input("Please input the name of in port#%d: " % i)
	else:
		if (in_count == 1):
			in_port_name =["in"]
		elif (in_count > 1):
			for i in range(in_count):
				in_port_name[i] = "in" + str(i)
	
out_port_name = [""] * out_count
if (out_count > 0):
	keep_default = raw_input("Keep Default name for out port?[Y/N]: ") or 'Y'
	if (keep_default == 'N'):
		for i in range(out_count):
			out_port_name[i] = raw_input("Please input the name of out port#%d: " % i)
	else:
		if (out_count == 1):
			out_port_name =["out"]
		elif (out_count > 1):
			for i in range(out_count):
				out_port_name[i] = "out" + str(i)


#= raw_input("Please input component name: ")
#comp_mapping = raw_input("Please input mapping name. (Default: %s): " % comp_name) or comp_name
#config_obj['name_mapping'][comp_name] = comp_mapping


#with open("config.json", "w") as fp:
#	json.dump(config_obj, fp, indent=4)

