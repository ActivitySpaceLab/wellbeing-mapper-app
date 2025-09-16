#!/bin/bash

# Apple App Store iPhone Screenshots Generator
# This script generates screenshots specifically for App Store submission

set -e  # Exit on any error

echo "📱 Apple App Store iPhone Screenshots Generator"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCREENSHOTS_DIR="$PROJECT_DIR/screenshots/app_store"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Apple App Store required iPhone screen sizes
IPHONE_DEVICES=("iPhone-15-Pro-Max" "iPhone-15-Pro" "iPhone-8-Plus")
IPHONE_SIZES=("430x932" "393x852" "414x736")
IPHONE_DESCRIPTIONS=("6.7\" Display - Required" "6.1\" Display - Required" "5.5\" Display - Optional")

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites for App Store screenshot generation..."
    
    # Check if Flutter is installed
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    
    # Check if FVM is being used and available
    if command -v fvm &> /dev/null; then
        print_status "Using FVM for Flutter version management"
        FLUTTER_CMD="fvm flutter"
    else
        print_warning "FVM not found, using system Flutter"
        FLUTTER_CMD="flutter"
    fi
    
    # Check Flutter version
    FLUTTER_VERSION=$($FLUTTER_CMD --version | head -n 1 | cut -d ' ' -f 2)
    print_status "Flutter version: $FLUTTER_VERSION"
    
    # Verify we're in the correct directory
    if [ ! -f "pubspec.yaml" ]; then
        print_error "pubspec.yaml not found. Please run this script from the Flutter project root."
        exit 1
    fi
    
    # Check if integration test exists
    if [ ! -f "integration_test/screenshot_test.dart" ]; then
        print_error "Screenshot integration test not found at integration_test/screenshot_test.dart"
        exit 1
    fi
    
    print_success "Prerequisites check completed"
}

# Function to prepare the environment
prepare_environment() {
    print_status "Preparing environment for App Store screenshot generation..."
    
    # Create App Store specific screenshots directory
    mkdir -p "$SCREENSHOTS_DIR"
    mkdir -p "$SCREENSHOTS_DIR/iPhone-15-Pro-Max"
    mkdir -p "$SCREENSHOTS_DIR/iPhone-15-Pro"  
    mkdir -p "$SCREENSHOTS_DIR/iPhone-8-Plus"
    
    # Create run-specific directory
    local run_dir="$SCREENSHOTS_DIR/run_$TIMESTAMP"
    mkdir -p "$run_dir"
    
    # Get dependencies
    print_status "Getting Flutter dependencies..."
    $FLUTTER_CMD pub get
    
    print_success "Environment prepared"
}

# Function to generate screenshots for a specific iPhone size
generate_screenshots_for_device() {
    local device_name="$1"
    local screen_size="$2"
    
    print_status "Generating App Store screenshots for $device_name ($screen_size)..."
    
    # Create device-specific directory
    local device_dir="$SCREENSHOTS_DIR/$device_name"
    mkdir -p "$device_dir"
    
    # Run integration test to capture screenshots
    print_status "Running integration test for $device_name..."
    
    # Set device-specific environment variables
    export FLUTTER_TEST_DEVICE_NAME="$device_name"
    export FLUTTER_TEST_SCREEN_SIZE="$screen_size"
    
    # Run the integration test
    $FLUTTER_CMD test integration_test/screenshot_test.dart \
        --dart-define=FLUTTER_TEST_MODE=true \
        --dart-define=DEVICE_NAME="$device_name" \
        --dart-define=SCREEN_SIZE="$screen_size" \
        --reporter=expanded \
        > "$device_dir/test_output_$TIMESTAMP.log" 2>&1 || {
            print_warning "Integration test completed with warnings for $device_name"
        }
    
    # Look for generated screenshots and organize them
    find . -name "screenshot_*.png" -type f -newer "$device_dir" 2>/dev/null | while read -r screenshot; do
        if [ -f "$screenshot" ]; then
            local filename=$(basename "$screenshot")
            local new_name="${device_name}_${filename}"
            print_status "Found screenshot: $screenshot -> $device_dir/$new_name"
            cp "$screenshot" "$device_dir/$new_name"
            rm "$screenshot"  # Clean up original
        fi
    done
    
    # Also check for screenshots in typical Flutter locations
    for screenshot_pattern in "test/screenshots/*.png" "screenshots/*.png" "integration_test/screenshots/*.png"; do
        find . -path "./$screenshot_pattern" -type f 2>/dev/null | while read -r screenshot; do
            if [ -f "$screenshot" ]; then
                local filename=$(basename "$screenshot")
                local new_name="${device_name}_${filename}"
                print_status "Moving screenshot: $screenshot -> $device_dir/$new_name"
                cp "$screenshot" "$device_dir/$new_name"
            fi
        done
    done
    
    print_success "Screenshots generated for $device_name"
}

# Function to organize and finalize screenshots
finalize_screenshots() {
    print_status "Finalizing App Store screenshots..."
    
    # Create a summary of what was generated
    local summary_file="$SCREENSHOTS_DIR/app_store_screenshots_summary_$TIMESTAMP.txt"
    
    echo "Apple App Store iPhone Screenshots Generated on $(date)" > "$summary_file"
    echo "========================================================" >> "$summary_file"
    echo "" >> "$summary_file"
    
    # List screenshots for each device
    for i in "${!IPHONE_DEVICES[@]}"; do
        local device="${IPHONE_DEVICES[$i]}"
        local size="${IPHONE_SIZES[$i]}"
        local description="${IPHONE_DESCRIPTIONS[$i]}"
        
        echo "Device: $device ($size - $description)" >> "$summary_file"
        echo "Screenshots:" >> "$summary_file"
        
        local device_dir="$SCREENSHOTS_DIR/$device"
        if [ -d "$device_dir" ]; then
            find "$device_dir" -name "*.png" -type f | sort | while read -r screenshot; do
                local filename=$(basename "$screenshot")
                local filesize=$(du -h "$screenshot" | cut -f1)
                echo "  - $filename ($filesize)" >> "$summary_file"
            done
        else
            echo "  - No screenshots generated" >> "$summary_file"
        fi
        echo "" >> "$summary_file"
    done
    
    # Add App Store submission instructions
    echo "App Store Submission Instructions:" >> "$summary_file"
    echo "1. Upload screenshots for iPhone 6.7\" Display (iPhone-15-Pro-Max)" >> "$summary_file"
    echo "2. Upload screenshots for iPhone 6.1\" Display (iPhone-15-Pro)" >> "$summary_file"
    echo "3. Optionally upload screenshots for iPhone 5.5\" Display (iPhone-8-Plus)" >> "$summary_file"
    echo "4. Ensure screenshots are in PNG format and meet Apple's requirements" >> "$summary_file"
    echo "5. Screenshots should be 1290×2796 pixels for 6.7\" and 1179×2556 pixels for 6.1\"" >> "$summary_file"
    
    print_status "Summary written to: $summary_file"
    print_success "App Store screenshots finalization completed"
}

# Main execution function
main() {
    print_status "Starting Apple App Store iPhone screenshots generation..."
    
    check_prerequisites
    prepare_environment
    
    # Generate screenshots for each required iPhone size
    for i in "${!IPHONE_DEVICES[@]}"; do
        local device="${IPHONE_DEVICES[$i]}"
        local size="${IPHONE_SIZES[$i]}"
        generate_screenshots_for_device "$device" "$size"
    done
    
    finalize_screenshots
    
    print_success "🎉 App Store iPhone screenshots generation completed!"
    print_status "Screenshots are available in: $SCREENSHOTS_DIR"
    print_status "Upload these screenshots to App Store Connect for your app submission."
}

# Show usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Generate iPhone screenshots for Apple App Store submission"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --verbose  Enable verbose output"
    echo ""
    echo "This script generates screenshots for the following iPhone sizes:"
    echo "  - iPhone 6.7\" Display (iPhone 15 Pro Max) - Required"
    echo "  - iPhone 6.1\" Display (iPhone 15 Pro) - Required"
    echo "  - iPhone 5.5\" Display (iPhone 8 Plus) - Optional"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -v|--verbose)
            set -x  # Enable verbose mode
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Run the main function
main
