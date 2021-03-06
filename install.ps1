$ErrorActionPreference = "Stop"

If (!([Security.Principal.WindowsPrincipal] `
     [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Error "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
}

Function Reset-Path {
  $MachinePaths = [Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Machine) -split ';'
  $UserPaths = [Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::User) -split ';'
  $Env:Path = ($MachinePaths + $UserPaths) -join ';'
}

Write-Host 'Bootstrapping Workup'

$WORKUP_VERSION = "0.1.6"
$WORKUP_URL = "https://github.com/cvent/workup/releases/download/v${WORKUP_VERSION}/workup.msi"
$WORKUP_DIR = Join-Path ${HOME} '.workup'

Get-WmiObject `
    -Class Win32_Product `
    -Filter "Name LIKE 'Workup%'" |% {
  Write-Host -NoNewLine "Uninstalling Workup v$($_.Version)... "
  $_.Uninstall() | Out-Null
  Write-Host -ForegroundColor 'Green' 'OK'
}

If (!(Test-Path ${WORKUP_DIR} -PathType 'Container')) {
  Write-Host -NoNewLine "Creating ~/.workup directory... "
  New-Item -Type Directory ${WORKUP_DIR} | Out-Null
  Write-Host -ForegroundColor 'Green' 'OK'
}

Write-Host -NoNewLine "Installing Workup v${WORKUP_VERSION}... "
$installer = Join-Path $WORKUP_DIR 'workup.msi'
(New-Object System.Net.WebClient).DownloadFile($WORKUP_URL, $installer)
cmd /c start '' /wait msiexec /i $installer /qn
Write-Host -ForegroundColor 'Green' 'OK'

Reset-Path

Write-Host -NoNewLine "Checking for workup command... "
If (Get-Command 'workup' -ErrorAction Ignore) {
  Write-Host -ForegroundColor 'Green' 'OK'
} else {
  Write-Host -ForegroundColor 'Red' 'Not found'
  Exit 1
}

Write-Host 'You are ready to run workup'
