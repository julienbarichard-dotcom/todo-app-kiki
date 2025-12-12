# Registers a Windows Task Scheduler job to run git_backup.ps1 daily
param(
  [string]$TaskName = "TodoApp-GitBackup-Daily",
  [string]$Time = "03:00",  # local time HH:mm
  [string]$RepoPath = "E:\App todo",
  [string]$Message = "Backup quotidien"
)

$scriptPath = Join-Path $RepoPath "scripts\git_backup.ps1"
if (-not (Test-Path $scriptPath)) {
  Write-Host "Script not found: $scriptPath" -ForegroundColor Red
  exit 1
}

# Build action to run PowerShell with the script
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -Message `"$Message`""
$trigger = New-ScheduledTaskTrigger -Daily -At ([datetime]::ParseExact($Time, 'HH:mm', $null))
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

# Register task
try {
  Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Force
  Write-Host "Scheduled daily Git backup registered as '$TaskName' at $Time" -ForegroundColor Green
} catch {
  Write-Host "Failed to register task: $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}
