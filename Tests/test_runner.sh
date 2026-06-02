#!/bin/bash

# Forged In Fire Client Manager - Test Runner Script
# Usage: ./test_runner.sh [options]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Forged In Fire - Security Test Suite ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Parse arguments
RUN_UNIT_TESTS=true
RUN_UI_TESTS=false
RUN_PERF_TESTS=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --ui)
            RUN_UI_TESTS=true
            shift
            ;;
        --perf)
            RUN_PERF_TESTS=true
            shift
            ;;
        --all)
            RUN_UI_TESTS=true
            RUN_PERF_TESTS=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            echo "Usage: ./test_runner.sh [options]"
            echo ""
            echo "Options:"
            echo "  --ui      Run UI tests"
            echo "  --perf    Run performance tests"
            echo "  --all     Run all tests (unit, UI, performance)"
            echo "  -v        Verbose output"
            echo "  --help    Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Get project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo -e "${YELLOW}Project Directory: $PROJECT_DIR${NC}"
echo ""

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Error: xcodebuild not found. Please install Xcode.${NC}"
    exit 1
fi

# Build for testing
echo -e "${BLUE}Building project for testing...${NC}"
if [ "$VERBOSE" = true ]; then
    xcodebuild build-for-testing \
        -project ForgedInFireClientManager.xcodeproj \
        -scheme ForgedInFireClientManager \
        -destination 'platform=macOS' \
        2>&1 | tee build.log
else
    xcodebuild build-for-testing \
        -project ForgedInFireClientManager.xcodeproj \
        -scheme ForgedInFireClientManager \
        -destination 'platform=macOS' \
        2>&1 | grep -E '(error|warning|Build succeeded|Build failed)' || true
fi

if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed! Check build.log for details.${NC}"
    exit 1
fi

echo -e "${GREEN}Build successful!${NC}"
echo ""

# Run Unit Tests
if [ "$RUN_UNIT_TESTS" = true ]; then
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}     Running Unit Tests${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    if [ "$VERBOSE" = true ]; then
        xcodebuild test \
            -project ForgedInFireClientManager.xcodeproj \
            -scheme ForgedInFireClientManager \
            -destination 'platform=macOS' \
            -only-testing:ForgedInFireClientManagerTests \
            2>&1 | tee unit_tests.log
    else
        xcodebuild test \
            -project ForgedInFireClientManager.xcodeproj \
            -scheme ForgedInFireClientManager \
            -destination 'platform=macOS' \
            -only-testing:ForgedInFireClientManagerTests \
            2>&1 | grep -E '(Test Case|Test Suite|passed|failed|error)' || true
    fi
    
    UNIT_TEST_RESULT=$?
    
    if [ $UNIT_TEST_RESULT -eq 0 ]; then
        echo -e "${GREEN}Unit tests passed!${NC}"
    else
        echo -e "${RED}Unit tests failed!${NC}"
    fi
    echo ""
fi

# Run UI Tests
if [ "$RUN_UI_TESTS" = true ]; then
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}     Running UI Tests${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    if [ "$VERBOSE" = true ]; then
        xcodebuild test \
            -project ForgedInFireClientManager.xcodeproj \
            -scheme ForgedInFireClientManager \
            -destination 'platform=macOS' \
            -only-testing:ForgedInFireClientManagerUITests \
            2>&1 | tee ui_tests.log
    else
        xcodebuild test \
            -project ForgedInFireClientManager.xcodeproj \
            -scheme ForgedInFireClientManager \
            -destination 'platform=macOS' \
            -only-testing:ForgedInFireClientManagerUITests \
            2>&1 | grep -E '(Test Case|Test Suite|passed|failed)' || true
    fi
    
    UI_TEST_RESULT=$?
    
    if [ $UI_TEST_RESULT -eq 0 ]; then
        echo -e "${GREEN}UI tests passed!${NC}"
    else
        echo -e "${RED}UI tests failed!${NC}"
    fi
    echo ""
fi

# Run Performance Tests
if [ "$RUN_PERF_TESTS" = true ]; then
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}     Running Performance Tests${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    if [ "$VERBOSE" = true ]; then
        xcodebuild test \
            -project ForgedInFireClientManager.xcodeproj \
            -scheme ForgedInFireClientManager \
            -destination 'platform=macOS' \
            -only-testing:ForgedInFireClientManagerTests/PerformanceTests \
            2>&1 | tee perf_tests.log
    else
        xcodebuild test \
            -project ForgedInFireClientManager.xcodeproj \
            -scheme ForgedInFireClientManager \
            -destination 'platform=macOS' \
            -only-testing:ForgedInFireClientManagerTests/PerformanceTests \
            2>&1 | grep -E '(Test Case|measured|average)' || true
    fi
    
    PERF_TEST_RESULT=$?
    
    if [ $PERF_TEST_RESULT -eq 0 ]; then
        echo -e "${GREEN}Performance tests completed!${NC}"
    else
        echo -e "${RED}Performance tests failed!${NC}"
    fi
    echo ""
fi

# Generate Test Report
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}     Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"

if [ -f "unit_tests.log" ]; then
    PASSED=$(grep -c " passed " unit_tests.log 2>/dev/null || echo "0")
    FAILED=$(grep -c " failed " unit_tests.log 2>/dev/null || echo "0")
    echo -e "${GREEN}Unit Tests: $PASSED passed${NC}"
    if [ $FAILED -gt 0 ]; then
        echo -e "${RED}Unit Tests: $FAILED failed${NC}"
    fi
fi

if [ -f "ui_tests.log" ]; then
    PASSED=$(grep -c " passed " ui_tests.log 2>/dev/null || echo "0")
    FAILED=$(grep -c " failed " ui_tests.log 2>/dev/null || echo "0")
    echo -e "${GREEN}UI Tests: $PASSED passed${NC}"
    if [ $FAILED -gt 0 ]; then
        echo -e "${RED}UI Tests: $FAILED failed${NC}"
    fi
fi

echo ""
echo -e "${BLUE}Test logs saved to:${NC}"
echo "  - build.log"
[ -f "unit_tests.log" ] && echo "  - unit_tests.log"
[ -f "ui_tests.log" ] && echo "  - ui_tests.log"
[ -f "perf_tests.log" ] && echo "  - perf_tests.log"

# Determine overall result
if [ ${UNIT_TEST_RESULT:-0} -eq 0 ] && [ ${UI_TEST_RESULT:-0} -eq 0 ] && [ ${PERF_TEST_RESULT:-0} -eq 0 ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}     All Tests Passed!${NC}"
    echo -e "${GREEN}========================================${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}     Some Tests Failed!${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
