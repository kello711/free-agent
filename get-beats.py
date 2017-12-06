import urllib.request
import os

directory = ".\\beats"
if not os.path.exists(directory):
    os.makedirs(directory)

# All the beat types that will be processed
beats = ['winlogbeat',
         'filebeat',
         #'metricbeat', # not using based on inital hunt slides
         'packetbeat']

for beat in beats:
    version = "6.0.0"
    file_name = beat + "-"+ version +"-windows-x86_64.zip"
    url = "https://artifacts.elastic.co/downloads/beats/" + beat + "/" + file_name
    urllib.request.urlretrieve(url, directory + "\\" + file_name)
