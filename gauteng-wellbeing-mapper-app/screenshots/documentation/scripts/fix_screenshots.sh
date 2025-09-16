#!/bin/bash
# fix_screenshots.sh

for screenshot in screenshots/app_store/**/*.png; do
    # Remove alpha channel and ensure RGB
    sips -s format png -s formatOptions normal --setProperty format png "$screenshot"
    # Convert to RGB and remove transparency
    convert "$screenshot" -background white -alpha remove -alpha off "$screenshot"
done