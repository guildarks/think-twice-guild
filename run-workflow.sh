#!/bin/bash

# ============================================
# Workflow Agent Runner
# Universal project workflow automation
# ============================================

echo "🤖 Workflow Automation Agent Started"
echo "======================================"

# Get project directory (default to current)
PROJECT_DIR="${1:-.}"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Project directory not found: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

echo "📁 Project: $(pwd)"
echo ""

# Run the workflow
bash "E:\cerveaux claude\workflow-multilang.sh"

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✅ Workflow Agent: Task completed successfully!"
else
    echo ""
    echo "❌ Workflow Agent: Task failed with code $EXIT_CODE"
fi

exit $EXIT_CODE
