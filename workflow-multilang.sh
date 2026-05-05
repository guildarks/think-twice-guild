#!/bin/bash

# ============================================
# Universal Workflow Automation - All Languages
# Auto-detects language and runs appropriate workflow
# Usage: ./workflow-multilang.sh [project-dir]
# ============================================

set -e

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Universal Workflow Automation${NC}"
echo "================================"
echo "Project: $(pwd)"
echo ""

# ============================================
# DETECT LANGUAGE
# ============================================

detect_language() {
    if [ -f "package.json" ]; then echo "node"; fi
    if [ -f "requirements.txt" ] || [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then echo "python"; fi
    if [ -f "go.mod" ]; then echo "go"; fi
    if [ -f "Cargo.toml" ]; then echo "rust"; fi
    if [ -f "pom.xml" ]; then echo "maven"; fi
    if [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then echo "gradle"; fi
    if [ -f ".csproj" ] || [ -f ".sln" ]; then echo "csharp"; fi
    if [ -f "composer.json" ]; then echo "php"; fi
    if [ -f "Gemfile" ]; then echo "ruby"; fi
    if [ -f "Makefile" ]; then echo "make"; fi
}

LANGUAGE=$(detect_language | head -n1)

if [ -z "$LANGUAGE" ]; then
    echo -e "${RED}✗ Could not detect language${NC}"
    echo "Supported: Node, Python, Go, Rust, Java, C#, PHP, Ruby, Make"
    exit 1
fi

echo -e "${YELLOW}📝 Detected Language: ${BLUE}$LANGUAGE${NC}"

# ============================================
# STEP 1: DETECT CHANGES
# ============================================

echo -e "${YELLOW}1️⃣ Detecting changes...${NC}"
if git status --porcelain | grep -q .; then
    echo -e "${GREEN}✓ Changes detected${NC}"
else
    echo -e "${RED}✗ No changes to process${NC}"
    exit 0
fi

# ============================================
# STEP 2: RUN TESTS (Language-Specific)
# ============================================

echo -e "${YELLOW}2️⃣ Running tests...${NC}"
TESTS_FAILED=false

case "$LANGUAGE" in
    node)
        echo "Running: npm test"
        npm test 2>&1 || TESTS_FAILED=true
        ;;
    python)
        echo "Running: pytest or python -m unittest"
        if python -m pytest 2>&1; then
            echo -e "${GREEN}✓ pytest passed${NC}"
        elif python -m unittest discover 2>&1; then
            echo -e "${GREEN}✓ unittest passed${NC}"
        else
            TESTS_FAILED=true
        fi
        ;;
    go)
        echo "Running: go test ./..."
        go test ./... 2>&1 || TESTS_FAILED=true
        ;;
    rust)
        echo "Running: cargo test"
        cargo test 2>&1 || TESTS_FAILED=true
        ;;
    maven)
        echo "Running: mvn test"
        mvn test 2>&1 || TESTS_FAILED=true
        ;;
    gradle)
        echo "Running: gradle test"
        gradle test 2>&1 || TESTS_FAILED=true
        ;;
    csharp)
        echo "Running: dotnet test"
        dotnet test 2>&1 || TESTS_FAILED=true
        ;;
    php)
        echo "Running: phpunit"
        phpunit 2>&1 || TESTS_FAILED=true
        ;;
    ruby)
        echo "Running: rspec or rake test"
        if command -v rspec &> /dev/null; then
            rspec 2>&1 || TESTS_FAILED=true
        else
            rake test 2>&1 || TESTS_FAILED=true
        fi
        ;;
    make)
        echo "Running: make test"
        make test 2>&1 || TESTS_FAILED=true
        ;;
esac

if [ "$TESTS_FAILED" = true ]; then
    echo -e "${RED}✗ Tests failed${NC}"
fi

# ============================================
# STEP 3: DEBUG & FIX
# ============================================

if [ "$TESTS_FAILED" = true ]; then
    echo -e "${YELLOW}3️⃣ Attempting auto-fix...${NC}"

    case "$LANGUAGE" in
        node)
            echo "Running: npm run lint -- --fix"
            npm run lint -- --fix 2>&1 || true
            ;;
        python)
            echo "Running: autopep8 and black"
            autopep8 --in-place --aggressive --recursive . 2>&1 || true
            black . 2>&1 || true
            ;;
        go)
            echo "Running: gofmt"
            gofmt -w . 2>&1 || true
            ;;
        rust)
            echo "Running: cargo fmt"
            cargo fmt 2>&1 || true
            ;;
        csharp)
            echo "Running: dotnet format"
            dotnet format 2>&1 || true
            ;;
        php)
            echo "Running: php-cs-fixer"
            php-cs-fixer fix . 2>&1 || true
            ;;
        ruby)
            echo "Running: rubocop --auto-correct"
            rubocop --auto-correct 2>&1 || true
            ;;
    esac
fi

# ============================================
# STEP 4: FINAL TEST RUN
# ============================================

echo -e "${YELLOW}4️⃣ Final test verification...${NC}"
FINAL_FAILED=false

case "$LANGUAGE" in
    node)
        npm test 2>&1 || FINAL_FAILED=true
        ;;
    python)
        python -m pytest 2>&1 || python -m unittest discover 2>&1 || FINAL_FAILED=true
        ;;
    go)
        go test ./... 2>&1 || FINAL_FAILED=true
        ;;
    rust)
        cargo test 2>&1 || FINAL_FAILED=true
        ;;
    maven)
        mvn test 2>&1 || FINAL_FAILED=true
        ;;
    gradle)
        gradle test 2>&1 || FINAL_FAILED=true
        ;;
    csharp)
        dotnet test 2>&1 || FINAL_FAILED=true
        ;;
    php)
        phpunit 2>&1 || FINAL_FAILED=true
        ;;
    ruby)
        (rspec 2>&1 || rake test 2>&1) || FINAL_FAILED=true
        ;;
esac

if [ "$FINAL_FAILED" = true ]; then
    echo -e "${RED}✗ Final tests failed${NC}"
    echo "Please review and fix manually"
    exit 1
fi

echo -e "${GREEN}✓ All tests passed${NC}"

# ============================================
# STEP 5: GIT ARCHIVE
# ============================================

echo -e "${YELLOW}5️⃣ Archiving in Git...${NC}"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

git add .
git commit -m "Workflow [$LANGUAGE]: Auto-commit at $TIMESTAMP - All tests passed ✓" 2>&1 || {
    echo -e "${YELLOW}⚠ Nothing new to commit${NC}"
}

if git push origin HEAD:main 2>&1; then
    echo -e "${GREEN}✓ Pushed to Git${NC}"
else
    echo -e "${YELLOW}⚠ Push failed (remote may not exist)${NC}"
fi

# ============================================
# COMPLETE
# ============================================

echo ""
echo "================================"
echo -e "${GREEN}✅ Workflow completed!${NC}"
echo -e "Language: ${BLUE}$LANGUAGE${NC}"
echo -e "Time: ${BLUE}$TIMESTAMP${NC}"
echo "================================"
