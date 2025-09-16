#!/bin/bash

# iPhone Simulator Screenshot Helper
# Automates switching between different iPhone simulators for App Store screenshots

set -e

echo "📱 iPhone Simulator Screenshot Helper"
echo "===================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to show available options
show_menu() {
    echo ""
    echo "Select iPhone simulator for App Store screenshots:"
    echo "1) iPhone 16 Plus     - 6.7\" display (1290×2796) - REQUIRED"
    echo "2) iPhone 15 Pro      - 6.1\" display (1179×2556) - REQUIRED"
    echo "3) iPhone 8 Plus      - 5.5\" display (1242×2208) - Optional"
    echo "4) Show current app   - Just run app on current simulator"
    echo "5) Stop all           - Stop all running simulators"
    echo "6) Help               - Show screenshot guide"
    echo "0) Exit"
    echo ""
}

# Function to run app on specific simulator
run_app_on_simulator() {
    local simulator_name="$1"
    
    print_status "Starting $simulator_name simulator..."
    
    # Start the simulator
    fvm flutter emulators --launch apple_ios_simulator &
    sleep 5
    
    # Get the simulator device ID
    local device_id=$(fvm flutter devices | grep "ios.*simulator" | head -1 | cut -d'•' -f2 | tr -d ' ')
    
    if [ -n "$device_id" ]; then
        print_status "Running Wellbeing Mapper on $simulator_name..."
        print_status "Device ID: $device_id"
        
        # Run the app
        fvm flutter run -d "$device_id" &
        
        print_success "App started on $simulator_name"
        print_status "You can now take screenshots using Cmd+S in the simulator"
        print_status "Follow the screenshot guide in screenshots/app_store/SCREENSHOT_GUIDE.md"
    else
        print_warning "Could not find simulator device ID"
    fi
}

# Function to stop all simulators
stop_simulators() {
    print_status "Stopping all iOS simulators..."
    killall "Simulator" 2>/dev/null || print_warning "No simulators were running"
    print_success "All simulators stopped"
}

# Function to show help
show_help() {
    cat screenshots/app_store/SCREENSHOT_GUIDE.md
}

# Main menu loop
main() {
    while true; do
        show_menu
        read -p "Choose an option (0-6): " choice
        
        case $choice in
            1)
                print_status "Setting up iPhone 16 Plus for 6.7\" display screenshots..."
                stop_simulators
                sleep 2
                run_app_on_simulator "iPhone 16 Plus"
                ;;
            2)
                print_status "Setting up iPhone 15 Pro for 6.1\" display screenshots..."
                stop_simulators
                sleep 2
                run_app_on_simulator "iPhone 15 Pro"
                ;;
            3)
                print_status "Setting up iPhone 8 Plus for 5.5\" display screenshots..."
                stop_simulators
                sleep 2
                run_app_on_simulator "iPhone 8 Plus"
                ;;
            4)
                print_status "Getting current simulator info..."
                fvm flutter devices
                echo ""
                print_status "Running app on current simulator..."
                fvm flutter run
                ;;
            5)
                stop_simulators
                ;;
            6)
                show_help
                ;;
            0)
                print_status "Exiting..."
                break
                ;;
            *)
                print_warning "Invalid option. Please choose 0-6."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Check prerequisites
if ! command -v fvm &> /dev/null; then
    if ! command -v flutter &> /dev/null; then
        print_error "Neither FVM nor Flutter found in PATH"
        exit 1
    else
        print_warning "FVM not found, using system Flutter"
        # Replace fvm flutter with flutter in script
        sed -i '' 's/fvm flutter/flutter/g' "$0"
    fi
fi

# Verify we're in the correct directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found. Please run this script from the Flutter project root."
    exit 1
fi

# Run main menu
main
