function Search-IMAsset
{
    <#
    .DESCRIPTION
        Search for assets using smart search
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER city
        City filter
    .PARAMETER country
        Country filter
    .PARAMETER createdAfter
        CreatedAfter filter
    .PARAMETER createdBefore
        CreatedBefore filter
    .PARAMETER deviceId
        Device Id filter
    .PARAMETER isArchived
        Archvied filter
    .PARAMETER isEncoded
        Encoded filter
    .PARAMETER isFavorite
        Favorite filter
    .PARAMETER isMotion
        Motion filter
    .PARAMETER isNotInAlbum
        Not in Album filter
    .PARAMETER isOffline
        Offline filter
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
    .PARAMETER personIds
        Person id filter
    .PARAMETER query
        Query filter
    .PARAMETER rating
        Rating filter
    .PARAMETER size
        Size of rest call page
    .PARAMETER state
        State filter
    .PARAMETER tagIds
        Tag id filter
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
    .PARAMETER withArchived
        Archived filter
    .PARAMETER withDeleted
        Deleted filter
    .PARAMETER withExif
        Exif filter
    .PARAMETER ResultSize
        Number of items to return. Defaults to 0 which means all items.
    .EXAMPLE
        Search-IMAsset -Query 'Road'

        Searches for assets matching content Road.
    #>

    [CmdletBinding(DefaultParameterSetName = 'list-shared')]
    param(
        [Parameter()]
        [ImmichSession]$Session = $null,

        [Parameter()]
        [string]$city,

        [Parameter()]
        [string]$country,

        [Parameter()]
        [datetime]$createdAfter,

        [Parameter()]
        [datetime]$createdBefore,

        [Parameter()]
        [string]$deviceId,

        [Parameter()]
        [boolean]$isArchived,

        [Parameter()]
        [boolean]$isEncoded,

        [Parameter()]
        [boolean]$isFavorite,

        [Parameter()]
        [boolean]$isMotion,

        [Parameter()]
        [boolean]$isNotInAlbum,

        [Parameter()]
        [boolean]$isOffline,

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
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]$personIds,

        [Parameter(Mandatory)]
        [Alias('SearchString')][string]$query,

        [Parameter()]
        [ValidateRange(-1, 5)][int]$rating,

        [Parameter()]
        [int]$size,

        [Parameter()]
        [string]$state,

        [Parameter()]
        [string[]]$tagIds,

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
        [boolean]$withArchived,

        [Parameter()]
        [boolean]$withDeleted,

        [Parameter()]
        [boolean]$withExif
    )

    $Body = @{}
    $Body += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'city', 'country', 'createdAfter', 'createdBefore', 'deviceId', 'isArchived', 'isEncoded', 'isFavorite', 'isMotion', 'isNotInAlbum', 'isOffline', 'isVisible', 'lensModel', 'libraryId', 'make', 'model', 'personIds', 'query', 'rating', 'size', 'state', 'tagIds', 'takenAfter', 'takenBefore', 'trashedAfter', 'trashedBefore', 'type', 'updatedAfter', 'updatedBefore', 'withArchived', 'withDeleted', 'withExif')

    $Result = InvokeImmichRestMethod -Method POST -RelativePath '/search/smart' -ImmichSession:$Session -Body $Body | Select-Object -ExpandProperty assets
    $Result | Select-Object -ExpandProperty items | AddCustomType IMAsset

    while ($Result.NextPage)
    {
        $Body.page = $Result.NextPage
        $Result = InvokeImmichRestMethod -Method POST -RelativePath '/search/metadata' -ImmichSession:$Session -Body $Body | Select-Object -ExpandProperty assets
        $Result | Select-Object -ExpandProperty items | AddCustomType IMAsset
    }
}
#endregion
