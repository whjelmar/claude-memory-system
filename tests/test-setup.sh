#!/bin/bash
# Test suite for setup.sh script
# Run from project root: bash tests/test-setup.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Get the directory containing this test script
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$TEST_DIR")"
SETUP_SCRIPT="$PROJECT_ROOT/setup.sh"

# Create a temporary directory for tests
TEST_TEMP_DIR=""

# Setup function - called before each test
setup_test() {
    TEST_TEMP_DIR=$(mktemp -d)
    echo "  Test dir: $TEST_TEMP_DIR"
}

# Teardown function - called after each test
teardown_test() {
    if [ -n "$TEST_TEMP_DIR" ] && [ -d "$TEST_TEMP_DIR" ]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Assert function
assert_true() {
    local condition="$1"
    local message="$2"

    if eval "$condition"; then
        echo -e "    ${GREEN}PASS${NC}: $message"
        return 0
    else
        echo -e "    ${RED}FAIL${NC}: $message"
        return 1
    fi
}

# Assert file exists
assert_file_exists() {
    local file="$1"
    local message="${2:-File exists: $file}"

    if [ -f "$file" ]; then
        echo -e "    ${GREEN}PASS${NC}: $message"
        return 0
    else
        echo -e "    ${RED}FAIL${NC}: $message (file not found)"
        return 1
    fi
}

# Assert directory exists
assert_dir_exists() {
    local dir="$1"
    local message="${2:-Directory exists: $dir}"

    if [ -d "$dir" ]; then
        echo -e "    ${GREEN}PASS${NC}: $message"
        return 0
    else
        echo -e "    ${RED}FAIL${NC}: $message (directory not found)"
        return 1
    fi
}

# Assert file contains string
assert_file_contains() {
    local file="$1"
    local string="$2"
    local message="${3:-File $file contains '$string'}"

    if grep -q "$string" "$file" 2>/dev/null; then
        echo -e "    ${GREEN}PASS${NC}: $message"
        return 0
    else
        echo -e "    ${RED}FAIL${NC}: $message (string not found)"
        return 1
    fi
}

# Run a test
run_test() {
    local test_name="$1"
    local test_func="$2"

    echo ""
    echo -e "${YELLOW}Running:${NC} $test_name"
    TESTS_RUN=$((TESTS_RUN + 1))

    setup_test

    if $test_func; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "  ${GREEN}TEST PASSED${NC}"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "  ${RED}TEST FAILED${NC}"
    fi

    teardown_test
}

# ============================================================================
# Test Cases
# ============================================================================

test_creates_directory_structure() {
    local result=0

    # Run setup script
    bash "$SETUP_SCRIPT" "$TEST_TEMP_DIR" > /dev/null 2>&1

    # Check directories were created
    assert_dir_exists "$TEST_TEMP_DIR/.claude/memory/sessions" "Sessions directory created" || result=1
    assert_dir_exists "$TEST_TEMP_DIR/.claude/memory/decisions" "Decisions directory created" || result=1
    assert_dir_exists "$TEST_TEMP_DIR/.claude/memory/knowledge" "Knowledge directory created" || result=1
    assert_dir_exists "$TEST_TEMP_DIR/.claude/plans" "Plans directory created" || result=1

    return $result
}

test_creates_template_files() {
    local result=0

    # Run setup script
    bash "$SETUP_SCRIPT" "$TEST_TEMP_DIR" > /dev/null 2>&1

    # Check template files were created
    assert_file_exists "$TEST_TEMP_DIR/.claude/memory/ARCHITECTURE.md" "ARCHITECTURE.md created" || result=1
    assert_file_exists "$TEST_TEMP_DIR/.claude/memory/USAGE.md" "USAGE.md created" || result=1
    assert_file_exists "$TEST_TEMP_DIR/.claude/memory/current_context.md" "current_context.md created" || result=1
    assert_file_exists "$TEST_TEMP_DIR/.claude/plans/active_plan.md" "active_plan.md created" || result=1
    assert_file_exists "$TEST_TEMP_DIR/.claude/plans/findings.md" "findings.md created" || result=1
    assert_file_exists "$TEST_TEMP_DIR/.claude/plans/progress.md" "progress.md created" || result=1

    return $result
}

test_creates_gitkeep_files() {
    local result=0

    # Run setup script
    bash "$SETUP_SCRIPT" "$TEST_TEMP_DIR" > /dev/null 2>&1

    # Check .gitkeep files were created
    assert_file_exists "$TEST_TEMP_DIR/.claude/memory/sessions/.gitkeep" ".gitkeep in sessions" || result=1
    assert_file_exists "$TEST_TEMP_DIR/.claude/memory/decisions/.gitkeep" ".gitkeep in decisions" || result=1
    assert_file_exists "$TEST_TEMP_DIR/.claude/memory/knowledge/.gitkeep" ".gitkeep in knowledge" || result=1

    return $result
}

test_creates_claude_md() {
    local result=0

    # Run setup script
    bash "$SETUP_SCRIPT" "$TEST_TEMP_DIR" > /dev/null 2>&1

    # Check CLAUDE.md was created
    assert_file_exists "$TEST_TEMP_DIR/CLAUDE.md" "CLAUDE.md created" || result=1
    assert_file_contains "$TEST_TEMP_DIR/CLAUDE.md" "Session Continuity System" "CLAUDE.md contains memory section" || result=1

    return $result
}

test_updates_existing_claude_md() {
    local result=0

    # Create existing CLAUDE.md
    echo "# Existing CLAUDE.md" > "$TEST_TEMP_DIR/CLAUDE.md"
    echo "" >> "$TEST_TEMP_DIR/CLAUDE.md"
    echo "Some existing content." >> "$TEST_TEMP_DIR/CLAUDE.md"

    # Run setup script
    bash "$SETUP_SCRIPT" "$TEST_TEMP_DIR" > /dev/null 2>&1

    # Check CLAUDE.md was updated but preserved existing content
    assert_file_contains "$TEST_TEMP_DIR/CLAUDE.md" "Existing CLAUDE.md" "Existing content preserved" || result=1
    assert_file_contains "$TEST_TEMP_DIR/CLAUDE.md" "Some existing content" "Existing content preserved (line 2)" || result=1
    assert_file_contains "$TEST_TEMP_DIR/CLAUDE.md" "Session Continuity System" "Memory section added" || result=1

    return $result
}

test_idempotency_directories() {
    local result=0

    # Run setup script twice
    bash "$SETUP_SCRIPT" "$TEST_TEMP_DIR" > /dev/null 2>&1
    bash "$SETUP_SCRIPT" "$TEST_TEMP_DIR" > /dev/null 2>&1

    # Directories should still exist and only be created once
    assert_dir_exists "$TEST_TEMP_DIR/.claude/memory/sessions" "Sessions directory exists after second run" || result=1
    assert_dir_exists "$TEST_TEMP_DIR/.claude/memory/decisions" "Decisions directory exists after second run" || result=1
    assert_dir_exists "$TEST_TEMP_DIR/.claude/memory/knowledge" "Knowledge directory exists after second run" || result=1

    return $result
}

test_idempotency_claude_md() {
    local result=0

    # Run setup script twice
    bash "$SETUP_SCRIPT" "$TEST_TEMP_DIR" > /dev/null 2>&1
    bash "$SETUP_SCRIPT" "$TEST_TEMP_DIR" > /dev/null 2>&1

    # CLAUDE.md should only have memory section once
    local count=$(grep -c "Session Continuity System" "$TEST_TEMP_DIR/CLAUDE.md" || true)

    if [ "$count" -eq 1 ]; then
        echo -e "    ${GREEN}PASS${NC}: Memory section appears exactly once"
    else
        echo -e "    ${RED}FAIL${NC}: Memory section appears $count times (expected 1)"
        result=1
    fi

    return $result
}

test_preserves_customized_files() {
    local result=0

    # Run setup script first time
    bash "$SETUP_SCRIPT" "$TEST_TEMP_DIR" > /dev/null 2>&1

    # Customize current_context.md (remove template markers)
    echo "# Current Context" > "$TEST_TEMP_DIR/.claude/memory/current_context.md"
    echo "" >> "$TEST_TEMP_DIR/.claude/memory/current_context.md"
    echo "Custom context from previous session." >> "$TEST_TEMP_DIR/.claude/memory/current_context.md"

    # Run setup script again
    bash "$SETUP_SCRIPT" "$TEST_TEMP_DIR" > /dev/null 2>&1

    # Customized file should be preserved
    assert_file_contains "$TEST_TEMP_DIR/.claude/memory/current_context.md" "Custom context from previous session" "Customized file preserved" || result=1

    return $result
}

test_install_skills_flag() {
    local result=0

    # Create fake skills directory for testing
    mkdir -p "$TEST_TEMP_DIR/fake-skills"

    # Skip this test if skills directory doesn't exist in project
    if [ ! -d "$PROJECT_ROOT/skills" ]; then
        echo -e "    ${YELLOW}SKIP${NC}: Skills directory not found in project"
        return 0
    fi

    # Create a fake home directory for testing
    export HOME="$TEST_TEMP_DIR/home"
    mkdir -p "$HOME"

    # Run setup with --install-skills
    bash "$SETUP_SCRIPT" "$TEST_TEMP_DIR/project" --install-skills > /dev/null 2>&1

    # Check if skills were installed to ~/.claude/skills
    if [ -d "$HOME/.claude/skills" ]; then
        local skill_count=$(ls -1 "$HOME/.claude/skills"/*.md 2>/dev/null | wc -l)
        if [ "$skill_count" -gt 0 ]; then
            echo -e "    ${GREEN}PASS${NC}: Skills installed ($skill_count files)"
        else
            echo -e "    ${RED}FAIL${NC}: No skill files installed"
            result=1
        fi
    else
        echo -e "    ${RED}FAIL${NC}: Skills directory not created"
        result=1
    fi

    return $result
}

test_full_flag() {
    local result=0

    # Skip if no skills
    if [ ! -d "$PROJECT_ROOT/skills" ]; then
        echo -e "    ${YELLOW}SKIP${NC}: Skills directory not found in project"
        return 0
    fi

    # Create a fake home directory for testing
    export HOME="$TEST_TEMP_DIR/home"
    mkdir -p "$HOME"

    # Run setup with --full (should install skills and build MCP)
    bash "$SETUP_SCRIPT" "$TEST_TEMP_DIR/project" --full > /dev/null 2>&1

    # Check base setup worked
    assert_dir_exists "$TEST_TEMP_DIR/project/.claude/memory" "Memory directory created with --full" || result=1

    # Check skills were installed
    if [ -d "$HOME/.claude/skills" ]; then
        echo -e "    ${GREEN}PASS${NC}: Skills directory created with --full"
    else
        echo -e "    ${RED}FAIL${NC}: Skills not installed with --full"
        result=1
    fi

    return $result
}

test_unknown_option_fails() {
    local result=0

    # Run setup with unknown option
    if bash "$SETUP_SCRIPT" "$TEST_TEMP_DIR" --unknown-option > /dev/null 2>&1; then
        echo -e "    ${RED}FAIL${NC}: Should have failed with unknown option"
        result=1
    else
        echo -e "    ${GREEN}PASS${NC}: Correctly failed with unknown option"
    fi

    return $result
}

test_default_to_current_directory() {
    local result=0

    # Change to temp directory and run setup without path argument
    cd "$TEST_TEMP_DIR"
    bash "$SETUP_SCRIPT" > /dev/null 2>&1

    # Check that setup ran in current directory
    assert_dir_exists "$TEST_TEMP_DIR/.claude/memory" "Setup ran in current directory" || result=1

    # Change back
    cd "$PROJECT_ROOT"

    return $result
}

# ============================================================================
# Main test runner
# ============================================================================

echo "========================================"
echo "Claude Memory System Setup Script Tests"
echo "========================================"
echo ""
echo "Project root: $PROJECT_ROOT"
echo "Setup script: $SETUP_SCRIPT"

# Verify setup script exists
if [ ! -f "$SETUP_SCRIPT" ]; then
    echo -e "${RED}ERROR${NC}: Setup script not found at $SETUP_SCRIPT"
    exit 1
fi

# Run all tests
run_test "Creates directory structure" test_creates_directory_structure
run_test "Creates template files" test_creates_template_files
run_test "Creates .gitkeep files" test_creates_gitkeep_files
run_test "Creates CLAUDE.md" test_creates_claude_md
run_test "Updates existing CLAUDE.md" test_updates_existing_claude_md
run_test "Idempotency - directories" test_idempotency_directories
run_test "Idempotency - CLAUDE.md" test_idempotency_claude_md
run_test "Preserves customized files" test_preserves_customized_files
run_test "Install skills flag" test_install_skills_flag
run_test "Full flag" test_full_flag
run_test "Unknown option fails" test_unknown_option_fails
run_test "Default to current directory" test_default_to_current_directory

# Print summary
echo ""
echo "========================================"
echo "Test Summary"
echo "========================================"
echo ""
echo -e "Tests run: $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
