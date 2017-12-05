<#
.SYNOPSIS
Used to deploy sysmon and elastic beats agents to client computers.
.DESCRIPTION

.PARAMETER name
The agent name

.EXAMPLE

#>
[CmdletBinding()]

# Pull in command line parameters
param (
  [Alias('agent')][string]$name = "agent"
)

$agent = Get-Item $name

# Get credentials for user to deploy as (i.e. Administrator)
Try {
  # Change the -Credential name before running (or remove the name)
  $cred = Get-Credential -Credential Kelly -ErrorAction Stop
}
Catch {
  Write-Error "ERROR: You must supply credentials for deployment script."
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
  Write-Verbose "Connecting to $computer..."
  $session = New-PSSession -ComputerName $computer -Credential $cred

  Write-Verbose "Copying $name.zip to $computer..."
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
  Write-Verbose "Installing agent archive on $hostname."
  Remove-Item "C:\$name" -Recurse -ErrorAction SilentlyContinue
  Expand-Archive "C:\$name.zip" -DestinationPath "C:\$name\" -Force
  Remove-Item -Path "C:\$name.zip" -Force

  Write-Verbose "Setting ExecutionPolicy to allow running scripts on $hostname."
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

  # Move to the newly created directory
  Set-Location -Path "C:\$name"

  # Install sysmon
  .\sysmon\install-sysmon.ps1

  # Install beats
  Write-Verbose "Installing beats on ${hostname}:"
  # Get the names of all files in the beats directory
  $beats = Get-ChildItem .\ -Name *beat
  foreach($beat in $beats) {
    # TODO: Skip packet beat for now need to check config
    if ($beat -eq "packetbeat") { continue }
    Write-Verbose "`t$beat..."
    & ".\$beat\install-service-$beat.ps1" | Out-Null
    Start-Service $beat | Out-Null
  }
  Write-Verbose "$hostname complete:"
  Get-Service sysmon,*beat | Select Name,Status | Format-Table -AutoSize
}

# Cleanup WinRM client trusted computers
Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value "" -Force
