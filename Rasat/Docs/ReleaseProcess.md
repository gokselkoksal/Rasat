# Release Process

## Bump the version

* Open `Info.plist`.
* Bump the version.

## Prapare Carthage Release

* Create a tag for the version and push it.

## Prepare Cocoapods Release

* Open `Rasat.podspec`.
* Update `s.version` field with the current version.
* Check other fields just in case there are any updates.
* Run: `pod spec lint Rasat.podspec`
* Run: `pod trunk push Rasat.podspec`
