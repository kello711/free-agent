from ruamel.yaml import YAML
from ruamel.yaml.scalarstring import DoubleQuotedScalarString
from ruamel.yaml.comments import CommentedMap

import os
import sys
import subprocess as sp
import ipaddress
import argparse

# Method to udate the config file
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
    try:
        newConfigFile = open("deploy\\" + beat+ "\\" + beat + '.yml', 'w')
        yaml.dump(loaded_config, newConfigFile)
    except (FileNotFoundError):
        # Not using this beat
        pass

    return

# Validate a correct IP address was input
# Does not allow for FQDNs
def valid_ip(address):
    try:
        assert ipaddress.ip_address(address)
        return True
    except:
        return False

# Start of the script
# All the beat types that will be processed
beats = [
         'winlogbeat'#,
         #'filebeat',
         #'metricbeat', # not using based on inital hunt slides
         #'packetbeat'
         ]

# Name for the package to be deployed
parser = argparse.ArgumentParser()
parser.add_argument("-a", "--agent", help="the name of the agent to create", default="agent")
args = parser.parse_args()
agentName = args.agent
#print(f"Agent name: {agentName}")

# Start of the program
# Get IP address for Logstash server
ipAddr = '' # Remove the fake IP, only here for testing
port = ''
while not valid_ip(ipAddr):
    ipAddr = input("Enter logstash host IP: ")
    port = input("Enter port [5044]: ")
if port == '':
    # If nothing entered, use default port for beats input to logstash
    port = '5044'

# Setup path for PowerShell script (may be different on Mac)
psPath = "C:\\WINDOWS\\system32\\WindowsPowerShell\\v1.0\\powershell.exe"
sp.call([psPath, "Set-ExecutionPolicy RemoteSigned"])
# Copy the beats from source zip files via PowerShell script
sp.call([psPath, ".\config-beats.ps1"])

# Setting up the ruamel.yaml to properly read libbeat configs
yaml = YAML()
yaml.default_flow_style = False
yaml.indent(mapping=2, sequence=4, offset=2)
yaml.preserve_quotes = True

# Get directories to work with
rootDir = 'configs'
for dirName, subdirList, fileList in os.walk(rootDir):
    for file in fileList:
        for beat in beats:
            if file == beat + '.yml':   #startswith(beat):
                print(f"Updating: {dirName}\{beat}.yml")
                update_config(beat, dirName+'\\')

# Copy sysmon files and package the files for deployment
print("Packaging agent for deployment...")
sp.call([psPath, ".\package-agent.ps1  -name " + agentName])

# Deploy the agent to all systems in range provided
# Currently being done in a different PowerShell script
#sp.call(["C:\\WINDOWS\\system32\\WindowsPowerShell\\v1.0\\powershell.exe", ".\deploy-agent.ps1  -name " + agentName])
