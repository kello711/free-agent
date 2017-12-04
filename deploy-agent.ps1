# Pull in command line parameters
param (
  [string]$name = "agent"
)

# Get credentials for user to deploy as (i.e. Administrator)
Try {
  # Change the -Credential name before running (or remove the name)
  $cred = Get-Credential -Credential Kelly -ErrorAction Stop
}
Catch {
  echo "ERROR: You must supply credentials for deployment script."
  Exit
}

# Get the computers to deploy to
$computers = Get-Content .\configs\computers.txt

# Setup WinRM client to trust computers connecting to
Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value ($computers -Join ",") -Force

Invoke-Command -Credential $cred -ComputerName $computers -ScriptBlock {
  # delete service on all hosts if it exists
  if (Get-Service *beat -ErrorAction SilentlyContinue) {
    $services = Get-WmiObject -Class Win32_Service -Filter "name like '%beat%'"
    $services | ForEach-Object {
      # Supress unuseful output
      $_.StopService() | Out-Null
      $_.Delete() } | Out-Null
  }
}

foreach($computer in $computers) {
  Write-Host "Connecting to $computer..."
  $session = New-PSSession -ComputerName $computer -Credential $cred

  Write-Host "Copying $name.zip to $computer..."
  Remove-Item -Path "C:\$name.zip" -Force -ErrorAction SilentlyContinue
  Copy-Item "$name.zip" -Destination "C:\$name.zip" -ToSession $session -Force

  Remove-PSSession $session
}

Invoke-Command -Credential $cred -ComputerName $computers -ArgumentList $name -ScriptBlock {
  param(
    [string]$name
  )
  $hostname = (& hostname)

  # Remove old and expand new archive
  Write-Host "Installing agent archive on $hostname."
  Remove-Item "C:\$name" -Recurse -ErrorAction SilentlyContinue
  Expand-Archive "C:\$name.zip" -DestinationPath "C:\$name\" -Force
  Remove-Item -Path "C:\$name.zip" -Force

  Write-Host "Setting ExecutionPolicy to allow running scripts on $hostname."
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

  # Move to the newly created directory
  Set-Location -Path "C:\$name"

  # Install sysmon
  .\sysmon\install-sysmon.ps1

  # Install beats
  Write-Host "Installing beats on ${hostname}:"
  # Get the names of all files in the beats directory
  $beats = Get-ChildItem .\ -Name *beat
  foreach($beat in $beats) {
    # TODO: Skip packet beat for now need to check config
    if ($beat -eq "packetbeat") { continue }
    Write-Host "`t$beat..."
    & ".\$beat\install-service-$beat.ps1" | Out-Null
    Start-Service $beat | Out-Null
  }
  Write-Host "$hostname complete:"
  Get-Service sysmon,*beat | Select Name,Status | Format-Table -AutoSize
}

# Cleanup WinRM client trusted computers
Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value "" -Force
