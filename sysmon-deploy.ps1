Set-Item wsman:\localhost\client\trustedhosts * -Force
$cred = Get-Credential username
$computers = Get-Content "\path\to\computer.txt"

foreach($computer in $computers) {
    Copy-Item -Path "\path\to\filename.zip" -Destination "\\$computer\C$\afs-agent.zip" -Force

    Invoke-Commmand -ComputerName $computer -Credential $cred -ScriptBlock {
        Expand-Archive "C:\afs-agent.zip" -DestinationPath "C:\afs-agent" -Force
    }

    Remove-Item -Path "\\$computer\C$\afs-agent.zip" -Force

    Invoke-Command -ComputerName $computer -Credential $cred -ScriptBlock {
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
        C:\afs-agent\sysmon.exe -accepteula -i C:\afs-agent\sysmon-config.xml
        C:\afs-agent\winlogbeat\install-service-winlogbeat.ps1
        Start-Service winlogbeat
        Get-Service winlogbeat
    }

    #Out-File -FilePath "C:\installed.txt" -Append -InputObject "$computer"
}
