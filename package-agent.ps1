# Helper script to package sysmon/beats for deployment
# It puts all the files in the deploy directory into a zip

# Pull in command line parameters
param (
  [string]$name = "agent"
)

# Remove the deployment agent for packaging
Remove-Item .\$name.zip -ErrorAction SilentlyContinue

# Move sysmon files to deploy directory
Copy-Item .\sysmon\ -Destination .\deploy -Recurse -Force
Copy-Item .\configs\basic-config.xml -Destination .\deploy\sysmon -Force

# Do this last
# Pacakage the files for deployment
Compress-Archive -Path .\deploy\* -CompressionLevel Optimal -DestinationPath ".\$name.zip"
