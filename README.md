# Macapult: Launchpad for macOS

A beautiful, native macOS application that brings back the LaunchPad functionality removed in recent macOS updates. Built with SwiftUI for a modern, polished experience.

## Features

✨ **Beautiful Grid Layout** - Display all your applications in an elegant grid with smooth animations

🔍 **Instant Search** - Quickly filter applications as you type

⌨️ **Keyboard Shortcuts** - Press F4 to show/hide LaunchPad (just like the original!)

🎨 **Modern Design** - Glassmorphic UI with stunning gradients and hover effects

🚀 **Fast & Lightweight** - Native SwiftUI app with minimal resource usage

## Screenshots

See below for the LaunchPad interface design.

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later (for building from source)


## Usage

### Opening LaunchPad

- Press **F4** on your keyboard to toggle LaunchPad
- Or click the app icon in your menu bar (if configured)

### Searching for Apps

- Start typing when LaunchPad is open
- The search is instant and case-insensitive
- Press ESC to clear search or hide LaunchPad

### Launching Apps

- Click any app icon to launch it
- LaunchPad will automatically hide after launching an app


## Known Limitations

- Requires macOS 14.0+ (due to SwiftUI features)
- Global shortcuts require accessibility permissions
- App runs as background accessory

## Troubleshooting

### LaunchPad doesn't respond to F4

1. Check System Settings → Privacy & Security → Accessibility
2. Add LaunchPad to the list of allowed apps
3. Restart the application

### Apps are missing from the grid

- The app only scans `/Applications` folder
- Apps in subfolders (like Utilities) are included
- Hidden apps and system utilities may be filtered

### Build fails in Xcode

- Ensure you're using Xcode 15.0 or later
- Check that deployment target is set to macOS 13.0
- Clean build folder (Product → Clean Build Folder)

## Future Enhancements

Some ideas for future versions:

- [ ] Multiple pages with gestures
- [ ] Customizable icon sizes
- [ ] Folder support for organizing apps
- [ ] Recent apps section
- [ ] App uninstall functionality
- [ ] Custom background images
- [ ] Alternative activation methods (hot corners, menu bar icon)

## License

This project is provided as-is for personal use.

## Contributing

Feel free to fork and improve! Some areas that could use work:

- Better error handling
- Performance optimizations for large app collections
- Additional customization options
- Alternative themes

---

**Note**: This is an independent project and is not affiliated with Apple Inc. LaunchPad is a trademark of Apple Inc.
