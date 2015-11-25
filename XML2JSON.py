import xon
import json
import pprint
from argparse import ArgumentParser

# command line arguments
# sample commands:
#   python XML2JSON.py -i XML/int_2.xml -o JSON/output.xml
parser = ArgumentParser(description="XML to JSON converter")
# specify input file
parser.add_argument('--infile', '-i',
                    help="input XML file",
                    dest='infile_name',
                    required=True,
                    type=str)
# specify output file
parser.add_argument('--outfile', '-o',
                    help="output XML file",
                    default='output.json',
                    dest='outfile_name',
                    required=False,
                    type=str)

args = parser.parse_args()

with open(args.infile_name) as f:
    xml_data = f.read().replace('\n', '')

# json_data is type 'dict'
json_data = xon.loads(xml_data)
# pprint.pprint(json_data)

# actions - a list
actions = json_data['vistrail']['action']

output = {}

output['connections'] = []
output['uid'] = 0
output['groups'] = []
# workflow
output['workflowState'] = {}
output['workflowState']['abstract'] = False
output['workflowState']['context'] = {}
# workflow/context
output['workflowState']['context']['description'] = ""
output['workflowState']['context']['author'] = ""
output['workflowState']['context']['affiliation'] = ""
output['workflowState']['context']['purpose'] = ""
output['workflowState']['context']['keywords'] = ""
output['workflowState']['context']['constraints'] = []

# nodes - a list
# the actual part
output['nodes'] = []

def generate_integer_json(x, y, id):
    # the goal result
    # {} - dict
    # [] - list
    # node - a dict
    node = {}
    node['anim'] = False
    node['name'] = "Integer"
    node['fields'] = {}
    node['fields']['out'] = [{'type': 'Float', 'name': 'out', 'custom': False},
                             {'type': 'String', 'name': 'out0', 'val': 0, 'custom': False}]
    node['fields']['in'] = [{'type': 'Float', 'name': 'in', 'val': 0, 'custom': False}]
    node['nid'] = int(float(id))
    node['x'] = int(float(x))
    node['y'] = int(float(y))
    node['type'] = 'Integer'
    return node

def generate_connection(x, y, id):
    node={}
    node['id']=int(id)
    node['from_node']=int(x)
    node['to_node']=int(y)
    node['from']='out'
    node['to']='in'
    return node

# tranform coordinates from VisTrails to online-VisTrails
def location_transform(xy):
    location_xy = [(xy[0] + 500), (xy[1]) + 150]
    return location_xy

def transform(action):
    what = action['add'][0]['@what']
    if what == 'module':
        # get module name
        moduleId = action['add'][0]['module']['@id']
        # get x and y coordinates
        # location_x = action['add'][1]['location']['@x']
        # location_y = action['add'][1]['location']['@y']
        location = location_transform([float(action['add'][1]['location']['@x']),
                                       float(action['add'][1]['location']['@y'])])
        print(location)
        output['nodes'].append(generate_integer_json(location[0],location[1],moduleId))
    if what == 'connection':
        # get connection
        connection = action['add'][0]['connection']['@id']
        pid1 = action['add'][1]['port']['@moduleId']
        pid2 = action['add'][2]['port']['@moduleId']
        output['connections'].append(generate_connection(pid1,pid2,connection))


if type(actions) is list:
    for action in actions:
        transform(action)
else:
    transform(actions)

open(args.outfile_name, 'w').write(json.dumps(output, indent=2))