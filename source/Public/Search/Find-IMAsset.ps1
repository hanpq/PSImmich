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
    .PARAMETER order
        Defines sort order
    .PARAMETER originalFileName
        Original file name filter
    .PARAMETER originalPath
        Original path filter
    .PARAMETER personIds
        Person id filter
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
    .PARAMETER withDeleted
        Deleted filter
    .PARAMETER withExif
        Exif filter
    .PARAMETER withPeople
        With people filter
    .PARAMETER withStacked
        Stacked filter
    .PARAMETER Visibility
        Asset visibility filter (archive, timeline, hidden, locked)
    .EXAMPLE
        Find-IMAsset -createdAfter (Get-Date).AddDays(-30)

        Retreives all assets created in the last 30 days
    #>

    [CmdletBinding(DefaultParameterSetName = 'list-shared')]
    param(
        [Parameter()]
        [ImmichSession]$Session = $null,

        [Parameter()]
        [ApiParameter('checksum')]
        [string]$Checksum,

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
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [ApiParameter('deviceAssetId')]
        [string]$DeviceAssetId,

        [Parameter()]
        [ApiParameter('deviceId')]
        [string]$DeviceId,

        [Parameter()]
        [ApiParameter('encodedVideoPath')]
        [string]$EncodedVideoPath,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [ApiParameter('id')]
        [string]$Id,

        [Parameter()]
        [ApiParameter('isEncoded')]
        [boolean]$isEncoded,

        [Parameter()]
        [ApiParameter('isFavorite')]
        [boolean]$isFavorite,

        [Parameter()]
        [ApiParameter('isMotion')]
        [boolean]$isMotion,

        [Parameter()]
        [ApiParameter('isNotInAlbum')]
        [boolean]$isNotInAlbum,

        [Parameter()]
        [ApiParameter('isOffline')]
        [boolean]$isOffline,

        [Parameter()]
        [ValidateSet('archive', 'timeline', 'hidden', 'locked')]
        [ApiParameter('visibility')]
        [string]$Visibility,

        [Parameter()]
        [ApiParameter('lensModel')]
        [string]$LensModel,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [ApiParameter('libraryId')]
        [string]$LibraryId,

        [Parameter()]
        [ApiParameter('make')]
        [string]$Make,

        [Parameter()]
        [ApiParameter('model')]
        [string]$Model,

        [Parameter()]
        [ValidateSet('asc', 'desc')]
        [ApiParameter('order')]
        [string]$Order,

        [Parameter()]
        [ApiParameter('originalFileName')]
        [string]$OriginalFileName,

        [Parameter()]
        [ApiParameter('originalPath')]
        [string]$OriginalPath,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [ApiParameter('personIds')]
        [string[]]$PersonIds,

        [Parameter()]
        [ApiParameter('size')]
        [int]$Size,

        [Parameter()]
        [ApiParameter('state')]
        [string]$State,

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
        [ValidateSet('IMAGE', 'VIDEO', 'AUDIO', 'OTHER')]
        [ApiParameter('type')]
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
        [boolean]$WithExif,

        [Parameter()]
        [ApiParameter('withPeople')]
        [boolean]$WithPeople,

        [Parameter()]
        [ApiParameter('withStacked')]
        [boolean]$WithStacked
    )

    $BodyParameters = @{}
    $BodyParameters += ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name

    $Result = InvokeImmichRestMethod -Method POST -RelativePath '/search/metadata' -ImmichSession:$Session -Body $BodyParameters | Select-Object -ExpandProperty assets
    $Result | Select-Object -ExpandProperty items | AddCustomType IMAsset

    while ($Result.NextPage)
    {
        $BodyParameters.page = $Result.NextPage
        $Result = InvokeImmichRestMethod -Method POST -RelativePath '/search/metadata' -ImmichSession:$Session -Body $BodyParameters | Select-Object -ExpandProperty assets
        $Result | Select-Object -ExpandProperty items | AddCustomType IMAsset
    }

}
#endregion
