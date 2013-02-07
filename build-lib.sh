#/bin/sh

function check_status {
	if [ $? -ne 0 ]; then
		cd ..
		echo "build failed"
		exit 1
	fi
}


if [ $# -lt 1 ]; then
	echo "Usuage: build-lib {libjpeg|libpng}"
	exit 1
fi
#strip off the trailing slash
LIB_NAME=${1//\//}
echo "building $LIB_NAME"
cd $LIB_NAME
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -sdk iphonesimulator5.1
check_status
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -sdk iphoneos5.1
check_status


lipo -create "build/Release-iphoneos/$LIB_NAME.a" "build/Release-iphonesimulator/$LIB_NAME.a" -output "./$LIB_NAME.a"
check_status
cd ..
echo "$LIB_NAME/$LIB_NAME.a created"
