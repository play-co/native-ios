#!/bin/sh

LIPO="xcrun -sdk iphoneos lipo"

# arm64
xcodebuild -project libpng.xcodeproj -configuration 'Debug' -sdk 'iphoneos8.1' \
  clean build ARCHS='arm64' IPHONEOS_DEPLOYMENT_TARGET='5.1.1' \
  TARGET_BUILD_DIR='./build-arm64' BUILT_PRODUCTS_DIR='./build-arm64'

# armv7 and armv7s
xcodebuild -project libpng.xcodeproj -configuration 'Debug' -sdk 'iphoneos8.1' \
  clean build ARCHS='armv7 armv7s' IPHONEOS_DEPLOYMENT_TARGET='5.1.1' \
  TARGET_BUILD_DIR='./build-armv7' BUILT_PRODUCTS_DIR='./build-armv7'

# i386
xcodebuild -project libpng.xcodeproj -configuration 'Debug' -sdk \
  'iphonesimulator8.1' clean build ARCHS='i386' \
  IPHONEOS_DEPLOYMENT_TARGET='5.1.1' TARGET_BUILD_DIR='./build-i386' \
  BUILT_PRODUCTS_DIR='./build-i386'

# x86_64
xcodebuild -project libpng.xcodeproj -configuration 'Debug' -sdk \
  'iphonesimulator8.1' clean build ARCHS='x86_64' \
  VALID_ARCHS='x86_64' IPHONEOS_DEPLOYMENT_TARGET='5.1.1' \
  TARGET_BUILD_DIR='./build-x86_64' BUILT_PRODUCTS_DIR='./build-x86_64'

# build universal library
rm libpng.a
lipo -create \
  build-arm64/libpng.a \
  build-armv7/libpng.a \
  build-i386/libpng.a \
  build-x86_64/libpng.a \
  -output libpng.a

rm -rf build-arm64 build-armv7 build-i386 build-x86_64 build
