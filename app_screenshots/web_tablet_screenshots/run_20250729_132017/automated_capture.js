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
