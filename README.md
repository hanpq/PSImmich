> :warning: **IMPORTANT**
> This module is early in it´s development phase. Many API function and features are not yet available. You are welcome to contribute on GitHub to accelerate progress further.

# PSImmich

This project has adopted the following policies [![CodeOfConduct](https://img.shields.io/badge/Code%20Of%20Conduct-gray)](https://github.com/hanpq/PSImmich/blob/main/.github/CODE_OF_CONDUCT.md) [![Contributing](https://img.shields.io/badge/Contributing-gray)](https://github.com/hanpq/PSImmich/blob/main/.github/CONTRIBUTING.md) [![Security](https://img.shields.io/badge/Security-gray)](https://github.com/hanpq/PSImmich/blob/main/.github/SECURITY.md) 

## Project status
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/hanpq/PSImmich/build.yml?branch=main&label=build&logo=github)](https://github.com/hanpq/PSImmich/actions/workflows/build.yml) [![Codecov](https://img.shields.io/codecov/c/github/hanpq/PSImmich?logo=codecov&token=qJqWlwMAiD)](https://codecov.io/gh/hanpq/PSImmich) [![Platform](https://img.shields.io/powershellgallery/p/PSImmich?logo=ReasonStudios)](https://img.shields.io/powershellgallery/p/PSImmich) [![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/PSImmich?label=downloads)](https://www.powershellgallery.com/packages/PSImmich) [![License](https://img.shields.io/github/license/hanpq/PSImmich)](https://github.com/hanpq/PSImmich/blob/main/LICENSE) [![docs](https://img.shields.io/badge/docs-getps.dev-blueviolet)](https://getps.dev/modules/PSImmich/getstarted) [![changelog](https://img.shields.io/badge/changelog-getps.dev-blueviolet)](https://github.com/hanpq/PSImmich/blob/main/CHANGELOG.md) ![GitHub release (latest SemVer including pre-releases)](https://img.shields.io/github/v/release/hanpq/PSImmich?label=version&sort=semver) ![GitHub release (latest SemVer including pre-releases)](https://img.shields.io/github/v/release/hanpq/PSImmich?include_prereleases&label=prerelease&sort=semver) ![Static Badge](https://img.shields.io/badge/85%25%20(111%2F130)-green?label=API%20Coverage) ![Static Badge2](https://img.shields.io/badge/951-green?label=Unit%2FQuality%2FIntegration%20tests)


## About

PSImmich is a Powershell API wrapper for Immich

## Installation

### PowerShell Gallery

To install from the PowerShell gallery using PowerShellGet run the following command:

```powershell
Install-Module PSImmich -Scope CurrentUser
```

## Usage

Before calling the Immich cmdlets a session needs to be created. Currently it is supported to use an API key or credentials (username and password)

```powershell
Connect-Immich -BaseURL 'https://immich.domain.com' -AccessToken 'ztKkvGWVIacJATX7RLCbWCISpamwEQkLpakn8O48acE'
```

```powershell
$Cred = Get-Credential
Connect-Immich -BaseURL 'https://immich.domain.com' -Credential $Cred
```

You can verify that the connection is working by calling `Get-IMSession` and verifying that `AccessTokenValid` is `true`

```powershell
Get-IMSession

BaseUri          : https://immich.domain.com
AuthMethod       : AccessToken
AccessToken      : System.Security.SecureString
AccessTokenValid : True
Credential       : 
JWT              : 
APIUri           : https://immich.domain.com/api
ImmichVersion    : 1.98.2
SessionID        : 67055f46-51aa-42a2-8471-46170c441558
```

The session object can be passed to all cmdlets. This is useful if connection to more than one Immich instance is needed.

```powershell
$Session1 = Connect-Immich -BaseURL 'https://immich.domain.com' -AccessToken 'ztKkvGWVIacJATX7RLCbWCISpamwEQkLpakn8O48acE' -PassThru

Get-IMAsset -Session $Session1
```

To see available cmdlets you can use the following command

```powershell
Get-Command -Module PSImmich  | Format-Wide -Column 4 -Property Name                     

Add-IMActivity     Add-IMAlbumAsset          Add-IMAlbumUser    Add-IMAsset
Add-IMAssetTag     Add-IMMyProfilePicture    Add-IMPartner      Add-IMSharedLinkAsset 
...
...

```

## Available commands

Below is a reference of the available command. For documentation about each command please see the [docs](https://getps.dev/modules/PSImmich/getstarted)

### Activity

- Add-IMActivity
- Get-IMActivity
- Get-IMActivityStatistic
- Remove-IMActivity

### Album

- Add-IMAlbumAsset
- Add-IMAlbumUser
- Get-IMAlbum
- Get-IMAlbumCount
- New-IMAlbum
- Remove-IMAlbum
- Remove-IMAlbumAsset
- Remove-IMAlbumUser
- Set-IMAlbum

### API key

- Get-IMAPIKey
- New-IMAPIKey
- Remove-IMAPIKey
- Set-IMAPIKey

### Asset

- Add-IMAsset
- Find-IMAsset
- Get-IMAsset
- Get-IMAssetMapMarker
- Get-IMAssetMemoryLane
- Get-IMAssetSearchTerm
- Get-IMAssetStatistic
- Get-IMCuratedLocation
- Get-IMCuratedObject
- Get-IMTimeBucket
- Remove-IMAsset
- Restore-IMAsset
- Save-IMAsset
- Set-IMAsset
- Start-IMAssetJob

### Audit

- Get-IMAuditDelete
- Get-IMAuditFile
- Get-IMFileChecksum

### Auth

- Get-IMAuthDevice
- Remove-IMAuthDevice
- Test-IMAccessToken

### Face

- Get-IMFace

### Job

- Clear-IMJob
- Get-IMJob
- Resume-IMJob
- Start-IMJob
- Suspend-IMJob

### Library

- Get-IMLibrary
- Measure-IMLibrary
- New-IMLibrary
- Remove-IMLibrary
- Remove-IMOfflineLibraryFile
- Set-IMLibrary
- Start-IMLibraryScan
- Test-IMLibrary

### Partner

- Add-IMPartner
- Get-IMPartner
- Remove-IMPartner
- Set-IMPartner

### Person

- Get-IMPerson
- New-IMPerson
- Set-IMPerson

### Config

- Get-IMConfig
- Set-IMConfig

### Server

- Get-IMServer
- Get-IMServerConfig
- Get-IMServerFeature
- Get-IMServerInfo
- Get-IMServerStatistic
- Get-IMServerVersion
- Get-IMSupportedMediaType
- Get-IMTheme
- Test-IMPing

### Session 

- Connect-Immich
- Disconnect-Immich
- Get-IMSession
- Invoke-ImmichMethod

### SharedLink

- Add-IMSharedLinkAsset
- Get-IMSharedLink
- New-IMSharedLink
- Remove-IMSharedLink
- Remove-IMSharedLinkAsset
- Set-IMSharedLink

### Tag

- Add-IMAssetTag
- Get-IMTag
- New-IMTag
- Remove-IMAssetTag
- Remove-IMTag
- Rename-IMTag

### User

- Add-IMMyProfilePicture
- Get-IMUser
- New-IMUser
- Remove-IMMyProfilePicture
- Remove-IMUser
- Restore-IMUser
- Set-IMUser
