param(
    # The SCCM site code to connect to.  This should be the CAS server or Primary server (in CAS-less heirarchies).
    [Parameter(Mandatory=$true)]
    [string]$SiteCode,
    # The path to the Configuration Manager PowerShell modules. Defaults to the Console install path.
    [Parameter(Mandatory=$false)]
    [string]$CmModulePath = ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')
)

try {
    $LastDir = $pwd.Path
    Import-Module $CmModulePath
    Set-Location "$($SiteCode):"
    $LastDir
}
catch {
    Write-Error $_
}