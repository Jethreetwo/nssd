# Stack iOS App

Open the project in Xcode:

1. Create a new iOS App project named **Stack** in Xcode.
2. Replace the generated source files with the contents of the `ios/Stack` folder in this repo.
3. Ensure SwiftData is enabled (iOS 17+).
4. Build and run on a simulator or device.

## Settings
The Settings tab lets you set:
- Server URL (default http://localhost:8000)
- Bearer token
- Mode (focus/quick/deep)

## Offline
The app stores tasks and queued sync events locally and retries sync when connected.
