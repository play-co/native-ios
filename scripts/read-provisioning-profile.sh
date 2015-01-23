# ./read-provisioning-profile.sh <path-to-profile> KEY
#
# where:
#   KEY can be any field in the plist
#
# common values for KEY include:
#   Name
#   UUID
#   :Entitlements:application-identifier

/usr/libexec/PlistBuddy -c "Print $2" /dev/stdin <<< $(security cms -D -i "$1")
