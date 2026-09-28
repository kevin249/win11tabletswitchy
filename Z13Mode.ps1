# Z13Mode.ps1
# ROG Flow Z13 Windows 11 PC / Tablet / Auto tray switcher.
# Launched by an elevated interactive scheduled task created by Install-Z13Mode.ps1.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'SilentlyContinue'
$RegPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl'
$IconPath = Join-Path $PSScriptRoot 'Z13Mode.ico'

if (-not ('Z13.NativeMethods' -as [type])) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
namespace Z13 {
    public static class NativeMethods {
        public const int HWND_BROADCAST = 0xffff;
        public const int WM_SETTINGCHANGE = 0x001A;
        public const int SMTO_ABORTIFHUNG = 0x0002;
        [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern IntPtr SendMessageTimeout(
            IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
            uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
    }
}
"@
}

function Broadcast-ModeChange {
    $result = [UIntPtr]::Zero
    [void][Z13.NativeMethods]::SendMessageTimeout(
        [IntPtr][Z13.NativeMethods]::HWND_BROADCAST,
        [Z13.NativeMethods]::WM_SETTINGCHANGE,
        [UIntPtr]::Zero,
        'ConvertibleSlateMode',
        [Z13.NativeMethods]::SMTO_ABORTIFHUNG,
        1000,
        [ref]$result)
}

function Ensure-RegPath {
    if (-not (Test-Path $RegPath)) {
        New-Item -Path $RegPath -Force | Out-Null
    }
}

function Set-PCMode {
    Ensure-RegPath
    New-ItemProperty -Path $RegPath -Name 'ConvertibilityEnabled' -PropertyType DWord -Value 0 -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name 'ConvertibleSlateMode' -PropertyType DWord -Value 1 -Force | Out-Null
    Broadcast-ModeChange
}

function Set-TabletMode {
    Ensure-RegPath
    New-ItemProperty -Path $RegPath -Name 'ConvertibilityEnabled' -PropertyType DWord -Value 1 -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name 'ConvertibleSlateMode' -PropertyType DWord -Value 0 -Force | Out-Null
    Broadcast-ModeChange
}

function Set-AutoMode {
    Ensure-RegPath
    Remove-ItemProperty -Path $RegPath -Name 'ConvertibilityEnabled' -ErrorAction SilentlyContinue
    Broadcast-ModeChange
}

function Get-Mode {
    Ensure-RegPath
    $p = Get-ItemProperty -Path $RegPath
    $hasCE = $null -ne $p.PSObject.Properties['ConvertibilityEnabled']
    $hasCSM = $null -ne $p.PSObject.Properties['ConvertibleSlateMode']
    $ce = if ($hasCE) { [int]$p.ConvertibilityEnabled } else { $null }
    $csm = if ($hasCSM) { [int]$p.ConvertibleSlateMode } else { $null }

    if (-not $hasCE) { return 'Auto' }
    if ($ce -eq 0) { return 'PC' }
    if (($ce -ne 0) -and $hasCSM -and ($csm -eq 0)) { return 'Tablet' }
    return 'Auto'
}

function Refresh-Explorer {
    Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 500
    Start-Process explorer.exe
}

$mutex = New-Object System.Threading.Mutex($false, 'Global\Z13ModeTraySingleton')
if (-not $mutex.WaitOne(0, $false)) { exit 0 }

$notify = New-Object System.Windows.Forms.NotifyIcon
$appIcon = $null
if (Test-Path $IconPath) {
    try {
        $appIcon = New-Object System.Drawing.Icon($IconPath)
        $notify.Icon = $appIcon
    } catch {
        $notify.Icon = [System.Drawing.SystemIcons]::Application
    }
} else {
    $notify.Icon = [System.Drawing.SystemIcons]::Application
}
$notify.Visible = $true
$notify.Text = 'Z13 Mode'

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$pcItem = $menu.Items.Add('PC 模式（强制）')
$tabletItem = $menu.Items.Add('平板模式（强制）')
$autoItem = $menu.Items.Add('自动（ASUS / Windows）')
[void]$menu.Items.Add('-')
$statusItem = $menu.Items.Add('当前：')
$statusItem.Enabled = $false
$refreshItem = $menu.Items.Add('刷新 Explorer（仅 UI 未切换时）')
[void]$menu.Items.Add('-')
$exitItem = $menu.Items.Add('退出')

function Update-Menu {
    $mode = Get-Mode
    $pcItem.Checked = ($mode -eq 'PC')
    $tabletItem.Checked = ($mode -eq 'Tablet')
    $autoItem.Checked = ($mode -eq 'Auto')
    switch ($mode) {
        'PC'     { $statusItem.Text = '当前：PC 模式'; $notify.Text = 'Z13 Mode - PC' }
        'Tablet' { $statusItem.Text = '当前：平板模式'; $notify.Text = 'Z13 Mode - Tablet' }
        default  { $statusItem.Text = '当前：自动模式'; $notify.Text = 'Z13 Mode - Auto' }
    }
}

function Show-Changed([string]$text) {
    Update-Menu
    $notify.BalloonTipTitle = 'Z13 Mode'
    $notify.BalloonTipText = $text
    $notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
    $notify.ShowBalloonTip(1500)
}

$pcItem.add_Click({ Set-PCMode; Show-Changed '已切换为强制 PC 模式。' })
$tabletItem.add_Click({ Set-TabletMode; Show-Changed '已切换为强制平板模式。' })
$autoItem.add_Click({ Set-AutoMode; Show-Changed '已恢复 ASUS / Windows 自动判断。' })
$refreshItem.add_Click({ Refresh-Explorer })
$exitItem.add_Click({
    $notify.Visible = $false
    $notify.Dispose()
    if ($null -ne $appIcon) { $appIcon.Dispose() }
    [System.Windows.Forms.Application]::Exit()
})

$notify.add_MouseClick({
    param($sender, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $mode = Get-Mode
        if ($mode -eq 'PC') {
            Set-TabletMode
            Show-Changed '已切换为强制平板模式。'
        } else {
            Set-PCMode
            Show-Changed '已切换为强制 PC 模式。'
        }
    }
})

$notify.ContextMenuStrip = $menu
Update-Menu

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 5000
$timer.add_Tick({ Update-Menu })
$timer.Start()

[System.Windows.Forms.Application]::Run()

$timer.Stop()
$notify.Visible = $false
$notify.Dispose()
if ($null -ne $appIcon) { $appIcon.Dispose() }
$mutex.ReleaseMutex() | Out-Null
$mutex.Dispose()
