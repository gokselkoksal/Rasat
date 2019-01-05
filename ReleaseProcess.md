# Release Process

## Bump the version

* Open `Info.plist`.
* Bump the version.

## Prapare Carthage Release

* Create a tag for the version and push it.

## Prepare Cocoapods Release

* Open Lightning.podspec.
* Update `s.version` field with the current version.
* Run: `pod spec lint Lightning.podspec`
* Run: `pod trunk push Lightning.podspec`
