<#
.SYNOPSIS  Scans the system for improperly open MCP/Chrome channels.
           Run after every Claude in Chrome session.
#>
$sep = "=" * 56
Write-Output "$sep`n  SECURITY SCAN - MCP / CHROME`n  $(Get-Date -Format 'MM/dd/yyyy HH:mm:ss')`n$sep"
$issues = 0

Write-Output "`n[1] Chrome suspicious flags..."
$flagged = Get-WmiObject Win32_Process | Where-Object {
    $_.Name -like "*chrome*" -and
    $_.CommandLine -match "remote-debugging|headless|no-sandbox|disable-web-security" }
if ($flagged) { $flagged | ForEach-Object { Write-Warning "PID $($_.ProcessId): $($_.CommandLine.Substring(0,100))"; $issues++ } }
else { Write-Output "  OK - no suspicious flags" }

Write-Output "`n[2] Critical ports..."
@(9222,9229,3000,3001,4040,8765) | ForEach-Object {
    $h = netstat -ano 2>$null | Select-String ":$_ .*LISTENING"
    if ($h) { Write-Warning "  Port $_ OPEN: $h"; $issues++ } else { Write-Output "  OK Port $_" } }

Write-Output "`n[3] MCP processes..."
$mcp = Get-Process -EA SilentlyContinue | Where-Object { $_.Name -match "^node$|^npx$|^mcp$|^deno$" }
if ($mcp) { $mcp | ForEach-Object { Write-Warning "  Active: $($_.Name) PID=$($_.Id)"; $issues++ } }
else { Write-Output "  OK - no Node/MCP processes" }

Write-Output "`n[4] Claude Desktop pairing..."
$cfg = "$env:APPDATA\Claude\claude_desktop_config.json"
if (Test-Path $cfg) {
    $j = Get-Content $cfg -Raw | ConvertFrom-Json
    $p = $j.preferences.chromeExtension.pairedDeviceName
    if ($p) { Write-Warning "  Still paired: $p"; $issues++ } else { Write-Output "  OK - no pairing" }
}

Write-Output "`n$sep"
if ($issues -eq 0) { Write-Output "  ALL CLEAR" } else { Write-Warning "  $issues issue(s) found" }
Write-Output "$sep"
