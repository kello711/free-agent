# Get credentials for user to deploy as (i.e. Administrator)
Try {
  # Change the -Credential name before running (or remove the name)
  $cred = Get-Credential -ErrorAction Stop
}
Catch {
  echo "ERROR: You must supply credentials for deployment script."
  Exit
}

$computers = Get-Content .\configs\computers.txt
$install_dir = "agent"
$filename = $install_dir+".zip"

# Setup WinRM client to trust computers connecting to
Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value ($computers -Join ",") -Force

foreach($computer in $computers) {
  Write-Host "Connecting to $computer..."
  $session = New-PSSession -ComputerName $computer -Credential $cred -Verbose

  Write-Host "Copying $filename to $computer..."
  Copy-Item $filename -Destination "C:\$filename" -ToSession $session -Force

  Invoke-Command -Session $session -ScriptBlock {
    $install_dir = "agent"
    $filename = $install_dir+".zip"

    #Write-Host "Checking for old agent files..."
    #Remove-Item "C:\$install_dir" -Recurse -ErrorAction SilentlyContinue

    # Expand and remove the archive
    Write-Host "Expanding agent archive..."
    Expand-Archive "C:\$filename" -DestinationPath "C:\$install_dir" -Force
    Write-Host "Removing archive..."
    Remove-Item -Path "C:\$install_dir.zip" -Force

    Write-Host "Setting ExecutionPolicy to allow running scripts on remote host..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

    # Install sysmon
    Write-Host "Installing sysmon..."
    #C:\agent\sysmon\sysmon.exe -accepteula -i C:\agent\sysmon\basic-config.xml
    C:\agent\sysmon\install-sysmon.ps1

    # Install beats
    Write-Host "Installing winlogbeats..."
    C:\agent\winlogbeat\install-service-winlogbeat.ps1
    Start-Service winlogbeat
    Get-Service winlogbeat
  }

  Remove-PSSession $session
  #Out-File -FilePath "C:\installed.txt" -Append -InputObject "$computer"
}

# Cleanup WinRM client trusted computers
Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value "" -Force
