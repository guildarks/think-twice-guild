# ============================================
# Windows Task Scheduler Setup for Workflow Agent
# Run as Administrator
# ============================================

Write-Host "Setting up Workflow Agent Task Scheduler..." -ForegroundColor Blue
Write-Host "============================================" -ForegroundColor Blue
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "ERROR: Please run this script as Administrator" -ForegroundColor Red
    exit 1
}

# Task settings
$taskName = "Workflow-Addon-Agent"
$taskPath = "\Claude\"
$scriptPath = "E:\cerveaux claude\run-workflow.sh"
$projectPath = "E:\cerveaux claude"

# Check if script exists
if (-not (Test-Path $scriptPath)) {
    Write-Host "Script not found: $scriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "Task Configuration:" -ForegroundColor Yellow
Write-Host "  Name: $taskName" -ForegroundColor Cyan
Write-Host "  Path: $taskPath" -ForegroundColor Cyan
Write-Host "  Script: $scriptPath" -ForegroundColor Cyan
Write-Host ""

# Remove existing task if it exists
Write-Host "Checking for existing task..." -ForegroundColor Yellow
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($existingTask) {
    Write-Host "Task already exists. Removing..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false | Out-Null
    Write-Host "Old task removed" -ForegroundColor Green
}

# Create action (Git Bash)
$gitBashPath = "C:\Program Files\Git\bin\bash.exe"

if (-not (Test-Path $gitBashPath)) {
    Write-Host "Git Bash not found at: $gitBashPath" -ForegroundColor Red
    Write-Host "Please install Git with Bash support" -ForegroundColor Yellow
    exit 1
}

$action = New-ScheduledTaskAction `
    -Execute $gitBashPath `
    -Argument "`"$scriptPath`" `"$projectPath`""

Write-Host "Action configured" -ForegroundColor Green

# Create trigger - Daily at 9 PM
$trigger = New-ScheduledTaskTrigger `
    -Daily `
    -At 9:00PM `
    -DaysInterval 1

Write-Host "Trigger configured (Daily at 9:00 PM)" -ForegroundColor Green

# Create principal (run with current user)
$principal = New-ScheduledTaskPrincipal `
    -UserID "$env:COMPUTERNAME\$env:USERNAME" `
    -LogonType Interactive `
    -RunLevel Highest

Write-Host "Principal configured (Run as: $env:USERNAME)" -ForegroundColor Green

# Create task settings
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -WakeToRun `
    -Compatibility Win8

Write-Host "Settings configured" -ForegroundColor Green

# Register the task
Write-Host ""
Write-Host "Creating task..." -ForegroundColor Yellow

Register-ScheduledTask `
    -TaskName $taskName `
    -TaskPath $taskPath `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description "Automated Workflow Agent for Addons and Coding Projects" `
    -Force | Out-Null

Write-Host "Task created successfully!" -ForegroundColor Green

# Verify
Write-Host ""
Write-Host "Verifying..." -ForegroundColor Yellow
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($task) {
    Write-Host "Task verified!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Task Details:" -ForegroundColor Cyan
    Write-Host "  Name: $($task.TaskName)" -ForegroundColor Gray
    Write-Host "  Path: $($task.TaskPath)" -ForegroundColor Gray
    Write-Host "  State: $($task.State)" -ForegroundColor Gray
    Write-Host "  Next Run: $($task.Triggers[0].StartBoundary)" -ForegroundColor Gray
} else {
    Write-Host "Task creation failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Blue
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Blue
Write-Host ""
Write-Host "The Workflow Agent will run:" -ForegroundColor Yellow
Write-Host "  * Every day at 9:00 PM" -ForegroundColor Cyan
Write-Host "  * Automatically tests, debugs, and commits code" -ForegroundColor Cyan
Write-Host "  * Works with Node, Python, Go, Rust, Java, etc." -ForegroundColor Cyan
Write-Host ""
