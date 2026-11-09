function Search-IMAsset
{
    <#
    .SYNOPSIS
        Searches assets using metadata filters or AI-based smart search.
    .DESCRIPTION
        By default, searches asset metadata using the Immich metadata search. Filter
        parameters are sent in the SearchFilter object. Multiple values for the
        AlbumIds, PersonIds and TagIds parameters match assets that have any of the
        given values.

        With -Smart, uses machine learning to find assets by visual content, faces,
        objects and OCR text. Smart search requires -Query. Results depend on model
        accuracy.

        Date parameters are inclusive: CreatedAfter, TakenAfter, UpdatedAfter and
        TrashedAfter match values on or after the date; the *Before parameters match
        values on or before the date.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Smart
        Uses smart (AI) search instead of metadata search. Requires -Query.
    .PARAMETER Query
        Natural-language query for smart search. Only valid with -Smart.
    .PARAMETER Language
        Language of the smart search query. Only valid with -Smart.
    .PARAMETER Order
        Sort direction for metadata search: asc or desc. Not valid with -Smart.
    .PARAMETER WithPeople
        Include people in the results. Metadata search only.
    .PARAMETER WithStacked
        Include stacked assets in the results. Metadata search only.
    .PARAMETER WithEXIF
        Include EXIF data in the results.
    .PARAMETER Size
        Number of items per page of results sent to the server.
    .PARAMETER City
        Filter by city name.
    .PARAMETER Country
        Filter by country name.
    .PARAMETER State
        Filter by state name.
    .PARAMETER Make
        Filter by camera make.
    .PARAMETER Model
        Filter by camera model.
    .PARAMETER LensModel
        Filter by lens model.
    .PARAMETER Checksum
        Filter by file checksum.
    .PARAMETER EncodedVideoPath
        Filter by encoded video path.
    .PARAMETER Id
        Filter by asset id.
    .PARAMETER LibraryId
        Filter by library id.
    .PARAMETER OCR
        Search text extracted from images via OCR.
    .PARAMETER OriginalFileName
        Filter by original file name.
    .PARAMETER OriginalPath
        Filter by original file path.
    .PARAMETER Rating
        Filter by rating, from -1 to 5.
    .PARAMETER Visibility
        Asset visibility: archive, timeline, hidden, or locked.
    .PARAMETER Type
        Asset type: IMAGE, VIDEO, AUDIO or OTHER.
    .PARAMETER IsEncoded
        Filter by video encoding status.
    .PARAMETER IsFavorite
        Filter by favorite status.
    .PARAMETER IsMotion
        Filter by motion photo status.
    .PARAMETER IsOffline
        Filter by offline status.
    .PARAMETER IsNotInAlbum
        Filter to assets that are in no album ($true) or in at least one album ($false).
    .PARAMETER AlbumIds
        Match assets in any of the given album ids.
    .PARAMETER PersonIds
        Match assets containing any of the given person ids.
    .PARAMETER TagIds
        Match assets with any of the given tag ids.
    .PARAMETER CreatedAfter
        Include assets created on or after this date.
    .PARAMETER CreatedBefore
        Include assets created on or before this date.
    .PARAMETER TakenAfter
        Include assets taken on or after this date.
    .PARAMETER TakenBefore
        Include assets taken on or before this date.
    .PARAMETER UpdatedAfter
        Include assets updated on or after this date.
    .PARAMETER UpdatedBefore
        Include assets updated on or before this date.
    .PARAMETER TrashedAfter
        Include assets trashed on or after this date.
    .PARAMETER TrashedBefore
        Include assets trashed on or before this date.
    .EXAMPLE
        Search-IMAsset -Type VIDEO -IsFavorite $true

        Returns favorite videos using metadata search.
    .EXAMPLE
        Search-IMAsset -Smart -Query 'Road'

        Searches for assets matching the content 'Road' using smart search.
    .EXAMPLE
        Search-IMAsset -OCR 'birthday party'

        Finds photos containing 'birthday party' text.
    .NOTES
        Smart search requires machine learning models to be enabled and trained.
    #>

    [CmdletBinding(DefaultParameterSetName = 'Metadata')]
    param(
        [Parameter()]
        [ImmichSession]$Session = $null,

        [Parameter()]
        [switch]$Smart,

        [Parameter(Mandatory, ParameterSetName = 'Smart')]
        [ApiParameter('query')]
        [Alias('SearchString')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Smart')]
        [ApiParameter('language')]
        [string]$Language,

        [Parameter(ParameterSetName = 'Metadata')]
        [ApiParameter('orderBy.direction')]
        [ValidateSet('asc', 'desc')]
        [string]$Order,

        [Parameter(ParameterSetName = 'Metadata')]
        [ApiParameter('withPeople')]
        [boolean]$WithPeople,

        [Parameter(ParameterSetName = 'Metadata')]
        [ApiParameter('withStacked')]
        [boolean]$WithStacked,

        [Parameter()]
        [ApiParameter('withExif')]
        [boolean]$WithEXIF,

        [Parameter()]
        [ApiParameter('size')]
        [int]$Size,

        [Parameter()]
        [ApiParameter('filter.city.eq')]
        [string]$City,

        [Parameter()]
        [ApiParameter('filter.country.eq')]
        [string]$Country,

        [Parameter()]
        [ApiParameter('filter.state.eq')]
        [string]$State,

        [Parameter()]
        [ApiParameter('filter.make.eq')]
        [string]$Make,

        [Parameter()]
        [ApiParameter('filter.model.eq')]
        [string]$Model,

        [Parameter()]
        [ApiParameter('filter.lensModel.eq')]
        [string]$LensModel,

        [Parameter()]
        [ApiParameter('filter.checksum.eq')]
        [string]$Checksum,

        [Parameter()]
        [ApiParameter('filter.encodedVideoPath.eq')]
        [string]$EncodedVideoPath,

        [Parameter()]
        [ApiParameter('filter.id.eq')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]$Id,

        [Parameter()]
        [ApiParameter('filter.libraryId.eq')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]$LibraryId,

        [Parameter()]
        [ApiParameter('filter.ocr.matches')]
        [string]$OCR,

        [Parameter()]
        [ApiParameter('filter.originalFileName.eq')]
        [string]$OriginalFileName,

        [Parameter()]
        [ApiParameter('filter.originalPath.eq')]
        [string]$OriginalPath,

        [Parameter()]
        [ApiParameter('filter.rating.eq')]
        [ValidateRange(-1, 5)]
        [int]$Rating,

        [Parameter()]
        [ApiParameter('filter.visibility.eq')]
        [ValidateSet('archive', 'timeline', 'hidden', 'locked')]
        [string]$Visibility,

        [Parameter()]
        [ApiParameter('filter.type.eq')]
        [ValidateSet('IMAGE', 'VIDEO', 'AUDIO', 'OTHER')]
        [string]$Type,

        [Parameter()]
        [ApiParameter('filter.isEncoded.eq')]
        [boolean]$IsEncoded,

        [Parameter()]
        [ApiParameter('filter.isFavorite.eq')]
        [boolean]$IsFavorite,

        [Parameter()]
        [ApiParameter('filter.isMotion.eq')]
        [boolean]$IsMotion,

        [Parameter()]
        [ApiParameter('filter.isOffline.eq')]
        [boolean]$IsOffline,

        [Parameter()]
        [switch]$IsNotInAlbum,

        [Parameter()]
        [ApiParameter('filter.albumIds.any')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]$AlbumIds,

        [Parameter()]
        [ApiParameter('filter.personIds.any')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]$PersonIds,

        [Parameter()]
        [ApiParameter('filter.tagIds.any')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]$TagIds,

        [Parameter()]
        [ApiParameter('filter.createdAt.gte')]
        [datetime]$CreatedAfter,

        [Parameter()]
        [ApiParameter('filter.createdAt.lte')]
        [datetime]$CreatedBefore,

        [Parameter()]
        [ApiParameter('filter.takenAt.gte')]
        [datetime]$TakenAfter,

        [Parameter()]
        [ApiParameter('filter.takenAt.lte')]
        [datetime]$TakenBefore,

        [Parameter()]
        [ApiParameter('filter.updatedAt.gte')]
        [datetime]$UpdatedAfter,

        [Parameter()]
        [ApiParameter('filter.updatedAt.lte')]
        [datetime]$UpdatedBefore,

        [Parameter()]
        [ApiParameter('filter.trashedAt.gte')]
        [datetime]$TrashedAfter,

        [Parameter()]
        [ApiParameter('filter.trashedAt.lte')]
        [datetime]$TrashedBefore
    )

    if ($Smart -and -not $PSBoundParameters.ContainsKey('Query'))
    {
        throw 'Smart search requires -Query.'
    }
    if (-not $Smart -and $PSBoundParameters.ContainsKey('Query'))
    {
        throw '-Query is only valid with -Smart.'
    }
    if (-not $Smart -and $PSBoundParameters.ContainsKey('Language'))
    {
        throw '-Language is only valid with -Smart.'
    }
    if ($Smart -and $PSBoundParameters.ContainsKey('Order'))
    {
        throw '-Order is only valid for metadata search and cannot be used with -Smart.'
    }
    if ($Smart -and ($PSBoundParameters.ContainsKey('WithPeople') -or $PSBoundParameters.ContainsKey('WithStacked')))
    {
        throw '-WithPeople and -WithStacked are only valid for metadata search and cannot be used with -Smart.'
    }

    $Body = @{}
    $Body += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name

    if ($PSBoundParameters.ContainsKey('IsNotInAlbum'))
    {
        if (-not $Body.ContainsKey('filter'))
        {
            $Body.filter = @{}
        }
        $Body.filter.hasAlbums = @{ eq = -not $IsNotInAlbum }
    }

    if ($Smart)
    {
        # SmartSearchDto has no cursor in the 3.3.6 spec; paging still uses the deprecated page field.
        $Response = Invoke-ImmichApiSearchSmart -Body $Body -ImmichSession $Session
        $Response.assets.items | ForEach-Object { [AssetResponseDto]::new($PSItem) }

        while ($Response.assets.nextPage)
        {
            $Body.page = [int]$Response.assets.nextPage
            $Response = Invoke-ImmichApiSearchSmart -Body $Body -ImmichSession $Session
            $Response.assets.items | ForEach-Object { [AssetResponseDto]::new($PSItem) }
        }
    }
    else
    {
        $Response = Invoke-ImmichApiSearchAssets -Body $Body -ImmichSession $Session
        $Response.assets.items | ForEach-Object { [AssetResponseDto]::new($PSItem) }

        while ($Response.assets.nextCursor)
        {
            $Body.cursor = $Response.assets.nextCursor
            $Response = Invoke-ImmichApiSearchAssets -Body $Body -ImmichSession $Session
            $Response.assets.items | ForEach-Object { [AssetResponseDto]::new($PSItem) }
        }
    }
}
