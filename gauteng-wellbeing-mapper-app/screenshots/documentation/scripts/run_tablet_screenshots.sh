#!/bin/bash

# Simple Tablet Screenshot Generator for Connected Devices
# Works with your Samsung Galaxy Tab and other connected devices

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if fvm is available
if command -v fvm &> /dev/null; then
    FLUTTER_CMD="fvm flutter"
    echo -e "${GREEN}✅ Using fvm for Flutter commands${NC}"
else
    FLUTTER_CMD="flutter"
    echo -e "${YELLOW}⚠️  Using system flutter${NC}"
fi

# Create screenshots directory
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SCREENSHOTS_DIR="screenshots/tablet_screenshots/run_$TIMESTAMP"
mkdir -p "$SCREENSHOTS_DIR"

echo -e "${BLUE}🚀 Tablet Screenshot Generator${NC}"
echo -e "${BLUE}📁 Screenshots will be saved to: $SCREENSHOTS_DIR${NC}"
echo ""

# Get list of connected devices
echo -e "${BLUE}📱 Checking connected devices...${NC}"
$FLUTTER_CMD devices

echo ""
echo -e "${YELLOW}❓ Please select a device from the list above.${NC}"
echo -e "${YELLOW}   Enter the device ID (e.g., RZCW90B03FV for Samsung tablet):${NC}"
read -r device_id

if [ -z "$device_id" ]; then
    echo -e "${RED}❌ No device ID entered. Exiting.${NC}"
    exit 1
fi

# Get device info
device_info=$($FLUTTER_CMD devices --machine | jq -r ".[] | select(.id == \"$device_id\") | .name")

if [ -z "$device_info" ] || [ "$device_info" = "null" ]; then
    echo -e "${RED}❌ Device ID '$device_id' not found. Please check the device ID.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Selected device: $device_info ($device_id)${NC}"
echo ""

# Create device-specific directory
device_dir="$SCREENSHOTS_DIR/${device_info// /_}"
mkdir -p "$device_dir"

# Run the integration tests
echo -e "${BLUE}🧪 Running tablet screenshot tests...${NC}"
echo -e "${BLUE}📱 Device: $device_info${NC}"
echo -e "${BLUE}📸 Output: $device_dir${NC}"
echo ""

# Run the test and capture output
if $FLUTTER_CMD test integration_test/tablet_screenshot_test.dart -d "$device_id" 2>&1 | tee "$device_dir/test_output.log"; then
    echo ""
    echo -e "${GREEN}✅ Tests completed successfully!${NC}"
else
    echo ""
    echo -e "${YELLOW}⚠️  Tests completed with some issues. Check the log for details.${NC}"
fi

# Check for generated screenshots
echo -e "${BLUE}📋 Checking for generated screenshots...${NC}"

# Screenshots are typically saved in the integration_test directory
# Let's move them to our organized directory
if [ -d "integration_test/screenshots" ]; then
    cp -r integration_test/screenshots/* "$device_dir/" 2>/dev/null || true
fi

# Also check build directory
if [ -d "build/integration_test_screenshots" ]; then
    cp -r build/integration_test_screenshots/* "$device_dir/" 2>/dev/null || true
fi

# Count screenshots
screenshot_count=$(find "$device_dir" -name "*.png" 2>/dev/null | wc -l)

if [ "$screenshot_count" -gt 0 ]; then
    echo -e "${GREEN}✅ Found $screenshot_count screenshots!${NC}"
    echo ""
    echo -e "${BLUE}📸 Generated screenshots:${NC}"
    
    find "$device_dir" -name "*.png" | sort | while read -r screenshot; do
        filename=$(basename "$screenshot")
        filesize=$(du -h "$screenshot" 2>/dev/null | cut -f1 || echo "unknown")
        echo -e "   📸 $filename ($filesize)"
    done
    
    # Determine device type based on screen size
    echo ""
    echo -e "${BLUE}📱 Device Classification:${NC}"
    
    # Try to get device info from the screenshot filename or test output
    if find "$device_dir" -name "*10inch*" | grep -q .; then
        echo -e "${GREEN}   📏 Detected: 10-inch tablet format${NC}"
    elif find "$device_dir" -name "*7inch*" | grep -q .; then
        echo -e "${GREEN}   📏 Detected: 7-inch tablet format${NC}"
    else
        echo -e "${YELLOW}   📏 Device type: Based on actual device dimensions${NC}"
    fi
    
else
    echo -e "${YELLOW}⚠️  No screenshots found. Screenshots might be in a different location.${NC}"
    echo -e "${BLUE}🔍 Searching for screenshots in common locations...${NC}"
    
    # Search for screenshots in various locations
    find . -name "*.png" -path "*/integration_test*" 2>/dev/null | head -10 | while read -r screenshot; do
        echo -e "   Found: $screenshot"
        # Copy to our directory
        cp "$screenshot" "$device_dir/" 2>/dev/null || true
    done
fi

# Generate summary
echo ""
echo -e "${BLUE}📊 Generating summary...${NC}"

cat > "$device_dir/SCREENSHOT_INFO.md" << EOF
# Tablet Screenshots - $device_info

**Generated:** $(date)
**Device ID:** $device_id
**Device Name:** $device_info
**Test Run:** $TIMESTAMP

## Screenshots Generated

$(find "$device_dir" -name "*.png" 2>/dev/null | sort | while read -r screenshot; do
    filename=$(basename "$screenshot")
    filesize=$(du -h "$screenshot" 2>/dev/null | cut -f1 || echo "unknown")
    echo "- 📸 \`$filename\` ($filesize)"
done)

## Google Play Store Requirements

For tablet screenshots on Google Play Store:

### 7-inch tablets:
- **Minimum resolution:** 1080p (1920 x 1080)
- **Recommended:** 1920 x 1200 or higher
- **Format:** PNG or JPEG
- **Max file size:** 8MB

### 10-inch tablets:
- **Minimum resolution:** 1080p (1920 x 1080) 
- **Recommended:** 2560 x 1600 or higher
- **Format:** PNG or JPEG
- **Max file size:** 8MB

### Usage:
1. Review all screenshots
2. Select 2-8 best screenshots showing key app features
3. Upload to Google Play Console under "Store listing" > "Graphics"
4. Ensure screenshots show actual app content (not placeholder data)

## Next Steps

1. **Review screenshots:** Check that they showcase key app features
2. **Optimize if needed:** Ensure good resolution and file size
3. **Upload to Play Store:** Add to your app listing
4. **Test on different devices:** Consider testing on various tablet sizes

EOF

echo -e "${GREEN}✅ Summary saved to: $device_dir/SCREENSHOT_INFO.md${NC}"

# Final summary
echo ""
echo -e "${GREEN}🎉 Screenshot generation complete!${NC}"
echo ""
echo -e "${BLUE}📁 Location: $device_dir${NC}"
echo -e "${BLUE}📋 Summary: $device_dir/SCREENSHOT_INFO.md${NC}"
echo -e "${BLUE}📋 Test Log: $device_dir/test_output.log${NC}"
echo ""
echo -e "${BLUE}📤 Next steps:${NC}"
echo -e "   1. Review screenshots in: $device_dir"
echo -e "   2. Select 2-8 best screenshots for Google Play Store"
echo -e "   3. Upload to Google Play Console > Store listing > Graphics"
echo -e "   4. Ensure screenshots show real app features and data"
echo ""

# Offer to open the directory
if command -v open &> /dev/null; then
    echo -e "${YELLOW}❓ Open screenshots folder? (y/N)${NC}"
    read -r open_folder
    if [[ $open_folder =~ ^[Yy]$ ]]; then
        open "$device_dir"
    fi
fi
