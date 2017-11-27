from ruamel.yaml import YAML
from ruamel.yaml.scalarstring import DoubleQuotedScalarString
from ruamel.yaml.comments import CommentedMap

import os
import sys
import ipaddress

def update_config(beat, path):
    # Read the winlogbeat config
    config_doc = open(path + beat + '.yml', 'r')
    loaded_config = yaml.load(config_doc)

    try:
        # Create logstash hostname:port string and insert into the config map
        hostName = DoubleQuotedScalarString(ipAddr + ":" + port)
        print(f"\tSetting logstash host IP: {hostName} -->", end= ' ')
        # Remove default host and add new hostname
        loaded_config['output.logstash']['hosts'].pop(0)
        loaded_config['output.logstash']['hosts'].insert(0, hostName)
        print("Success")
    except:
        print("Failed")
        print(f"\t{beat} config does not have logstash enabled")

    # Remove the outpout.elasticsearch section if it isn't commented out
    del loaded_config['output.elasticsearch']
    print("\tElasticsearch output removed")

    # Output the corrected config to screen, can also dump to a file
    # yaml.dump(loaded_config, sys.stdout)
    newConfigFile = open(path + beat + '_test.yml', 'w')
    yaml.dump(loaded_config, newConfigFile)

    return

# Validate a correct IP address was input
# Does not allow for FQDNs
def valid_ip(address):
    try:
        assert ipaddress.ip_address(address)
        return True
    except:
        return False

# All the beat types that will be processed
beats = ['winlogbeat',
         'filebeat',
         'metricbeat',
         'packetbeat']

# Start of the program
ipAddr = 'asdf' # Remove the fake IP, only here for testing
port = ''
while not valid_ip(ipAddr):
    ipAddr = input("Enter logstash host IP: ")
    port = input("Enter port [5044]: ")
if port == '':
    # If nothing entered, use default port for beats input to logstash
    port = '5044'

# Setting up the ruamel.yaml to properly read libbeat configs
yaml = YAML()
yaml.default_flow_style = False
yaml.indent(mapping=2, sequence=4, offset=2)
yaml.preserve_quotes = True

# Get directories to work with
rootDir = '.'
for dirName, subdirList, fileList in os.walk(rootDir):
    for file in fileList:
        for beat in beats:
            if file == beat + '.yml':   #startswith(beat):
                print(f"Updating: {dirName}/{beat}.yml")
                update_config(beat, dirName+'/')
