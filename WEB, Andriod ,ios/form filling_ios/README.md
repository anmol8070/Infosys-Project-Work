# FillEasy iOS

A full-featured iOS application that enables easy form filling and management.

## Description

FillEasy is a native iOS application that simplifies the process of filling and managing forms. Built using Swift and Objective-C, it provides a seamless user experience for handling various types of forms and documents.

## Features

- Form auto-filling capability
- Document management
- Multiple language support
- Offline support
- Custom theming
- PDF handling
- Secure data storage

## Requirements

- Xcode 14.0 or later
- iOS 14.0 or later
- CocoaPods

## Installation

1. Clone the repository:
```bash
git clone https://github.com/svsairevanth12/filleasy_ios.git
cd filleasy_ios
```

2. Install CocoaPods if you haven't already:
```bash
sudo gem install cocoapods
```

3. Install project dependencies:
```bash
pod install
```

4. Open the workspace in Xcode:
```bash
open FillEasy.xcworkspace
```

## Building the Project

1. Make sure you've opened `FillEasy.xcworkspace` (not `FillEasy.xcodeproj`)
2. Select your target device or simulator
3. Build the project using `⌘ + B` or by clicking the build button
4. Run the app using `⌘ + R` or by clicking the run button

## Configuration

- Update `appConfig.json` in the LeanIOS directory for app-specific configurations
- Modify `GoogleService-Info.plist` with your Firebase credentials if using Firebase services
- Custom styling can be modified in `customCSS.css` and `iosCustomCSS.css`
- Custom JavaScript functionality can be added in `customJS.js` and `iosCustomJS.js`

## Usage

1. Launch the application
2. Sign in or create a new account
3. Access your forms through the main dashboard
4. Use the built-in tools to fill, save, and manage your forms
5. Export or share completed forms as needed

## Testing

Run the unit tests using Xcode's Test Navigator or via command line:
```bash
xcodebuild test -workspace FillEasy.xcworkspace -scheme FillEasy -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.0'
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
# Form-Filling-ios
