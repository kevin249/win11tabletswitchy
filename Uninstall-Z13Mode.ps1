# Uninstall-Z13Mode.ps1
Add-Type -AssemblyName System.Windows.Forms
$ErrorActionPreference = 'SilentlyContinue'

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $PSCommandPath)
    )
    exit
}

Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object {
    $_.CommandLine -like '*ProgramData\Z13Mode\Z13Mode.ps1*'
} | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }

Unregister-ScheduledTask -TaskName 'Z13 Mode Tray' -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item -Path (Join-Path $env:ProgramData 'Z13Mode') -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\Z13 Mode.lnk') -Force -ErrorAction SilentlyContinue

$regPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl'
Remove-ItemProperty -Path $regPath -Name 'ConvertibilityEnabled' -ErrorAction SilentlyContinue

[System.Windows.Forms.MessageBox]::Show(
    'Z13 Mode 已卸载，并恢复 Windows / ASUS 自动判断。',
    'Z13 Mode',
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
) | Out-Null
