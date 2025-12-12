# Simple Git backup script: commits and pushes current workspace
param(
    [string]$Message = "Auto backup",
    [string]$Branch = "main"
)

Write-Host "Starting Git backup..." -ForegroundColor Cyan

# Ensure we're at repo root (one level up from this scripts folder if needed)
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
Push-Location $repoRoot

# Initialize git if missing
if (-not (Test-Path ".git")) {
    git init
}

# Add all changes
git add -A

# Commit with timestamp
$timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$finalMessage = "$Message - $timestamp"

# Allow empty commit if nothing changed
try {
    git commit -m "$finalMessage" --allow-empty
} catch {
    Write-Host "Commit failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Detect remote
$remote = git remote
if ([string]::IsNullOrWhiteSpace($remote)) {
    Write-Host "No git remote configured. Run: git remote add origin <URL>" -ForegroundColor Yellow
} else {
    # Determine current branch
    $currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
    if ([string]::IsNullOrWhiteSpace($currentBranch)) { $currentBranch = $Branch }

    Write-Host "Pushing to remote '$remote' branch '$currentBranch'..." -ForegroundColor Cyan
    git push -u origin $currentBranch
}

Pop-Location
Write-Host "Git backup complete." -ForegroundColor Green
