#!/bin/bash

# Wellbeing Mapper Screenshot Generation Script
# This script automates the process of capturing screenshots for the app

set -e  # Exit on any error

echo "🖼️  Wellbeing Mapper Screenshot Generator"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCREENSHOTS_DIR="$PROJECT_DIR/screenshots"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

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
    print_status "Checking prerequisites..."
    
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
    
    print_success "Prerequisites check completed"
}

# Function to prepare the environment
prepare_environment() {
    print_status "Preparing environment..."
    
    # Create screenshots directory
    mkdir -p "$SCREENSHOTS_DIR"
    mkdir -p "$SCREENSHOTS_DIR/manual"
    mkdir -p "$SCREENSHOTS_DIR/automated"
    
    # Get dependencies
    print_status "Getting Flutter dependencies..."
    $FLUTTER_CMD pub get
    
    print_success "Environment prepared"
}

# Function to run basic app and capture manual screenshots
run_manual_capture() {
    print_status "Setting up for manual screenshot capture..."
    
    print_status "Starting the app in debug mode..."
    print_status "You can now manually navigate through the app and take screenshots."
    print_status "Screenshots will be saved when you run the integration test."
    
    # Check if we can run the app
    $FLUTTER_CMD doctor
    
    print_status "To capture screenshots manually:"
    print_status "1. Run: $FLUTTER_CMD run"
    print_status "2. Navigate through the app features"
    print_status "3. Use device screenshot features or simulator screenshot tools"
    print_status "4. Save screenshots to: $SCREENSHOTS_DIR/manual/"
    
    print_success "Manual capture setup completed"
}

# Function to run automated screenshot capture using integration tests
run_automated_capture() {
    print_status "Running automated screenshot capture using integration tests..."
    
    # Create a specific directory for this run
    local run_dir="$SCREENSHOTS_DIR/automated/run_$TIMESTAMP"
    mkdir -p "$run_dir"
    
    # Try different approaches for screenshot capture
    
    # Approach 1: Use flutter drive (if available)
    if [ -f "test_driver/driver.dart" ]; then
        print_status "Attempting screenshot capture with flutter drive..."
        
        # Start the app and driver
        $FLUTTER_CMD drive \
            --target=integration_test/screenshot_test.dart \
            --dart-define=FLUTTER_TEST_MODE=true \
            > "$run_dir/drive_output.log" 2>&1 || {
                print_warning "Flutter drive failed, trying alternative approach..."
            }
    fi
    
    # Approach 2: Use flutter test (fallback)
    print_status "Running integration test to capture app state..."
    
    # Run the test and capture output
    $FLUTTER_CMD test integration_test/screenshot_test.dart \
        --dart-define=FLUTTER_TEST_MODE=true \
        --reporter=expanded \
        > "$run_dir/test_output.log" 2>&1 || {
            print_warning "Integration test had issues, but may have captured some screenshots"
        }
    
    # Look for any generated screenshots
    find . -name "*.png" -type f -newer "$run_dir" -not -path "*/screenshots/*" | while read -r screenshot; do
        if [ -f "$screenshot" ]; then
            print_status "Found screenshot: $screenshot"
            cp "$screenshot" "$run_dir/"
        fi
    done
    
    print_success "Automated capture completed"
}

# Function to provide manual screenshot instructions
provide_manual_instructions() {
    print_status "Manual Screenshot Capture Instructions"
    print_status "======================================"
    
    cat << EOF

📱 iOS Simulator Screenshots:
   - Use Cmd+S in iOS Simulator
   - Or: Device > Screenshot from menu
   - Screenshots saved to Desktop by default

🤖 Android Emulator Screenshots:
   - Use camera icon in emulator controls
   - Or: Tools > Screenshot from menu
   - Screenshots saved to default location

📋 Recommended Screenshots to Capture:

1. 🚀 App Launch Screen
   - Initial loading/splash screen

2. 🔘 Participation Selection
   - Screen showing Private/Barcelona/Gauteng options
   - Each option selected

3. 📝 Survey Interface
   - Initial survey screen
   - Form fields filled out
   - Different survey types (Barcelona vs Gauteng)

4. 🗺️  Map View
   - Map with location data
   - Different zoom levels

5. ⚙️  Settings/Configuration
   - Settings menu
   - Data upload screen
   - Privacy settings

6. 📊 Data Management
   - Upload status screen
   - Data export options

7. ℹ️  Information Screens
   - Consent forms
   - Privacy policy
   - Help/about screens

💡 Tips:
   - Capture in both light and dark modes if supported
   - Include various screen states (loading, error, success)
   - Take screenshots at different device orientations
   - Capture empty states and populated states

📁 Save all screenshots to: $SCREENSHOTS_DIR/manual/
EOF

    print_success "Instructions displayed"
}

# Function to organize screenshots
organize_screenshots() {
    print_status "Organizing screenshots..."
    
    # Create organized structure
    mkdir -p "$SCREENSHOTS_DIR/organized"
    mkdir -p "$SCREENSHOTS_DIR/organized/by_type"
    mkdir -p "$SCREENSHOTS_DIR/organized/by_date"
    
    # Find all screenshot files
    find "$SCREENSHOTS_DIR" -name "*.png" -not -path "*/organized/*" | while read -r screenshot; do
        if [ -f "$screenshot" ]; then
            filename=$(basename "$screenshot")
            
            # Copy to organized folders
            cp "$screenshot" "$SCREENSHOTS_DIR/organized/by_type/"
            
            # Create date-based organization
            file_date=$(date -r "$screenshot" +"%Y-%m-%d")
            mkdir -p "$SCREENSHOTS_DIR/organized/by_date/$file_date"
            cp "$screenshot" "$SCREENSHOTS_DIR/organized/by_date/$file_date/"
            
            print_status "Organized: $filename"
        fi
    done
    
    print_success "Screenshots organized"
}

# Function to generate report
generate_report() {
    print_status "Generating screenshot report..."
    
    local report_file="$SCREENSHOTS_DIR/report.html"
    local total_screenshots=$(find "$SCREENSHOTS_DIR" -name "*.png" | wc -l)
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Wellbeing Mapper Screenshots Report</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: linear-gradient(135deg, #4CAF50, #45a049); color: white; padding: 30px; border-radius: 10px; margin-bottom: 20px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        .header h1 { margin: 0; font-size: 2.5em; }
        .header p { margin: 10px 0 0 0; opacity: 0.9; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .stat-card { background: white; padding: 20px; border-radius: 10px; text-align: center; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .stat-number { font-size: 2em; font-weight: bold; color: #4CAF50; }
        .stat-label { color: #666; margin-top: 5px; }
        .section { background: white; padding: 30px; border-radius: 10px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .section h2 { margin-top: 0; color: #333; border-bottom: 2px solid #4CAF50; padding-bottom: 10px; }
        .screenshots-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(250px, 1fr)); gap: 20px; }
        .screenshot-card { text-align: center; background: #f9f9f9; padding: 15px; border-radius: 8px; transition: transform 0.2s; }
        .screenshot-card:hover { transform: translateY(-2px); }
        .screenshot-card img { max-width: 100%; max-height: 300px; border: 2px solid #ddd; border-radius: 8px; cursor: pointer; }
        .screenshot-name { margin-top: 10px; font-size: 14px; color: #555; font-weight: 500; }
        .instructions { background: #e3f2fd; border-left: 4px solid #2196F3; padding: 20px; margin: 20px 0; border-radius: 0 8px 8px 0; }
        .footer { text-align: center; margin-top: 40px; color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🖼️ Wellbeing Mapper Screenshots</h1>
            <p>Comprehensive visual documentation of the application interface</p>
            <p>Generated on: $(date '+%B %d, %Y at %I:%M %p')</p>
        </div>
        
        <div class="stats">
            <div class="stat-card">
                <div class="stat-number">$total_screenshots</div>
                <div class="stat-label">Total Screenshots</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">$(find "$SCREENSHOTS_DIR/manual" -name "*.png" 2>/dev/null | wc -l)</div>
                <div class="stat-label">Manual Captures</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">$(find "$SCREENSHOTS_DIR/automated" -name "*.png" 2>/dev/null | wc -l)</div>
                <div class="stat-label">Automated Captures</div>
            </div>
        </div>
        
        <div class="section">
            <h2>📱 Project Information</h2>
            <p><strong>Application:</strong> Wellbeing Mapper - Privacy-focused mental wellbeing tracking</p>
            <p><strong>Flutter Version:</strong> $FLUTTER_VERSION</p>
            <p><strong>Screenshot Date:</strong> $TIMESTAMP</p>
            <p><strong>Key Features:</strong> Three-way participation system (Private/Barcelona/Gauteng), Encrypted data upload, Location tracking, Mental wellbeing surveys</p>
        </div>
EOF

    # Add screenshots if any exist
    if [ "$total_screenshots" -gt 0 ]; then
        echo '<div class="section">' >> "$report_file"
        echo '<h2>📸 Captured Screenshots</h2>' >> "$report_file"
        echo '<div class="screenshots-grid">' >> "$report_file"
        
        find "$SCREENSHOTS_DIR" -name "*.png" -not -path "*/organized/*" | while read -r screenshot; do
            if [ -f "$screenshot" ]; then
                filename=$(basename "$screenshot")
                relative_path=$(realpath --relative-to="$SCREENSHOTS_DIR" "$screenshot" 2>/dev/null || echo "$screenshot")
                echo "<div class=\"screenshot-card\">" >> "$report_file"
                echo "<img src=\"$relative_path\" alt=\"$filename\" onclick=\"window.open('$relative_path', '_blank')\">" >> "$report_file"
                echo "<div class=\"screenshot-name\">$filename</div>" >> "$report_file"
                echo "</div>" >> "$report_file"
            fi
        done
        
        echo '</div></div>' >> "$report_file"
    else
        cat >> "$report_file" << EOF
        <div class="instructions">
            <h3>📋 Next Steps</h3>
            <p>No screenshots found yet. To capture screenshots:</p>
            <ol>
                <li>Run the app: <code>$FLUTTER_CMD run</code></li>
                <li>Navigate through different screens</li>
                <li>Take screenshots using device/simulator tools</li>
                <li>Save them to: <code>$SCREENSHOTS_DIR/manual/</code></li>
                <li>Re-run this script to update the report</li>
            </ol>
        </div>
EOF
    fi

    cat >> "$report_file" << EOF
        <div class="footer">
            <p>Generated by Wellbeing Mapper Screenshot Generator</p>
            <p>For manual screenshot instructions, run: <code>./generate_screenshots.sh --help</code></p>
        </div>
    </div>
</body>
</html>
EOF
    
    print_success "Report generated: $report_file"
}

# Main execution
main() {
    print_status "Starting Wellbeing Mapper screenshot generation..."
    
    # Parse command line arguments
    MANUAL_MODE=false
    AUTOMATED_MODE=false
    INSTRUCTIONS_ONLY=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --manual)
                MANUAL_MODE=true
                shift
                ;;
            --automated)
                AUTOMATED_MODE=true
                shift
                ;;
            --instructions)
                INSTRUCTIONS_ONLY=true
                shift
                ;;
            --help)
                echo "Wellbeing Mapper Screenshot Generator"
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  --manual        Set up for manual screenshot capture"
                echo "  --automated     Attempt automated screenshot capture"
                echo "  --instructions  Show detailed screenshot instructions"
                echo "  --help          Show this help message"
                echo ""
                echo "Default behavior (no options): Show instructions and prepare environment"
                exit 0
                ;;
            *)
                print_warning "Unknown option: $1"
                shift
                ;;
        esac
    done
    
    # Run the screenshot process
    check_prerequisites
    prepare_environment
    
    if [ "$INSTRUCTIONS_ONLY" = true ]; then
        provide_manual_instructions
    elif [ "$AUTOMATED_MODE" = true ]; then
        run_automated_capture
    elif [ "$MANUAL_MODE" = true ]; then
        run_manual_capture
    else
        # Default: provide instructions and prepare
        provide_manual_instructions
        run_manual_capture
    fi
    
    organize_screenshots
    generate_report
    
    print_success "Screenshot generation process completed!"
    print_status "Results saved in: $SCREENSHOTS_DIR"
    print_status "Open $SCREENSHOTS_DIR/report.html to view the report"
    
    # Helpful next steps
    echo ""
    print_status "📋 Next Steps:"
    print_status "1. Run '$FLUTTER_CMD run' to start the app"
    print_status "2. Navigate through the app and take screenshots"
    print_status "3. Save screenshots to $SCREENSHOTS_DIR/manual/"
    print_status "4. Re-run this script to update the report"
}

# Run main function with all arguments
main "$@"
