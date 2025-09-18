#!/bin/bash

# Automated Tablet Screenshot Generator for Google Play Store
# This script generates screenshots for 7-inch and 10-inch tablets

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
SCREENSHOTS_DIR="$PROJECT_DIR/screenshots/tablet_screenshots"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RUN_DIR="$SCREENSHOTS_DIR/run_$TIMESTAMP"

# Device configurations for tablets
declare -A TABLET_CONFIGS
TABLET_CONFIGS[tablet_7inch]="1920x1200@320"
TABLET_CONFIGS[tablet_10inch]="2560x1600@320"

echo -e "${BLUE}🚀 Starting Tablet Screenshot Generation${NC}"
echo -e "${BLUE}📁 Project Directory: $PROJECT_DIR${NC}"
echo -e "${BLUE}📸 Screenshots will be saved to: $RUN_DIR${NC}"

# Create screenshots directory
mkdir -p "$RUN_DIR"

# Function to check if fvm is available
check_fvm() {
    if command -v fvm &> /dev/null; then
        echo -e "${GREEN}✅ Using fvm for Flutter commands${NC}"
        FLUTTER_CMD="fvm flutter"
    else
        echo -e "${YELLOW}⚠️  fvm not found, using system flutter${NC}"
        FLUTTER_CMD="flutter"
    fi
}

# Function to get connected devices
get_devices() {
    echo -e "${BLUE}📱 Checking connected devices...${NC}"
    $FLUTTER_CMD devices --machine | jq -r '.[] | select(.type == "physical" or .type == "emulator") | "\(.id)|\(.name)|\(.platform)"'
}

# Function to create AVD if needed
create_avd() {
    local avd_name=$1
    local device_config=$2
    
    echo -e "${BLUE}📱 Checking if AVD '$avd_name' exists...${NC}"
    
    if ! avdmanager list avd | grep -q "$avd_name"; then
        echo -e "${YELLOW}⚠️  AVD '$avd_name' not found. Creating...${NC}"
        
        # Parse device config
        IFS='x@' read -r width height dpi <<< "$device_config"
        
        # Create AVD
        echo "no" | avdmanager create avd \
            -n "$avd_name" \
            -k "system-images;android-34;google_apis;arm64-v8a" \
            -d "pixel_xl" \
            --force
        
        # Configure AVD for tablet resolution
        local avd_config="$HOME/.android/avd/${avd_name}.avd/config.ini"
        if [ -f "$avd_config" ]; then
            # Update display settings
            sed -i.bak "s/hw.lcd.width=.*/hw.lcd.width=${width}/" "$avd_config"
            sed -i.bak "s/hw.lcd.height=.*/hw.lcd.height=${height}/" "$avd_config"
            sed -i.bak "s/hw.lcd.density=.*/hw.lcd.density=${dpi}/" "$avd_config"
            
            echo -e "${GREEN}✅ AVD '$avd_name' configured for ${width}x${height}@${dpi}dpi${NC}"
        fi
    else
        echo -e "${GREEN}✅ AVD '$avd_name' already exists${NC}"
    fi
}

# Function to start emulator
start_emulator() {
    local avd_name=$1
    
    echo -e "${BLUE}🚀 Starting emulator '$avd_name'...${NC}"
    
    # Start emulator in background
    emulator -avd "$avd_name" -no-snapshot -wipe-data &
    local emulator_pid=$!
    
    echo -e "${BLUE}⏳ Waiting for emulator to boot...${NC}"
    
    # Wait for emulator to be ready
    local timeout=300  # 5 minutes
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        if adb devices | grep -q "emulator.*device"; then
            echo -e "${GREEN}✅ Emulator is ready!${NC}"
            return 0
        fi
        sleep 5
        elapsed=$((elapsed + 5))
        echo -e "${YELLOW}⏳ Still waiting... (${elapsed}s/${timeout}s)${NC}"
    done
    
    echo -e "${RED}❌ Emulator failed to start within ${timeout} seconds${NC}"
    kill $emulator_pid 2>/dev/null || true
    return 1
}

# Function to run screenshot tests
run_screenshot_tests() {
    local device_id=$1
    local device_name=$2
    
    echo -e "${BLUE}📸 Running screenshot tests on '$device_name' ($device_id)...${NC}"
    
    # Create device-specific output directory
    local device_dir="$RUN_DIR/${device_name// /_}"
    mkdir -p "$device_dir"
    
    # Run integration tests
    cd "$PROJECT_DIR"
    
    echo -e "${BLUE}🧪 Executing integration tests...${NC}"
    $FLUTTER_CMD test integration_test/tablet_screenshot_test.dart \
        -d "$device_id" \
        --dart-define=SCREENSHOTS_PATH="$device_dir" \
        2>&1 | tee "$device_dir/test_output.log"
    
    # Check if screenshots were generated
    local screenshot_count=$(find "$device_dir" -name "*.png" | wc -l)
    if [ $screenshot_count -gt 0 ]; then
        echo -e "${GREEN}✅ Generated $screenshot_count screenshots for '$device_name'${NC}"
        
        # List generated screenshots
        echo -e "${BLUE}📋 Generated screenshots:${NC}"
        find "$device_dir" -name "*.png" | sort | while read -r screenshot; do
            local filename=$(basename "$screenshot")
            local filesize=$(du -h "$screenshot" | cut -f1)
            echo -e "   📸 $filename ($filesize)"
        done
    else
        echo -e "${YELLOW}⚠️  No screenshots found for '$device_name'${NC}"
    fi
}

# Function to optimize screenshots for Play Store
optimize_screenshots() {
    echo -e "${BLUE}🔧 Optimizing screenshots for Google Play Store...${NC}"
    
    find "$RUN_DIR" -name "*.png" | while read -r screenshot; do
        if command -v convert &> /dev/null; then
            # Use ImageMagick to optimize if available
            convert "$screenshot" -quality 85 -strip "${screenshot%.png}_optimized.png"
            if [ -f "${screenshot%.png}_optimized.png" ]; then
                mv "${screenshot%.png}_optimized.png" "$screenshot"
                echo -e "${GREEN}✅ Optimized $(basename "$screenshot")${NC}"
            fi
        fi
    done
}

# Function to generate summary
generate_summary() {
    echo -e "${BLUE}📊 Generating summary report...${NC}"
    
    local summary_file="$RUN_DIR/SCREENSHOT_SUMMARY.md"
    
    cat > "$summary_file" << EOF
# Tablet Screenshots Summary

**Generated:** $(date)
**Test Run:** $TIMESTAMP

## Device Screenshots

EOF
    
    find "$RUN_DIR" -type d -name "*tablet*" | sort | while read -r device_dir; do
        local device_name=$(basename "$device_dir" | tr '_' ' ')
        local screenshot_count=$(find "$device_dir" -name "*.png" | wc -l)
        
        echo "### $device_name" >> "$summary_file"
        echo "- Screenshots: $screenshot_count" >> "$summary_file"
        echo "" >> "$summary_file"
        
        find "$device_dir" -name "*.png" | sort | while read -r screenshot; do
            local filename=$(basename "$screenshot")
            local filesize=$(du -h "$screenshot" | cut -f1)
            echo "- 📸 \`$filename\` ($filesize)" >> "$summary_file"
        done
        
        echo "" >> "$summary_file"
    done
    
    echo -e "${GREEN}✅ Summary report saved to: $summary_file${NC}"
}

# Main execution
main() {
    check_fvm
    
    echo -e "${BLUE}🎯 Target: Generate tablet screenshots for Google Play Store${NC}"
    echo -e "${BLUE}📱 Required: 7-inch and 10-inch tablet screenshots${NC}"
    echo ""
    
    # Check for physical devices first
    echo -e "${BLUE}📱 Checking for connected devices...${NC}"
    local devices_output
    devices_output=$(get_devices)
    
    if [ -n "$devices_output" ]; then
        echo -e "${GREEN}✅ Found connected devices:${NC}"
        echo "$devices_output" | while IFS='|' read -r id name platform; do
            echo -e "   📱 $name ($platform) - $id"
        done
        echo ""
        
        # Ask user which device to use
        echo -e "${YELLOW}❓ Would you like to use a connected device? (y/N)${NC}"
        read -r use_device
        
        if [[ $use_device =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}📋 Available devices:${NC}"
            local i=1
            echo "$devices_output" | while IFS='|' read -r id name platform; do
                echo "   [$i] $name ($platform)"
                i=$((i + 1))
            done
            
            echo -e "${YELLOW}❓ Enter device number:${NC}"
            read -r device_num
            
            local selected_device
            selected_device=$(echo "$devices_output" | sed -n "${device_num}p")
            
            if [ -n "$selected_device" ]; then
                IFS='|' read -r device_id device_name device_platform <<< "$selected_device"
                run_screenshot_tests "$device_id" "$device_name"
            else
                echo -e "${RED}❌ Invalid device selection${NC}"
                exit 1
            fi
        else
            echo -e "${BLUE}🤖 Using emulators instead...${NC}"
            
            # Create and use emulators
            for tablet_name in "${!TABLET_CONFIGS[@]}"; do
                local config="${TABLET_CONFIGS[$tablet_name]}"
                create_avd "$tablet_name" "$config"
                
                if start_emulator "$tablet_name"; then
                    # Wait a bit more for app to be installable
                    sleep 10
                    
                    # Get emulator device ID
                    local emulator_id
                    emulator_id=$(adb devices | grep "emulator" | head -1 | cut -f1)
                    
                    if [ -n "$emulator_id" ]; then
                        run_screenshot_tests "$emulator_id" "$tablet_name"
                        
                        # Stop emulator
                        adb -s "$emulator_id" emu kill
                        sleep 5
                    fi
                fi
            done
        fi
    else
        echo -e "${YELLOW}⚠️  No physical devices found. Using emulators...${NC}"
        
        # Check if Android SDK is available
        if ! command -v avdmanager &> /dev/null; then
            echo -e "${RED}❌ Android SDK not found. Please install Android Studio or SDK tools.${NC}"
            exit 1
        fi
        
        # Create and use emulators for each tablet size
        for tablet_name in "${!TABLET_CONFIGS[@]}"; do
            local config="${TABLET_CONFIGS[$tablet_name]}"
            create_avd "$tablet_name" "$config"
            
            if start_emulator "$tablet_name"; then
                # Wait for emulator to be ready for app installation
                sleep 10
                
                # Get emulator device ID
                local emulator_id
                emulator_id=$(adb devices | grep "emulator" | head -1 | cut -f1)
                
                if [ -n "$emulator_id" ]; then
                    run_screenshot_tests "$emulator_id" "$tablet_name"
                    
                    # Stop emulator
                    adb -s "$emulator_id" emu kill
                    sleep 5
                fi
            fi
        done
    fi
    
    # Post-processing
    optimize_screenshots
    generate_summary
    
    echo ""
    echo -e "${GREEN}🎉 Screenshot generation complete!${NC}"
    echo -e "${GREEN}📁 Screenshots saved to: $RUN_DIR${NC}"
    echo -e "${GREEN}📋 Summary: $RUN_DIR/SCREENSHOT_SUMMARY.md${NC}"
    echo ""
    echo -e "${BLUE}📤 Next steps:${NC}"
    echo -e "   1. Review screenshots in $RUN_DIR"
    echo -e "   2. Select best screenshots for Google Play Store"
    echo -e "   3. Upload to Google Play Console"
    echo ""
}

# Run main function
main "$@"
