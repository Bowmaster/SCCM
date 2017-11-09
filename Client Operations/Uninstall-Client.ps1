#Requires -RunAsAdministrator

param(
    # Opts to perform a complex, scripted uninstall rather than just using ccmsetup with the uninstall flag
    [Parameter(Mandatory=$false)]
    [switch]$ComplexRemoval,
    # Remote computer to execute the script against
    [Parameter(Mandatory=$false)]
    [string]$ComputerName=".",
    # The credential to use to connect to the remote computer
    [Parameter(Mandatory=$false)]
    [pscredential]
    $Credential
)



Invoke-Command -ComputerName $ComputerName -Credential $Credential -ArgumentList $ComplexRemoval -ScriptBlock {
    $ComplexRemoval = $args[0]
    try {
        if ($ComplexRemoval) {
            $CmServices = @("ccmsetup",
            "ccmexec",
            "cmrcservice",
            "smstsmgr")
            $CmServices | Stop-Service -ErrorAction SilentlyContinue
            $Dependcies = (Get-Service -Name winmgmt).DependentServices
            $WmiBackupPath = "C:\Windows\Temp\WmiBackup$((Get-Date).ToFileTime()).wmi"
            winmgmt /backup $WmiBackupPath
            Write-Host "The WMI repository has been backup up to $WmiBackupPath" -ForegroundColor Yellow
            Stop-Service winmgmt -Force -ErrorAction Stop
            $CmServices | % {sc.exe delete $_}
    
            @("HKLM:\SYSTEM\CurrentControlSet\services\Ccmsetup",
            "HKLM:\SYSTEM\CurrentControlSet\services\CcmExec",
            "HKLM:\SYSTEM\CurrentControlSet\services\smstsmgr",
            "HKLM:\SYSTEM\CurrentControlSet\services\CmRcService",
            "HKLM:\SOFTWARE\Microsoft\CCM",
            "HKLM:\SOFTWARE\Microsoft\CCMSetup",
            "C:\Windows\CCM",
            "C:\Windows\ccmsetup",
            "C:\Windows\ccmcache",
            "C:\Windows\SMSCFG.ini",
            "C:\Windows\SMS*.mif") | % {Remove-Item $_ -Force -Recurse -ErrorAction SilentlyContinue}
    
            Unregister-ScheduledTask -TaskPath "\Microsoft\Configuration Manager\" -TaskName * -Confirm:$false
    
            get-wmiobject -query "SELECT * FROM __Namespace WHERE Name='CCM'" -Namespace "root" | Remove-WmiObject
    
            get-wmiobject -query "SELECT * FROM __Namespace WHERE Name='sms'" -Namespace "root\cimv2" | Remove-WmiObject
    
            Start-Service Winmgmt
            
            $Dependcies | % {
                if ($_.Status -eq "Running") {
                    Start-Service $_ 
                }
            }
            Write-Host "The process completed without a STOPPING error. Please confirm the health of server before reinstalling SCCM." -ForegroundColor Green
        }else {
            Write-Warning "Note: ccmsetup commands return to the console immediately while processing continues in the background, please verify by monitoring the ccmsetup.log file for a successful return code."
            C:\Windows\ccmsetup\ccmsetup.exe /uninstall
        }
    }
    catch {
        Write-Warning "This following errors occured:"
        Write-Error $_
    }
}
