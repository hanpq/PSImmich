function Search-IMAsset
{
    <#
    .SYNOPSIS
        Searches assets using AI content analysis.
    .DESCRIPTION
        Uses machine learning to find assets by visual content, faces, objects, and OCR text.
        Results may vary based on model accuracy. For metadata searches, use Find-IMAsset.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER City
        Filter by city name.
    .PARAMETER Country
        Filter by country name.
    .PARAMETER CreatedAfter
        Include assets created after this date.
    .PARAMETER CreatedBefore
        Include assets created before this date.
    .PARAMETER DeviceId
        Filter by device identifier.
    .PARAMETER Visibility
        Asset visibility: archive, timeline, hidden, or locked.
    .PARAMETER OCR
        Search text extracted from images via OCR.
    .PARAMETER IsEncoded
        Filter by video encoding status.
    .PARAMETER isFavorite
        Favorite filter
    .PARAMETER isMotion
        Motion filter
    .PARAMETER isNotInAlbum
        Not in Album filter
    .PARAMETER isOffline
        Offline filter
    .PARAMETER lensModel
        Lens model filter
    .PARAMETER libraryId
        Library id filter
    .PARAMETER AlbumIds
        Album id filter (array of UUIDs)
    .PARAMETER make
        Make filter
    .PARAMETER model
        Model filter
    .PARAMETER language
        Language filter
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
    .PARAMETER withDeleted
        Deleted filter
    .PARAMETER withExif
        Exif filter
    .PARAMETER ResultSize
        Number of items to return. Defaults to 0 which means all items.
    .EXAMPLE
        Search-IMAsset -Query 'Road'

        Searches for assets matching content Road.
    .EXAMPLE
        Search-IMAsset -OCR 'birthday party'

        Finds photos containing 'birthday party' text.
    .NOTES
        Requires machine learning models to be enabled and trained.

    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]$Session = $null,

        [Parameter()]
        [ApiParameter('city')]
        [string]$City,

        [Parameter()]
        [ApiParameter('country')]
        [string]$Country,

        [Parameter()]
        [ApiParameter('createdAfter')]
        [datetime]$CreatedAfter,

        [Parameter()]
        [ApiParameter('createdBefore')]
        [datetime]$CreatedBefore,

        [Parameter()]
        [ApiParameter('deviceId')]
        [string]$DeviceId,

        [Parameter()]
        [ApiParameter('visibility')]
        [ValidateSet('archive', 'timeline', 'hidden', 'locked')]
        [string]$Visibility,

        [Parameter()]
        [ApiParameter('ocr')]
        [string]$OCR,

        [Parameter()]
        [ApiParameter('isEncoded')]
        [boolean]$IsEncoded,

        [Parameter()]
        [ApiParameter('isFavorite')]
        [boolean]$IsFavorite,

        [Parameter()]
        [ApiParameter('isMotion')]
        [boolean]$IsMotion,

        [Parameter()]
        [ApiParameter('isNotInAlbum')]
        [boolean]$IsNotInAlbum,

        [Parameter()]
        [ApiParameter('isOffline')]
        [boolean]$IsOffline,

        [Parameter()]
        [ApiParameter('lensModel')]
        [string]$LensModel,

        [Parameter()]
        [ApiParameter('libraryId')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]$LibraryId,

        [Parameter()]
        [ApiParameter('albumIds')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]$AlbumIds,

        [Parameter()]
        [ApiParameter('make')]
        [string]$Make,

        [Parameter()]
        [ApiParameter('model')]
        [string]$Model,

        [Parameter()]
        [ApiParameter('language')]
        [string]$Language,

        [Parameter()]
        [ApiParameter('personIds')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]$PersonIds,

        [Parameter(Mandatory)]
        [ApiParameter('query')]
        [Alias('SearchString')]
        [string]$Query,

        [Parameter()]
        [ApiParameter('rating')]
        [ValidateRange(-1, 5)]
        [int]$Rating,

        [Parameter()]
        [ApiParameter('size')]
        [int]$Size,

        [Parameter()]
        [ApiParameter('state')]
        [string]$State,

        [Parameter()]
        [ApiParameter('tagIds')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]$TagIds,

        [Parameter()]
        [ApiParameter('takenAfter')]
        [datetime]$TakenAfter,

        [Parameter()]
        [ApiParameter('takenBefore')]
        [datetime]$TakenBefore,

        [Parameter()]
        [ApiParameter('trashedAfter')]
        [datetime]$TrashedAfter,

        [Parameter()]
        [ApiParameter('trashedBefore')]
        [datetime]$TrashedBefore,

        [Parameter()]
        [ApiParameter('type')]
        [ValidateSet('IMAGE', 'VIDEO', 'AUDIO', 'OTHER')]
        [string]$Type,

        [Parameter()]
        [ApiParameter('updatedAfter')]
        [datetime]$UpdatedAfter,

        [Parameter()]
        [ApiParameter('updatedBefore')]
        [datetime]$UpdatedBefore,

        [Parameter()]
        [ApiParameter('withDeleted')]
        [boolean]$WithDeleted,

        [Parameter()]
        [ApiParameter('withExif')]
        [boolean]$WithEXIF
    )

    $Body = @{}
    $Body += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)

    $Result = InvokeImmichRestMethod -Method POST -RelativePath '/search/smart' -ImmichSession:$Session -Body $Body | Select-Object -ExpandProperty assets
    $Result | Select-Object -ExpandProperty items | AddCustomType IMAsset

    while ($Result.NextPage)
    {
        $Body.page = $Result.NextPage
        $Result = InvokeImmichRestMethod -Method POST -RelativePath '/search/smart' -ImmichSession:$Session -Body $Body | Select-Object -ExpandProperty assets
        $Result | Select-Object -ExpandProperty items | AddCustomType IMAsset
    }
}
#endregion
