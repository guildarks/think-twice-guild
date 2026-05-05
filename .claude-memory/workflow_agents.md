---
name: Workflow Automation Agents
description: Daily automated testing, fixing, and Git commit workflow configured via Windows Task Scheduler
type: project
---

# Workflow Agents Configuration

**Active**: Yes - Runs daily at 21:00 (9 PM) via Windows Task Scheduler

## Setup Location
- Task Name: `Workflow-Addon-Agent`
- Task Path: `\Claude\`
- Scripts: `E:\cerveaux claude\`
- Status: ✅ Verified and working

## How Agents Work

**Every day at 21:00**, the workflow agent:
1. Detects project language (Node, Python, Go, Rust, Java, C#, PHP, Ruby, Make)
2. Checks for changes via `git status`
3. Runs language-specific tests (npm test, pytest, go test, etc.)
4. Auto-fixes issues (linting, formatting)
5. Re-runs tests to verify
6. Auto-commits to Git with timestamp
7. Attempts to push to origin/main

## Key Scripts

- `workflow-multilang.sh` - Universal workflow automation (auto-detects language)
- `run-workflow.sh` - Wrapper script that calls workflow-multilang.sh
- `setup-scheduler.ps1` - PowerShell script to configure Task Scheduler (Windows admin only)

## Test Results

**Test-project (Node.js)**: Successfully tested 3 times
- ✅ Commit 0f8abe9 - Auto-commit at 21:48:44
- ✅ Commit 2ea5a78 - Auto-commit at 21:44:57
- ✅ Commit b925e1b - Auto-commit at 21:30:24

## GitHub Integration

- Remote configured: `https://github.com/guildarks/think-twice-guild.git`
- Branch: `main`
- Push enabled: Yes (attempts after successful tests)

## Manual Execution

To run workflow manually:
```bash
bash "E:\cerveaux claude\workflow-multilang.sh"
```

## Future Improvements

- Add GitHub Actions for CI/CD on remote
- Configure email notifications on test failure
- Add webhook triggers for automatic execution on Git push
