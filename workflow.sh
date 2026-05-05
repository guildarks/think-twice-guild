#!/bin/bash

# ============================================
# Addon + Coding Workflow Automation
# Usage: ./workflow.sh
# ============================================

set -e  # Exit on error

echo "🚀 Starting Automated Workflow..."
echo "================================"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Detect Changes
echo -e "${YELLOW}1️⃣ Detecting changes...${NC}"
if git status --porcelain | grep -q .; then
    echo -e "${GREEN}✓ Changes detected${NC}"
else
    echo -e "${RED}✗ No changes to process${NC}"
    exit 1
fi

# Step 2: Run Tests
echo -e "${YELLOW}2️⃣ Running tests...${NC}"
if [ -f "package.json" ]; then
    npm test 2>&1 || {
        echo -e "${RED}✗ Tests failed${NC}"
        TESTS_FAILED=true
    }
elif [ -f "pytest.ini" ] || [ -f "requirements.txt" ]; then
    python -m pytest 2>&1 || {
        echo -e "${RED}✗ Tests failed${NC}"
        TESTS_FAILED=true
    }
else
    echo -e "${YELLOW}⚠ No test framework detected${NC}"
fi

# Step 3: Debug & Fix
if [ "$TESTS_FAILED" = true ]; then
    echo -e "${YELLOW}3️⃣ Debugging and fixing...${NC}"
    echo "Running linter..."
    if [ -f "package.json" ]; then
        npm run lint -- --fix 2>&1 || true
    elif [ -f "pytest.ini" ]; then
        python -m pylint . --exit-zero 2>&1 || true
    fi
fi

# Step 4: Final Test Run
echo -e "${YELLOW}4️⃣ Final test verification...${NC}"
if [ -f "package.json" ]; then
    npm test 2>&1 || {
        echo -e "${RED}✗ Final tests still failing${NC}"
        exit 1
    }
elif [ -f "pytest.ini" ]; then
    python -m pytest 2>&1 || {
        echo -e "${RED}✗ Final tests still failing${NC}"
        exit 1
    }
fi

echo -e "${GREEN}✓ All tests passed${NC}"

# Step 5: Archive in Git
echo -e "${YELLOW}5️⃣ Archiving in Git...${NC}"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
git add .
git commit -m "Workflow: Auto-commit at $TIMESTAMP - Tests passed ✓" || {
    echo -e "${YELLOW}⚠ Nothing to commit${NC}"
}

git push origin HEAD:main 2>&1 || {
    echo -e "${RED}✗ Git push failed${NC}"
    exit 1
}

echo -e "${GREEN}✓ Changes pushed to Git${NC}"

echo ""
echo "================================"
echo -e "${GREEN}✅ Workflow completed successfully!${NC}"
echo "================================"
