<#
.SYNOPSIS
    Collects URLs from a range of Chrome tabs via UIAutomation + keyboard shortcuts.
.PARAMETER StartTab
    Number of the first tab (1-based).
.PARAMETER EndTab
    Number of the last tab (1-based).
.PARAMETER OutputPath
    Path of the output markdown file.
.EXAMPLE
    .\collect_urls.ps1 -StartTab 67 -EndTab 87
#>
param(
    [int]$StartTab    = 1,
    [int]$EndTab      = 10,
    [string]$OutputPath = "$env:USERPROFILE\Desktop\urls_tabs_${StartTab}_${EndTab}.md"
)

Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class ChromeNav {
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(int f,int x,int y,int d,int e);
    [DllImport("user32.dll")] public static extern void keybd_event(byte vk,byte sc,int fl,int ex);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
    public static void Click(int x, int y) {
        SetCursorPos(x, y); System.Threading.Thread.Sleep(200);
        mouse_event(2,0,0,0,0); System.Threading.Thread.Sleep(150);
        mouse_event(4,0,0,0,0); System.Threading.Thread.Sleep(150);
    }
    public static void CtrlL()   { Key(0x11); Key(0x4C); Up(0x4C); Up(0x11); }
    public static void CtrlC()   { Key(0x11); Key(0x43); Up(0x43); Up(0x11); }
    public static void CtrlTab() { Key(0x11); Key(0x09); Up(0x09); Up(0x11); }
    static void Key(byte vk) { keybd_event(vk,0,0,0); }
    static void Up (byte vk) { keybd_event(vk,0,2,0); }
}
"@

$root = [System.Windows.Automation.AutomationElement]::RootElement
$chrome = $root.FindAll(
    [System.Windows.Automation.TreeScope]::Children,
    (New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::ClassNameProperty, "Chrome_WidgetWin_1"))
) | Where-Object { $_.Current.Name -like "*Google Chrome*" } | Select-Object -First 1

if (-not $chrome) { throw "Chrome window not found." }

$hwnd = [IntPtr]$chrome.Current.NativeWindowHandle
[ChromeNav]::ShowWindow($hwnd, 9) | Out-Null
[ChromeNav]::SetForegroundWindow($hwnd) | Out-Null
Start-Sleep -Milliseconds 600

$tabs = $chrome.FindAll(
    [System.Windows.Automation.TreeScope]::Descendants,
    (New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
        [System.Windows.Automation.ControlType]::TabItem)))

Write-Output "Total tabs found: $($tabs.Count)"
if ($tabs.Count -lt $EndTab) { throw "Chrome has only $($tabs.Count) tabs." }

$firstTab = $tabs[$StartTab - 1]
$rect = $firstTab.Current.BoundingRectangle
[ChromeNav]::Click([int]($rect.X+$rect.Width/2), [int]($rect.Y+$rect.Height/2))
Start-Sleep -Milliseconds 700

$results = @()
for ($i = 0; $i -lt ($EndTab - $StartTab + 1); $i++) {
    [ChromeNav]::CtrlL(); Start-Sleep 300
    [ChromeNav]::CtrlL(); Start-Sleep 300
    [ChromeNav]::CtrlC(); Start-Sleep 400
    $url = Get-Clipboard
    $tabNum = $StartTab + $i
    $prev = if ($results.Count -gt 0) { $results[-1].Split("|")[1] } else { "" }
    $results += if ($url -eq $prev) { "$tabNum|[DUPLICATE]" } else { "$tabNum|$url" }
    Write-Output "Tab $tabNum : $url"
    Write-Progress -Activity "Collecting" -Status "$tabNum of $EndTab" -PercentComplete (($i+1)/($EndTab-$StartTab+1)*100)
    if ($i -lt ($EndTab-$StartTab)) { [ChromeNav]::CtrlTab(); Start-Sleep 500 }
}

$ts = Get-Date -Format "MM/dd/yyyy HH:mm:ss"
$out = @("## URLs from tabs $StartTab to $EndTab",""> Collected: $ts | Total: $($results.Count)","","| # | URL |","|---|-----|")
foreach ($r in $results) { $p=$r.Split("|",2); $out += "| $($p[0]) | $($p[1]) |" }
$out | Out-File $OutputPath -Encoding UTF8
Write-Output "Saved: $OutputPath"
