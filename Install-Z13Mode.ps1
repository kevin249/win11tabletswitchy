# Install-Z13Mode.ps1
# Installs Z13 Mode and registers a highest-privilege interactive logon task.

Add-Type -AssemblyName System.Windows.Forms
$ErrorActionPreference = 'Stop'

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $PSCommandPath)
    )
    exit
}

$installDir = Join-Path $env:ProgramData 'Z13Mode'
New-Item -ItemType Directory -Path $installDir -Force | Out-Null
Copy-Item -Path (Join-Path $PSScriptRoot 'Z13Mode.ps1') -Destination (Join-Path $installDir 'Z13Mode.ps1') -Force
Copy-Item -Path (Join-Path $PSScriptRoot 'Z13Mode.ico') -Destination (Join-Path $installDir 'Z13Mode.ico') -Force

$taskName = 'Z13 Mode Tray'
$scriptPath = Join-Path $installDir 'Z13Mode.ps1'
$iconPath = Join-Path $installDir 'Z13Mode.ico'
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ('-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{0}"' -f $scriptPath)
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $identity.Name
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Days 3650)
$taskPrincipal = New-ScheduledTaskPrincipal -UserId $identity.Name -LogonType Interactive -RunLevel Highest

Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $taskPrincipal -Description 'ROG Flow Z13 PC / Tablet / Auto tray switcher' | Out-Null

# Start Menu shortcut: launches the already-authorized scheduled task and uses the custom icon.
$startMenuDir = Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs'
$shortcutPath = Join-Path $startMenuDir 'Z13 Mode.lnk'
$wsh = New-Object -ComObject WScript.Shell
$shortcut = $wsh.CreateShortcut($shortcutPath)
$shortcut.TargetPath = Join-Path $env:SystemRoot 'System32\schtasks.exe'
$shortcut.Arguments = '/Run /TN "Z13 Mode Tray"'
$shortcut.WorkingDirectory = $installDir
$shortcut.IconLocation = "$iconPath,0"
$shortcut.Description = 'Z13 Mode - PC / Tablet / Auto switcher'
$shortcut.Save()

Start-ScheduledTask -TaskName $taskName

[System.Windows.Forms.MessageBox]::Show(
    "安装完成。`n`n右下角托盘会出现新的 Z13 Mode 图标。`n左键：PC / 平板快速切换`n右键：PC / 平板 / 自动 / 刷新 Explorer。",
    'Z13 Mode',
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
) | Out-Null
