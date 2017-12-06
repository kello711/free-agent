# Cleanup/create the deploy directory
New-Item .\deploy -Itemtype Directory -ErrorAction SilentlyContinue

# Get the names of all files in the beats directory
$beats = Get-ChildItem .\beats\ -Name

# Expand the files into the deploy directory
ForEach ($file in $beats) {
  Expand-Archive -Path .\beats\$file -DestinationPath .\deploy\
}

# Rename the directories to *beat format
$deploy = Get-ChildItem .\deploy\ -Name
ForEach ($file in $deploy) {
  Rename-Item .\deploy\$file $file.split("-")[0]
}
