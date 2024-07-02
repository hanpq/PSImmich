function Find-IMAsset
{
    <#
    .DESCRIPTION
        Find assets
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER checksum
        Checksum filter
    .PARAMETER city
        City filter
    .PARAMETER country
        Country filter
    .PARAMETER createdAfter
        CreatedAfter filter
    .PARAMETER createdBefore
        CreatedBefore filter
    .PARAMETER deviceAssetId
        Device Asset Id filter
    .PARAMETER deviceId
        Device Id filter
    .PARAMETER encodedVideoPath
        Encoded Video path filter
    .PARAMETER id
        Id filter
    .PARAMETER isArchived
        Archvied filter
    .PARAMETER isEncoded
        Encoded filter
    .PARAMETER isExternal
        External filter
    .PARAMETER isFavorite
        Favorite filter
    .PARAMETER isMotion
        Motion filter
    .PARAMETER isNotInAlbum
        Not in Album filter
    .PARAMETER isOffline
        Offline filter
    .PARAMETER isReadOnly
        Read only filter
    .PARAMETER isVisible
        Visible filter
    .PARAMETER lensModel
        Lens model filter
    .PARAMETER libraryId
        Library id filter
    .PARAMETER make
        Make filter
    .PARAMETER model
        Model filter
    .PARAMETER order
        Defines sort order
    .PARAMETER originalFileName
        Original file name filter
    .PARAMETER originalPath
        Original path filter
    .PARAMETER personIds
        Person id filter
    .PARAMETER resizePath
        Resize path filter
    .PARAMETER size
        Size of rest call page
    .PARAMETER state
        State filter
    .PARAMETER takenAfter
        Taken after filter
    .PARAMETER takenBefore
        Taken before filter
    .PARAMETER trashedAfter
        Trashed after filter
    .PARAMETER trashedBefore
        Trashed before filter
    .PARAMETER type
        Type filter
    .PARAMETER updatedAfter
        Updated after filter
    .PARAMETER updatedBefore
        Updated before filter
    .PARAMETER webpPath
        Webp path filter
    .PARAMETER withArchived
        Archived filter
    .PARAMETER withDeleted
        Deleted filter
    .PARAMETER withExif
        Exif filter
    .PARAMETER withPeople
        With people filter
    .PARAMETER withStacked
        Stacked filter
    .EXAMPLE
        Find-IMAsset -createdAfter (Get-Date).AddDays(-30)

        Retreives all assets created in the last 30 days
    #>

    [CmdletBinding(DefaultParameterSetName = 'list-shared')]
    param(
        [Parameter()]
        [ImmichSession]$Session = $null,

        [Parameter()]
        [string]$checksum,

        [Parameter()]
        [string]$city,

        [Parameter()]
        [string]$country,

        [Parameter()]
        [datetime]$createdAfter,

        [Parameter()]
        [datetime]$createdBefore,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]$deviceAssetId,

        [Parameter()]
        [string]$deviceId,

        [Parameter()]
        [string]$encodedVideoPath,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]$id,

        [Parameter()]
        [boolean]$isArchived,

        [Parameter()]
        [boolean]$isEncoded,

        [Parameter()]
        [boolean]$isExternal,

        [Parameter()]
        [boolean]$isFavorite,

        [Parameter()]
        [boolean]$isMotion,

        [Parameter()]
        [boolean]$isNotInAlbum,

        [Parameter()]
        [boolean]$isOffline,

        [Parameter()]
        [boolean]$isReadOnly,

        [Parameter()]
        [boolean]$isVisible,

        [Parameter()]
        [string]$lensModel,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]$libraryId,

        [Parameter()]
        [string]$make,

        [Parameter()]
        [string]$model,

        [Parameter()]
        [ValidateSet('asc', 'desc')]
        [string]$order,

        [Parameter()]
        [string]$originalFileName,

        [Parameter()]
        [string]$originalPath,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]$personIds,

        [Parameter()]
        [string]$resizePath,

        [Parameter()]
        [int]$size,

        [Parameter()]
        [string]$state,

        [Parameter()]
        [datetime]$takenAfter,

        [Parameter()]
        [datetime]$takenBefore,

        [Parameter()]
        [datetime]$trashedAfter,

        [Parameter()]
        [datetime]$trashedBefore,

        [Parameter()]
        [ValidateSet('IMAGE', 'VIDEO', 'AUDIO', 'OTHER')]
        [string]$type,

        [Parameter()]
        [datetime]$updatedAfter,

        [Parameter()]
        [datetime]$updatedBefore,

        [Parameter()]
        [string]$webpPath,

        [Parameter()]
        [boolean]$withArchived,

        [Parameter()]
        [boolean]$withDeleted,

        [Parameter()]
        [boolean]$withExif,

        [Parameter()]
        [boolean]$withPeople,

        [Parameter()]
        [boolean]$withStacked
    )

    $Body = @{}
    $Body += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'checksum', 'city', 'country', 'createdAfter', 'createdBefore', 'deviceAssetId', 'deviceId', 'encodedVideoPath', 'id', 'isArchived', 'isEncoded', 'isExternal', 'isFavorite', 'isMotion', 'isNotInAlbum', 'isOffline', 'isReadOnly', 'isVisible', 'lensModel', 'libraryId', 'make', 'model', 'order', 'originalFileName', 'originalPath', 'page', 'personIds', 'resizePath', 'size', 'state', 'takenAfter', 'takenBefore', 'trashedAfter', 'trashedBefore', 'type', 'updatedAfter', 'updatedBefore', 'webpPath', 'withArchived', 'withDeleted', 'withExif', 'withPeople', 'withStacked')

    $Result = InvokeImmichRestMethod -Method POST -RelativePath '/search/metadata' -ImmichSession:$Session -Body $Body | Select-Object -ExpandProperty assets
    $Result | Select-Object -ExpandProperty items | AddCustomType IMAsset

    while ($Result.NextPage)
    {
        $Body.page = $Result.NextPage
        $Result = InvokeImmichRestMethod -Method POST -RelativePath '/search/metadata' -ImmichSession:$Session -Body $Body | Select-Object -ExpandProperty assets
        $Result | Select-Object -ExpandProperty items | AddCustomType IMAsset
    }

}
#endregion
