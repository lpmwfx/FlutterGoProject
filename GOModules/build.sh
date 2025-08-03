#!/bin/bash

#!/bin/bash

# iOS Device (ARM64)
export SDK_PATH_IOS=$(xcrun --sdk iphoneos --show-sdk-path)
export CC_IOS=$(xcrun --sdk iphoneos -f clang)
export CGO_CFLAGS_IOS="-fembed-bitcode -target arm64-apple-ios18.5 -isysroot $SDK_PATH_IOS"
export CGO_LDFLAGS_IOS="-isysroot $SDK_PATH_IOS"
GOOS=ios GOARCH=arm64 CGO_ENABLED=1 CC=$CC_IOS CGO_CFLAGS=$CGO_CFLAGS_IOS CGO_LDFLAGS=$CGO_LDFLAGS_IOS go build -ldflags="-w -s" -o libengine_ios_arm64.a -buildmode=c-archive engine.go

# iOS Simulator (ARM64)
export SDK_PATH_SIM=$(xcrun --sdk iphonesimulator --show-sdk-path)
export CC_SIM=$(xcrun --sdk iphonesimulator -f clang)
export CGO_CFLAGS_SIM="-fembed-bitcode -target arm64-apple-ios18.5-simulator -isysroot $SDK_PATH_SIM"
export CGO_LDFLAGS_SIM="-isysroot $SDK_PATH_SIM"
GOOS=ios GOARCH=arm64 CGO_ENABLED=1 CC=$CC_SIM CGO_CFLAGS=$CGO_CFLAGS_SIM CGO_LDFLAGS=$CGO_LDFLAGS_SIM go build -ldflags="-w -s" -o libengine_sim_arm64.a -buildmode=c-archive engine.go

# macOS (dylib)
GOOS=darwin GOARCH=arm64 CGO_ENABLED=1 go build -ldflags="-w -s" -o libengine.dylib -buildmode=c-shared engine.go
cp libengine.dylib ../FlutterEditor/macos/

# Create frameworks

# iOS Device
rm -rf ios-arm64
mkdir -p ios-arm64/libengine.framework/Headers
cp libengine_ios_arm64.a ios-arm64/libengine.framework/libengine
cp libengine_ios_arm64.h ios-arm64/libengine.framework/Headers/engine.h
cat <<EOF > ios-arm64/libengine.framework/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>libengine</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.libengine</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>libengine</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
EOF

# iOS Simulator
rm -rf ios-arm64-simulator
mkdir -p ios-arm64-simulator/libengine.framework/Headers
cp libengine_sim_arm64.a ios-arm64-simulator/libengine.framework/libengine
cp libengine_sim_arm64.h ios-arm64-simulator/libengine.framework/Headers/engine.h
cat <<EOF > ios-arm64-simulator/libengine.framework/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>libengine</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.libengine</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>libengine</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
EOF

# Create XCFramework
rm -rf libengine.xcframework
xcodebuild -create-xcframework \
    -framework ios-arm64/libengine.framework \
    -framework ios-arm64-simulator/libengine.framework \
    -output libengine.xcframework

# Clean up
rm libengine_ios_arm64.a
rm libengine_sim_arm64.a
rm libengine_ios_arm64.h
rm libengine_sim_arm64.h
rm -rf ios-arm64
rm -rf ios-arm64-simulator

echo "Successfully created libengine.xcframework and libengine.dylib"