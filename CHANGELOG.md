# Changelog for PSImmich

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.3.6-beta001](https://github.com/hanpq/PSImmich/compare/v2.3.1...v3.3.6-beta001) (2026-11-09)


### ⚠ BREAKING CHANGES

* **plugin:** Get-IMPlugin and Get-IMPluginMethod no longer accept -Enabled.
* **person:** Set-IMPerson -Color no longer accepts hex color values.
* **map:** Get-IMMapMarker returns MapMarkerResponseDto and Convert-IMCoordinatesToLocation returns MapReverseGeocodeResponseDto. The Immich 3.3.6 DTOs do not define assetCount (markers) or name (reverse geocode), so those properties are no longer returned.
* **notification:** the cmdlet returns TestEmailResponseDto instead of the raw response.
* **plugin:** Get-IMPlugin returns PluginResponseDto objects instead of IMPlugin custom objects. Property names follow the 3.3.6 spec.
* **auth-session:** SessionResponseDto in Immich 3.3.6 has no ipAddress or userAgent properties, so Get-IMAuthSession no longer returns them.
* **face:** Remove-IMFace always sends the required force field (default $false). Previously it was omitted unless -Force was given.
* **workflow:** New-IMWorkflow and Set-IMWorkflow no longer accept -TriggerType, -Actions, or -Filters. Use -Trigger and -Steps instead.
* **search:** Find-IMAsset is removed; use Search-IMAsset. The parameters -DeviceId, -DeviceAssetId, -IsVisible and -WithDeleted are removed because the Immich 3.3.6 search DTOs no longer define them. Smart search still pages with the deprecated `page` field because 3.3.6 has no replacement.
* **search:** Find-IMCity has been removed. GET /search/cities is a web places-page feature with no PowerShell use case.
* **queue:** queue cmdlets return DTO types named QueueResponseDto and QueueJobResponseDto instead of objects tagged PSImmich.ObjectType.IMQueue and PSImmich.ObjectType.IMQueueJob.
* Get-IMJob output changed from jobCounts to statistics per queue. Clear-IMJob's default now removes waiting jobs without removing failed jobs, instead of the previous empty command.

### Features

* **album:** add album map marker lookup ([cbdbecd](https://github.com/hanpq/PSImmich/commit/cbdbecdf5873f77910fdae4219dc20f673fd5d92))
* **api-key:** add API key secret rotation ([9334724](https://github.com/hanpq/PSImmich/commit/9334724321d50e830b6585bf985946ea9a605eb2))
* **api:** generate internal API routes and DTO classes from the spec ([f7f5ba2](https://github.com/hanpq/PSImmich/commit/f7f5ba20b35ac662bd6c6214ca5027219467b0e0))
* **api:** support multipart headers, extra parts and query parameters ([fb97450](https://github.com/hanpq/PSImmich/commit/fb97450beef0bfec80ef820e5c7f601dbcac1999))
* **asset:** add asset edit lifecycle commands ([833e509](https://github.com/hanpq/PSImmich/commit/833e509a85b8af9196bdccb5978c8b1bbf922860))
* **asset:** add asset file lookup and download ([9e3a0f8](https://github.com/hanpq/PSImmich/commit/9e3a0f8e97b0cfdf1141f69556307f997c6ba216))
* **asset:** add asset folder browsing ([772daee](https://github.com/hanpq/PSImmich/commit/772daee6bb486ee8372fda3c088d38f669973e4d))
* **asset:** add bulk key/value asset metadata commands ([2c990e3](https://github.com/hanpq/PSImmich/commit/2c990e36e2919487019bc1d17bba1656e613fb8b))
* **auth-session:** route auth session cmdlets through the generated API layer ([3c14199](https://github.com/hanpq/PSImmich/commit/3c1419998e3f30ffad9726d48bdc4c5779374dae))
* **duplicate:** add duplicate group resolution ([37a9f5d](https://github.com/hanpq/PSImmich/commit/37a9f5dfd225cbc00bfe3f605ee4c7d2e64244c1))
* **face:** route face cmdlets through the generated API layer ([160f40d](https://github.com/hanpq/PSImmich/commit/160f40d22ddbb1f2c3287f46d5a2544c4ecf45a9))
* **maintenance:** add database backup commands ([a6e2e4e](https://github.com/hanpq/PSImmich/commit/a6e2e4e314325de48f68038f4380c1975fb70758))
* **maintenance:** add integrity report commands ([c9b1d7b](https://github.com/hanpq/PSImmich/commit/c9b1d7b387554c650b4ad903eca60eccc8d01c62))
* migrate job queue commands to the queues API ([1f5fdcf](https://github.com/hanpq/PSImmich/commit/1f5fdcfa453a73466c58b9548f736e0a81c2da09))
* **notification:** add admin notification creation ([f7cffd6](https://github.com/hanpq/PSImmich/commit/f7cffd6cdec917dd64b0861f5729becab573aba7))
* **person:** add people access sharing commands ([0038811](https://github.com/hanpq/PSImmich/commit/003881155c1c9481276e18858eaf5218989a1af2))
* **person:** send person color as the avatar color enum ([3364e80](https://github.com/hanpq/PSImmich/commit/3364e8099ab58c5407cd5c83e28bc6c38831b953))
* **plugin:** add plugin method and workflow template lookup ([887d239](https://github.com/hanpq/PSImmich/commit/887d239a9b1b88ed5388c0eede57849db4713163))
* **plugin:** route Get-IMPlugin through the generated API layer ([207f799](https://github.com/hanpq/PSImmich/commit/207f799076be13c2145fa2ecb34c5c6e48bc7504))
* **search:** merge metadata and smart asset search into Search-IMAsset ([8be7064](https://github.com/hanpq/PSImmich/commit/8be70647775d12f25d4df7ad1fc6558825256d78))
* **search:** route search cmdlets through the internal API layer ([445df0e](https://github.com/hanpq/PSImmich/commit/445df0e9b557bfbfa5c34549ba1a7ceb0fa37cb4))
* **server:** add maintenance status and version check state lookup ([ee1b34f](https://github.com/hanpq/PSImmich/commit/ee1b34fb98b4edb4848b1dc945b590c70bd9db51))
* **timeline:** add spec filters to Get-IMTimeBucket and route session logout through the API ([2bd752c](https://github.com/hanpq/PSImmich/commit/2bd752c6fc62ca062c72f4dbb45a4ecb138adeaf))
* **workflow:** route workflow cmdlets through the internal API layer ([d910ed1](https://github.com/hanpq/PSImmich/commit/d910ed17827fb3c20c102abd765eec3823c0dbb7))


### Bug Fixes

* **activity:** default activity type to comment ([320def3](https://github.com/hanpq/PSImmich/commit/320def3e2d8db13c8a2d741d60b828406d2e01e4))
* **activity:** send piped album id when adding activity ([4115f50](https://github.com/hanpq/PSImmich/commit/4115f50e7d37d20a643c77dd2fb31c4f67685aaa))
* **album:** route album cmdlets through the internal API layer ([e8ed321](https://github.com/hanpq/PSImmich/commit/e8ed32116ac4f91cef98ef24e5eb8b11e6b8c881))
* **api-key:** send default all permission when none is specified ([6334615](https://github.com/hanpq/PSImmich/commit/633461547ccdf73e834837dc068044e094229f33))
* **api:** bind DTO objects to ID parameters from the pipeline ([26a33c0](https://github.com/hanpq/PSImmich/commit/26a33c08d296038bb2d0379b2f8a096facbe3c6f))
* **api:** send booleans and ISO 8601 datetimes for Immich 3.3.6 ([7f56875](https://github.com/hanpq/PSImmich/commit/7f56875673cab06c0e944e8555a742f92ff313a8))
* **api:** serialize nested request bodies to full depth ([cd74ea5](https://github.com/hanpq/PSImmich/commit/cd74ea50090e04a5e17cc8269fd46a05720eac94))
* **asset:** send boolean multipart form fields as lowercase true and false ([5eda64e](https://github.com/hanpq/PSImmich/commit/5eda64e4850c28bd07f2a6392b728a10ad4575ad))
* **asset:** send explicit false for unspecified copy switches ([d9a1ada](https://github.com/hanpq/PSImmich/commit/d9a1ada160d13ecdaf8bd2e7624338b328e5dca7))
* **build:** compare generated API layer independent of line endings ([abca263](https://github.com/hanpq/PSImmich/commit/abca26374d2c0c57a43d75c3ff6ff9623cc0712c))
* code quality ([8721ea9](https://github.com/hanpq/PSImmich/commit/8721ea9c53f8a24e427f36495184655c499c27a3))
* **memory:** send each asset id once when creating a memory ([081f0a0](https://github.com/hanpq/PSImmich/commit/081f0a0e03a8e2286cabf911f84ecd398f4444a4))
* **memory:** send required type and year when creating memories ([9561745](https://github.com/hanpq/PSImmich/commit/956174556b5447a57ab50ac18bbcd5549eeb237a))
* **notification:** send required SMTP transport fields and plain-text password ([a64f42e](https://github.com/hanpq/PSImmich/commit/a64f42e1cbc6cf903199157a4ceba2d97ea6863c))
* **person:** migrate person merging to the bulk endpoint ([9257eae](https://github.com/hanpq/PSImmich/commit/9257eaeda8392a78068fa68fef7973d178de2ee1))
* **person:** unwrap people list and send birth date as a date ([c2a9db6](https://github.com/hanpq/PSImmich/commit/c2a9db696d431f53c0e25084b799ffff3f70618e))
* **plugin:** filter enabled, logging and type client-side ([540bf4d](https://github.com/hanpq/PSImmich/commit/540bf4d5f1a3064ed98616ca974d89f4543bbe81))
* prepare 3.3.6-beta001 prerelease ([06b72d3](https://github.com/hanpq/PSImmich/commit/06b72d3c4ae0b71e18f727d2bc3889bfc125d33d))
* **queue:** send array query parameters as bracketed keys ([709590f](https://github.com/hanpq/PSImmich/commit/709590fe714c8c7daff895c1c890e3179c3a14cc))
* **queue:** stop sending unsupported force field when clearing queues ([97bd06b](https://github.com/hanpq/PSImmich/commit/97bd06bab19166d32bc0dcde6feba234bd8e145e))
* **search:** page metadata and smart search and send memory dates for Immich 3.3.6 ([f7810da](https://github.com/hanpq/PSImmich/commit/f7810da7d79798f204f7a8826142d32c7379f3c4))
* **search:** send nested filter dates in UTC ISO 8601 ([9df5610](https://github.com/hanpq/PSImmich/commit/9df5610075d0c40f2076f976eb67a0a1a423f1f9))
* **server:** read theme from the public config endpoint ([f1ad1fe](https://github.com/hanpq/PSImmich/commit/f1ad1fe65c7feb58149455519e09bd52ed7c7e04))
* **server:** send admin configuration as raw JSON without depth truncation ([bc96928](https://github.com/hanpq/PSImmich/commit/bc969289ff76bba475e834e968222cec679d3e9a))
* **server:** use admin config endpoints for system configuration ([c83dd9f](https://github.com/hanpq/PSImmich/commit/c83dd9ffd6f76b567cff76431e7f1a63a1c09a90))
* **session:** accept relative URIs without a leading slash ([52113d7](https://github.com/hanpq/PSImmich/commit/52113d78fe788c4dea78852b99174e46f08c0568))
* **user:** correct typo in email parameter description ([5b9b106](https://github.com/hanpq/PSImmich/commit/5b9b10605b9687efd4a93b52f37889fed4c8c2b9))


### Code Refactoring

* **map:** use generated map API and return DTOs ([af716f6](https://github.com/hanpq/PSImmich/commit/af716f6e66f23eea787a5fe42e5283b715dd83bb))
* **queue:** route queue cmdlets through the internal API layer ([6a16b30](https://github.com/hanpq/PSImmich/commit/6a16b30e420f0f333baf3c112db21b11cfee49a6))

## [Unreleased]

### [2.3.3] (planned)

The following changes were previously listed under 2.3.2 and are planned for the next release.

### Added

- New cmdlet Copy-IMAssetInfo to support the PUT /assets/copy API.
- Get-IMAsset now has a parameter -IncludeOCR when using the -Id parameter to retrieve OCR data.
- New cmdlet Remove-IMDuplicate to support the DELETE /duplicate API
- New cmdlets Start-IMMaintenanceMode and Stop-IMMaintenanceMode
  - NOTE: These are currently in alpha mode and not completely functional. We can enter maintenance mode successfully but once maintenance mode is enabled we cannot stop maintenance mode trough the API. Therefor it is currently disabled in code with a warning.

## [2.3.1] - 2025-11-22

### BREAKING CHANGES

- Get-IMServer* cmdlets have been removed and replaced by a single Get-IMServer cmdlet that provides switch parameters for the different data.
  - Removed cmdlets
    - Get-IMServerAbout -> Get-IMServer -About
    - Get-IMServerConfig -> Get-IMServer -Configuration
    - Get-IMServerFeature -> Get-IMServer -Features
    - Get-IMServerStatistic -> Get-IMServer -Statistics
    - Get-IMServerStorage -> Get-IMServer -Storage
    - Get-IMServerVersion -> Get-IMServer -Version & Get-IMServer -VersionHistory
    - Get-IMServerMediaTypes -> Get-IMServer -MediaTypes
    - Get-IMTheme -> Get-IMServer -Theme
    - Get-IMConfig -Applied -> Get-IMServer -AppliedSystemConfiguration
    - Get-IMConfig -Default -> Get-IMServer -DefaultSystemConfiguration
    - Get-IMConfig -Storage -> Get-IMServer -StorageTemplateOptions
    - Test-IMPing -> Get-IMServer -Ping
    - Set-IMConfig -RawJson -> Set-IMServer -RawJson

### Added

- New Plugin management cmdlets (Alpha feature):
  - Get-IMPlugin - Retrieve plugins with support for listing all plugins or getting specific plugin by ID
- New Workflow management cmdlets (Alpha feature):
  - NOTE: These are basically untested, the API specification is not complete and workflows are currently under active development by the Immich Team. These cmdlets has been added as a preparation for when the workflow feature is stable.
  - Get-IMWorkflow - Retrieve workflows with support for listing all workflows or getting specific workflow by ID
  - New-IMWorkflow - Create new workflows with configurable name, description, trigger type, actions, and filters
  - Set-IMWorkflow - Update existing workflows including name, description, trigger type, enabled state, actions, and filters
  - Remove-IMWorkflow - Delete workflows with confirmation support
- New server info
  - Get-IMServer -APKLinks
  - Get-IMServer -VersionCheck

### Changed

- Enhanced Memory management functionality:
  - Get-IMMemory - Added support for retrieving memories statistics via new -Statistics parameter
  - Get-IMMemory - New parameters: Order, For, NumberOfMemories, IsSaved, IsTrashed, Type, Statistics
  - Get-IMMemory - Integrated /memories/statistics API functionality
- Updated Job management:
  - Start-IMJob - Now uses the updated POST /jobs API endpoint
- Updated Partner cmdlets for API changes
- Deprecated functionality removal:
  - Get-IMAsset - Removed DeviceID support following API deprecation

## [2.2.5] - 2025-11-17

### Added

- Added pipeline support for Disconnect-Immich cmdlet
- Added automatic test count badge updates in README during build process

### Changed

- Improved cross-platform compatibility for unit tests on Linux and macOS
- Enhanced Windows PowerShell test compatibility and reliability
- Refactored multipart HTTP upload functionality into dedicated private function for better code organization
- Improved build system documentation escaping for website integration

### Fixed

- Fixed unit test execution issues on Linux and macOS platforms
- Fixed Windows PowerShell test failures for ConvertFromSecureString function
- Resolved build process issues with curly bracket escaping in documentation

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
