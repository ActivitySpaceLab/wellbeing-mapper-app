#!/bin/bash

# Web-based Tablet Screenshot Generator
# Perfect for Apple Silicon Macs without Android emulator support

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
SCREENSHOTS_DIR="screenshots/web_tablet_screenshots/run_$TIMESTAMP"
mkdir -p "$SCREENSHOTS_DIR"

echo -e "${BLUE}🌐 Web-based Tablet Screenshot Generator${NC}"
echo -e "${BLUE}📱 Perfect for Apple Silicon Macs without Android emulator support${NC}"
echo -e "${BLUE}📁 Screenshots will be saved to: $SCREENSHOTS_DIR${NC}"
echo ""

# Build web version
echo -e "${BLUE}🔨 Building Flutter web app...${NC}"
$FLUTTER_CMD build web --release --no-tree-shake-icons

if [ ! -d "build/web" ]; then
    echo -e "${RED}❌ Web build failed. Please check for errors.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Web build completed successfully${NC}"

# Start local server
echo -e "${BLUE}🚀 Starting local web server...${NC}"
cd build/web

# Try different ways to start a local server
if command -v python3 &> /dev/null; then
    echo -e "${GREEN}✅ Using Python 3 HTTP server${NC}"
    python3 -m http.server 8080 &
    SERVER_PID=$!
    SERVER_CMD="python3"
elif command -v python &> /dev/null; then
    echo -e "${GREEN}✅ Using Python HTTP server${NC}"
    python -m http.server 8080 &
    SERVER_PID=$!
    SERVER_CMD="python"
elif command -v npx &> /dev/null; then
    echo -e "${GREEN}✅ Using npx serve${NC}"
    npx serve -s . -p 8080 &
    SERVER_PID=$!
    SERVER_CMD="npx"
else
    echo -e "${RED}❌ No suitable HTTP server found. Please install Python or Node.js.${NC}"
    exit 1
fi

echo -e "${BLUE}⏳ Waiting for server to start...${NC}"
sleep 3

# Check if server is running
if curl -s http://localhost:8080 > /dev/null; then
    echo -e "${GREEN}✅ Server is running at http://localhost:8080${NC}"
else
    echo -e "${RED}❌ Server failed to start${NC}"
    kill $SERVER_PID 2>/dev/null || true
    exit 1
fi

cd ../..

# Create screenshot capture script
cat > "$SCREENSHOTS_DIR/capture_instructions.md" << 'EOF'
# Web-based Tablet Screenshot Capture Instructions

## Automated Browser Screenshots

Your Flutter web app is now running at: **http://localhost:8080**

### Method 1: Chrome DevTools (Recommended)

1. **Open Chrome** and go to http://localhost:8080
2. **Open DevTools** (F12 or Cmd+Option+I)
3. **Click Device Toolbar** (phone/tablet icon) or press Cmd+Shift+M
4. **Select tablet presets:**

#### 7-inch Tablet:
   - **Custom size:** 1024 x 768 (4:3 ratio)
   - **Or:** 1280 x 800 (16:10 ratio)
   - **Device pixel ratio:** 2

#### 10-inch Tablet:
   - **Custom size:** 1366 x 1024 (4:3 ratio)  
   - **Or:** 1920 x 1200 (16:10 ratio)
   - **Device pixel ratio:** 2

5. **Navigate through your app** and capture screenshots:
   - Right-click → "Capture screenshot" 
   - Or use Chrome's screenshot tool in DevTools

### Method 2: Firefox Responsive Design Mode

1. **Open Firefox** and go to http://localhost:8080
2. **Enable Responsive Design Mode** (F12 → Click tablet icon)
3. **Set tablet dimensions:**
   - 7-inch: 1024x768 or 1280x800
   - 10-inch: 1366x1024 or 1920x1200
4. **Use built-in screenshot tool**

### Method 3: Safari Web Inspector

1. **Open Safari** and go to http://localhost:8080
2. **Open Web Inspector** (Cmd+Option+I)
3. **Use Responsive Design Mode**
4. **Set custom tablet sizes**
5. **Take screenshots** using macOS screenshot tools (Cmd+Shift+4)

## Screen Sizes for Google Play Store

### 7-inch Tablets (Required)
- **Resolution:** 1024x768 or 1280x800 minimum
- **Target:** 1920x1200 for best quality
- **Orientation:** Landscape preferred

### 10-inch Tablets (Required)  
- **Resolution:** 1366x1024 or 1920x1200 minimum
- **Target:** 2560x1600 for best quality
- **Orientation:** Landscape preferred

## Key Screens to Capture

1. **Participation Selection** - Initial mode selection
2. **Private Mode Main** - Main app interface
3. **Map Interface** - Interactive map (if available)
4. **Survey Forms** - Data collection screens
5. **Research Participation** - Barcelona/Gauteng flows
6. **Settings/Menu** - Configuration options

## Tips for Quality Screenshots

- **Use landscape orientation** for tablets
- **Ensure high pixel density** (2x or higher)
- **Show real data/content** (not empty states)
- **Capture key app features** that differentiate your app
- **Save as PNG** for best quality
- **Keep file sizes under 8MB** for Play Store

## After Capturing

1. **Save screenshots** with descriptive names:
   - `7inch_tablet_01_participation_selection.png`
   - `10inch_tablet_02_main_interface.png`
   - etc.

2. **Optimize for Play Store:**
   - Ensure minimum resolution requirements
   - Compress if needed (but keep quality high)
   - Review for appropriate content

3. **Upload to Google Play Console:**
   - Go to Store listing → Graphics
   - Upload 2-8 screenshots per tablet size
   - Add captions if desired

EOF

# Create automated screenshot script using Playwright (if available)
if command -v npx &> /dev/null; then
    echo -e "${BLUE}🎭 Checking for Playwright...${NC}"
    
    cat > "$SCREENSHOTS_DIR/automated_capture.js" << 'EOF'
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

async function captureTabletScreenshots() {
  const browser = await chromium.launch();
  
  // Tablet configurations
  const tablets = [
    { name: '7inch_tablet', width: 1280, height: 800, deviceScaleFactor: 2 },
    { name: '10inch_tablet', width: 1920, height: 1200, deviceScaleFactor: 2 }
  ];
  
  const screens = [
    { name: '01_participation_selection', path: '/' },
    { name: '02_main_interface', path: '/' },
    { name: '03_map_interface', path: '/' },
    { name: '04_survey_forms', path: '/' },
    { name: '05_settings', path: '/' }
  ];
  
  for (const tablet of tablets) {
    console.log(`📱 Capturing screenshots for ${tablet.name}...`);
    
    const context = await browser.newContext({
      viewport: { width: tablet.width, height: tablet.height },
      deviceScaleFactor: tablet.deviceScaleFactor
    });
    
    const page = await context.newPage();
    
    for (const screen of screens) {
      try {
        await page.goto(`http://localhost:8080${screen.path}`);
        await page.waitForLoadState('networkidle');
        
        const filename = `${tablet.name}_${screen.name}.png`;
        await page.screenshot({ 
          path: filename,
          fullPage: false 
        });
        
        console.log(`✅ Captured: ${filename}`);
        
        // Wait between screenshots
        await page.waitForTimeout(2000);
        
      } catch (error) {
        console.log(`❌ Failed to capture ${tablet.name}_${screen.name}: ${error.message}`);
      }
    }
    
    await context.close();
  }
  
  await browser.close();
  console.log('🎉 Screenshot capture completed!');
}

captureTabletScreenshots().catch(console.error);
EOF

    echo -e "${YELLOW}💡 To use automated capture (if you have Playwright):${NC}"
    echo -e "   cd $SCREENSHOTS_DIR"
    echo -e "   npm init -y"
    echo -e "   npm install playwright"
    echo -e "   node automated_capture.js"
    echo ""
fi

# Final instructions
echo ""
echo -e "${GREEN}🎉 Web server is ready for tablet screenshot capture!${NC}"
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
echo -e "   1. Open http://localhost:8080 in your browser"
echo -e "   2. Follow instructions in: $SCREENSHOTS_DIR/capture_instructions.md"
echo -e "   3. Use browser DevTools to simulate tablet sizes"
echo -e "   4. Capture screenshots of key app screens"
echo ""
echo -e "${BLUE}📐 Tablet sizes to use:${NC}"
echo -e "   • 7-inch tablet: 1280x800 or 1024x768"
echo -e "   • 10-inch tablet: 1920x1200 or 1366x1024"
echo ""
echo -e "${YELLOW}⚠️  Remember to stop the server when done:${NC}"
echo -e "   kill $SERVER_PID"
echo ""

# Create stop server script
cat > "$SCREENSHOTS_DIR/stop_server.sh" << EOF
#!/bin/bash
echo "🛑 Stopping web server..."
kill $SERVER_PID 2>/dev/null || true
echo "✅ Server stopped"
EOF

chmod +x "$SCREENSHOTS_DIR/stop_server.sh"

echo -e "${BLUE}📁 Files created:${NC}"
echo -e "   📋 $SCREENSHOTS_DIR/capture_instructions.md"
echo -e "   🛑 $SCREENSHOTS_DIR/stop_server.sh"
if [ -f "$SCREENSHOTS_DIR/automated_capture.js" ]; then
    echo -e "   🎭 $SCREENSHOTS_DIR/automated_capture.js"
fi
echo ""

# Auto-open browser if possible
if command -v open &> /dev/null; then
    echo -e "${YELLOW}❓ Open browser automatically? (y/N)${NC}"
    read -r -t 10 open_browser
    if [[ $open_browser =~ ^[Yy]$ ]]; then
        open "http://localhost:8080"
        echo -e "${GREEN}✅ Browser opened to http://localhost:8080${NC}"
    fi
fi

echo -e "${GREEN}🚀 Ready to capture tablet screenshots! 📸${NC}"
