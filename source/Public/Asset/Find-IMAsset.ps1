function Find-IMAsset
{
    <#
    .DESCRIPTION
        Find assets
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER checksum
        asd
    .PARAMETER city
        asd
    .PARAMETER country
        asd
    .PARAMETER createdAfter
        asd
    .PARAMETER createdBefore
        asd
    .PARAMETER deviceAssetId
        asd
    .PARAMETER deviceId
        asd
    .PARAMETER encodedVideoPath
        asd
    .PARAMETER id
        asd
    .PARAMETER isArchived
        asd
    .PARAMETER isEncoded
        asd
    .PARAMETER isExternal
        asd
    .PARAMETER isFavorite
        asd
    .PARAMETER isMotion
        asd
    .PARAMETER isNotInAlbum
        asd
    .PARAMETER isOffline
        asd
    .PARAMETER isReadOnly
        asd
    .PARAMETER isVisible
        asd
    .PARAMETER lensModel
        asd
    .PARAMETER libraryId
        asd
    .PARAMETER make
        asd
    .PARAMETER model
        asd
    .PARAMETER order
        asd
    .PARAMETER originalFileName
        asd
    .PARAMETER originalPath
        asd
    .PARAMETER personIds
        asd
    .PARAMETER resizePath
        asd
    .PARAMETER size
        asd
    .PARAMETER state
        asd
    .PARAMETER takenAfter
        asd
    .PARAMETER takenBefore
        asd
    .PARAMETER trashedAfter
        asd
    .PARAMETER trashedBefore
        asd
    .PARAMETER type
        asd
    .PARAMETER updatedAfter
        asd
    .PARAMETER updatedBefore
        asd
    .PARAMETER webpPath
        asd
    .PARAMETER withArchived
        asd
    .PARAMETER withDeleted
        asd
    .PARAMETER withExif
        asd
    .PARAMETER withPeople
        asd
    .PARAMETER withStacked
        asd
    .EXAMPLE
        Find-IMAsset

        Find assets
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
    $Result | Select-Object -ExpandProperty items

    while ($Result.NextPage)
    {
        $Body.page = $Result.NextPage
        $Result = InvokeImmichRestMethod -Method POST -RelativePath '/search/metadata' -ImmichSession:$Session -Body $Body | Select-Object -ExpandProperty assets
        $Result | Select-Object -ExpandProperty items
    }

}
#endregion
