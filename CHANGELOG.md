# Changelog for PSImmich

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.2.4] - 2025-11-13

### Changed

- Rerelease of 2.2.3

## [2.2.3] - 2025-11-13

### Added

- Windows PowerShell compatibility for Import-IMAsset and Add-IMMyProfilePicture cmdlets

### Changed

- Comprehensively improved PowerShell help documentation for all cmdlets
- Enhanced API parameter handling with support for nested parameter structures using dot-notation

### Removed

- Removed Get-IMMapStyle cmdlet (endpoint no longer available in Immich API)

## [2.2.1] - 2025-11-06

### Added

- Added ApiParameter attribute system for better parameter mapping to API endpoints

### Changed

- Enhanced Search-IMAsset with ApiParameter attributes and improved pagination handling
- Updated New-IMAlbum, Set-IMAsset, Find-IMPerson, and Find-IMPlace to use new ApiParameter system
- Improved parameter mapping consistency across cmdlets

### Fixed

- Fixed pagination bug in Search-IMAsset when multiple pages are returned


## [2.2.0] - 2025-11-03

### Added

- Added complete Stack API support with Get-IMStack, New-IMStack, Set-IMStack, Remove-IMStack, and Remove-IMStackAsset cmdlets

### Fixed

- Fixed Get-IMAsset -TagId to use search API instead of deprecated tags/\{id\}/assets endpoint
- Updated Get-IMAsset to remove deprecation warning for asset enumeration

### Removed

- Removed Get-IMAssetMemoryLane cmdlet (endpoint no longer available)
- Removed Get-IMAuditFile cmdlet (functionality moved to different endpoint)
- Removed Get-IMFileChecksum cmdlet (functionality moved to different endpoint)

## [1.128.0] - 2025-03-03

### Added

- Added coverage for smart search, provided by Search-IMAsset.

### Removed

- Removed Get-IMAuditDelete as it is no longer provided by the Immich API.

## [1.118.0] - 2024-10-15

### Fixed

- Connect Immich session now uses the new server api instead of the deprecated server-info api.

### Chore

- Combined all unit test files to two combined test-files. Cuts test-discovery with 80%
- Switched to Profiler for code coverage instead of breakpoints. Also cuts testing time substantially.
- ValidateToken has been moved to a new private function to allow mocking when called from a class.

## [1.117.0] - 2024-10-12

### Fixed

- Updated Start-IMJob to align with API changes.
- Get-IMAsset -Random now uses the new /search/random endpoint.

### Added

- Added -History parameter to Get-IMServerVersion to retrieve version history.
- Added new jobs to Start-,Suspend-,Resume-,Clear-IMJob

### Removed

- Removed Remove-IMLibraryOfflineFiles as it has been removed from the API and is now handled by Immich automatically.

## [1.113.0] - 2024-09-01

### Added 

- Added Color parameter to Set-IMTag
- Added Permissions to New-IMAPIKey
- Added Get-IMServerAbout

### Fixed

- Renamed Get-IMAlbumCount to Get-IMAlbumStatistics according to upstream API change
- Changed removed/server-info calls and replace with new /server calls.
- Removed Rename-IMTag as it is removed from the upstream API

## [1.111.1] - 2024-08-14

### Fixed

- Maintenance: Fix version number issue causing PSGallery publish to fail

## [1.111.0] - 2024-08-12

### Added

- Added support for the user preference API. This has been added as two new cmdlets Get-IMUserPreference and Set-IMUserPreference.
- Added support for the duplicates API. This has been added as one new cmdlet Get-IMDuplicate.
- Added support for the reverse geocoding API. This has been added as one new cmdlet Convert-IMCoordinatesToLocation.
- Added support for the server license API. This has been added as three new cmdlets Get-IMServerLicense, Set-IMServerLicense, Remove-IMServerLicense.

## [1.107.0] - 2024-07-02

### IMPORTANT NOTE

- The previous release had the aim to simplify the use of Get-IMAlbum and to align the cmdlet to how a powershell user would expect a cmdlet to function. However the changes caused quite a lot of breaking changes not motivated by the gains. And actually caused some behavior in itself that might be unexpected as a powershell user. Therefor the previous release has been yanked and a new version will be released with more moderate changes.

### Added

- Get-IMAlbum now has a -Name parameter allowing you to return a single album with the name specified.
- Get-IMAlbum now has a -SearchString parameter allowing you to do wildcard searches for album names.
- Many cmdlets, mainly "set"-cmdlets returned an empty string for each object that was updated, this noise is now suppressed.
- Most objects is now tagged with a type name that allows default table formatting to be applied.

### Fixed

- Find-IMPerson, fixed issue where parameter values was not sent correctly to the API
- Find-IMPlace, fixed issue where parameter values was not sent correctly to the API

### Changed

- Get-IMAlbum, Before you had to use -withoutAssets:$false to return assets which is not logical. This parameter has been changed to a switch parameter named IncludeAssets. This means that Get-IMAlbum will by default not return assets as part of the album object returned. You must specify -IncludeAssets if assets should be returned.
- Get-IMAlbum, the parameter -IncludeAssets can now be used in list-mode as well. Previously -IncludeAssets (withoutAssets) was only effective together with the -Id parameter.

## [1.106.1] [YANKED] - 2024-06-27

### IMPORTANT NOTE

- This update contains breaking changes regarding the way the cmdlet behaves when listing albums. Especially when you use the Shared, WithoutAssets parameters. Read the changelog below and test your scripts.

### Added

- A new parameter "-Name" has been added to the Get-IMAlbum cmdlet. This parameter makes a wildcard search for all albums containing that string.

### Changed

- The parameter "shared" for Get-IMAlbum has been changed to a switch parameter and renamed to ExcludeShared. This means that the command will return shared albums by default unless this parameter is used.
- The parameter "withoutAssets has been changed to a switch parameter and renamed to IncludeAssets. This means that the command will not return assets in the asset property of the returned albums by default.

## [1.106.0] - 2024-06-12

### Changed

- Versioning of the PSImmich module will follow the Immich version. For instance v1.105.X will correspond to the API version of Immich 1.105.X. The third number (patch) will be used to track releases/fixes for the PSImmich module specifically. This makes it much easier to find the correct PSImmich version that has feature parity with the version of Immich that is used. If Immich releases a new version that does not require an update to the PSImmich module, that version number will simply be skipped. So the version of PSImmich might not be sequentially incremented.

### Added

- Added new cmdlet Send-IMTestMessage
- Added new cmdlet Get-IMMemory
- Added new cmdlet New-IMMemory
- Added new cmdlet Remove-IMMemory
- Added new cmdlet Set-IMMemory
- New cmdlet Get-IMServerStorage
- New cmdlet Get-IMProfilePicture
- New cmdlet Get-IMAssetThumbnail
- New cmdlet Set-IMAlbumUser to allow changing the user role for an album.
- Set-IMAsset now has a parameter for AddToFace to incorporate the /face/\{id\} API
- New cmdlet Marge-IMPerson to incorporate the /person/\{id\}/merge API
- Get-IMPerson now has a new switch IncludeStatistics to incorporate the /person/\{id\}/statistics API. The switch is not currently available with the list parameter set. However one could use the following to produce the same result Get-IMPerson | Get-IMPerson -IncludeStatistics
- New cmdlet Export-IMPersonThumbnail

### Fixed

- Updated Get-IMAssetMapMarker to the new API location under map and renamed to Get-IMMapMarker
- Updated Get-IMAssetMapStyle to the new API location under map and renamed to GetIMAssetMarker
- Updated Get-IMAuthDevice to the new API location under session and renamed to Get-IMAuthSession.
- Updated Remove-IMAuthDevice to the new API location under session and renamed to Remove-IMAuthSession
- Updated Get-IMAuditFile to the new API location under report
- Updated Get-IMFileChecksum to the new API location under report
- Updated Add-IMAlbumUser to use the new albumUsers property instead of the deprecated sharedUserIds.
- Updated Add-IMAlbumUser to allow configuring the user role.
- Updated Get-IMTimeBucket to the new API location under timeline
- Updated test suite for Get-IMServerFeature now returning the email attribute
- Updated Get-IMServer to also include the result from Get-IMServerStorage

### Removed

- Get-IMAsset will no longer enumerate assets as a search (with optional filters), this API endpoint has been removed from Immich. Instead Find-IMAsset should be used.
- Removed Get-IMSearchTerms due to API deprecation
- Removed Get-IMCuratedLocation due to API deprecation
- Removed Get-IMCuratedObject due to API deprecation

## [1.1.0] - 2024-03-27

### Added

- Set-IMAlbum; Added parameter order

## [1.0.0] - 2024-03-20

### Added

- First release
