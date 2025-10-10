# Manual Tablet Screenshot Capture Guide

Your web app is running at: http://localhost:8080

## Required Screenshot Sizes for Google Play Store

### 7-inch Tablet
- **Landscape**: 1280 x 800 pixels
- **Portrait**: 800 x 1280 pixels

### 10-inch Tablet  
- **Landscape**: 1920 x 1200 pixels
- **Portrait**: 1200 x 1920 pixels

## Step-by-Step Instructions

### 1. Open Browser DevTools
1. Open Chrome or Safari
2. Navigate to http://localhost:8080
3. Open DevTools:
   - **Chrome**: Press F12 or Cmd+Option+I (Mac) / Ctrl+Shift+I (Windows)
   - **Safari**: Press Cmd+Option+I (you may need to enable Developer menu first)

### 2. Enable Device Simulation Mode
1. **Chrome**: Click the device toggle icon (📱) in the DevTools toolbar
2. **Safari**: Click the Responsive Design Mode icon

### 3. Set Custom Device Dimensions

#### For 7-inch Tablet Screenshots:
1. Select "Responsive" or "Custom" from device dropdown
2. Set dimensions to **1280 x 800** (landscape) or **800 x 1280** (portrait)
3. Set device pixel ratio to 1.0

#### For 10-inch Tablet Screenshots:
1. Select "Responsive" or "Custom" from device dropdown  
2. Set dimensions to **1920 x 1200** (landscape) or **1200 x 1920** (portrait)
3. Set device pixel ratio to 1.0

### 4. Capture Screenshots

#### Method 1: DevTools Screenshot (Recommended)
1. **Chrome**: 
   - Open Command Menu: Cmd+Shift+P (Mac) / Ctrl+Shift+P (Windows)
   - Type "screenshot" and select "Capture full size screenshot"
   
2. **Safari**:
   - Right-click in the simulated device area
   - Select "Capture Screenshot"

#### Method 2: System Screenshot
1. Position the browser window appropriately
2. Use system screenshot tools:
   - **Mac**: Cmd+Shift+4, then select the device simulation area
   - **Windows**: Windows+Shift+S, then select the area

### 5. Navigate and Capture Key Screens

Capture screenshots of these important app screens:

1. **Home/Landing Screen** - Shows the main interface
2. **Map View** - Displays the mapping functionality  
3. **Survey Screen** - Shows the wellbeing survey interface
4. **Settings/Menu** - Displays app navigation and options

### 6. Save Screenshots

Save with descriptive names:
- `7inch_landscape_home.png`
- `7inch_portrait_map.png`
- `10inch_landscape_survey.png`
- `10inch_portrait_settings.png`

## Tips for Better Screenshots

1. **Clear Cache**: Refresh the page (Cmd+R / Ctrl+R) before capturing
2. **Wait for Loading**: Ensure all content is fully loaded
3. **Remove DevTools**: Hide DevTools UI from the final screenshot
4. **Check Scaling**: Ensure the viewport shows crisp, properly scaled content
5. **Test Interactions**: Try tapping/clicking elements to verify tablet responsiveness

## Quality Checklist

✅ Screenshots are exactly the required dimensions  
✅ Content is clearly visible and properly scaled  
✅ No browser UI elements visible in screenshots  
✅ App functionality works correctly at tablet dimensions  
✅ Text is readable and buttons are appropriately sized  
✅ Images and icons appear crisp (not pixelated)

## Troubleshooting

**If content appears too small/large:**
- Adjust device pixel ratio in DevTools
- Try zooming the page (Cmd/Ctrl + or -)

**If layout breaks:**
- Check that your Flutter web build includes responsive design
- Verify CSS media queries are working correctly

**If server isn't responding:**
- Restart the server: `python3 -m http.server 8080` in the web build directory

## Next Steps

Once you have captured the required screenshots:
1. Verify they meet Google Play Store requirements
2. Upload them to your Google Play Console
3. Test the screenshots in the store listing preview
