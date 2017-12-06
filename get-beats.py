# Small helper file to download the latest beats
# May need to change the version number and the beats collection

import urllib.request
import os

# Create the beats directory
directory = ".\\beats"
if not os.path.exists(directory):
    print("Creating 'beats' directory")
    os.makedirs(directory)
else:
    print("'beats' directory already exists")

# All the beat types that will be processed
beats = ['winlogbeat',
         'filebeat',
         #'metricbeat', # not using based on inital hunt slides
         'packetbeat']

# Get the beats
for beat in beats:
    version = "6.0.0"
    file_name = beat + "-"+ version +"-windows-x86_64.zip"
    if not os.path.exists(directory + "\\" + file_name):
        url = "https://artifacts.elastic.co/downloads/beats/" + beat + "/" + file_name
        print(f"\tGetting {beat} from: {url}", end='')
        urllib.request.urlretrieve(url, directory + "\\" + file_name)
        print("...complete")
    else:
        print(f"\tFile {file_name} already exists")
