# Remove the deployment agent for packaging
Remove-Item .\agent.zip -ErrorAction SilentlyContinue

# Move sysmon files to deploy directory
Copy-Item .\sysmon\ -Destination .\deploy -Recurse
Copy-Item .\configs\basic-config.xml -Destination .\deploy\sysmon

# Do this last
# Pacakage the files for deployment
Compress-Archive -Path .\deploy\* -CompressionLevel Optimal -DestinationPath .\agent.zip
