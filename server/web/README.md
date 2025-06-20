# Flutter Web App Directory

This directory contains the built Flutter web application that will be served by the Rust server.

## Building the Flutter Web App

1. **Navigate to your Flutter project directory:**
   ```bash
   cd /path/to/your/flutter/project
   ```

2. **Build the web app:**
   ```bash
   flutter build web --release
   ```

3. **Copy the build output to this directory:**
   ```bash
   cp -r build/web/* /path/to/this/server/web/
   ```

## Directory Structure

After building and copying, your `web/` directory should contain:
```
web/
├── index.html          # Main entry point
├── main.dart.js        # Compiled Dart code
├── flutter.js          # Flutter web runtime
├── assets/             # App assets
│   ├── AssetManifest.json
│   ├── FontManifest.json
│   └── ...
└── canvaskit/          # CanvasKit files (if using CanvasKit renderer)
```

## Development Workflow

1. **Build your Flutter app:**
   ```bash
   flutter build web --release
   ```

2. **Copy to server:**
   ```bash
   cp -r build/web/* /path/to/server/web/
   ```

3. **Restart the Rust server:**
   ```bash
   cargo run
   ```

4. **Access your app:**
   - Web app: `http://localhost:8080/` (or your configured port)
   - API: `http://localhost:8080/api/...`

## Notes

- The server is configured to serve static files from this directory
- Flutter's client-side routing is handled by the fallback service
- API routes are prefixed with `/api/` to avoid conflicts
- Make sure to rebuild and copy the web files whenever you update your Flutter app 