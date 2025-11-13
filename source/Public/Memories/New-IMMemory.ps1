function New-IMMemory
{
    <#
    .SYNOPSIS
        Creates a new memory collection in Immich.
    .DESCRIPTION
        The New-IMMemory function creates a new memory in Immich, which is a curated collection
        of assets organized around a specific date, event, or theme. Memories help users
        rediscover their photos through temporal organization and can be configured for
        different types of reminiscence experiences.

        The function supports creating 'on_this_day' type memories that highlight assets
        from previous years on the same date, helping users revisit past moments and experiences.
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER MemoryAt
        Specifies the date and time when the memory is anchored. This represents the focal
        point of the memory and is used to organize and present the associated assets.
        Must be provided in a valid DateTime format.
    .PARAMETER SeenAt
        Specifies when the memory was last viewed or acknowledged by the user. This helps
        track user engagement with memories and can influence how memories are presented.
    .PARAMETER Type
        Specifies the type of memory to create. Currently supports 'on_this_day' which
        creates memories that highlight assets from the same date in previous years.
        Defaults to 'on_this_day' if not specified.
    .PARAMETER Year
        Specifies the year component for the memory. This helps organize memories by
        temporal periods and can be used to create year-specific memory collections.
    .PARAMETER AssetIds
        Specifies an array of asset IDs to include in the memory. These assets will be
        associated with the memory and displayed when the memory is viewed. Assets should
        be relevant to the memory's date or theme.
    .EXAMPLE
        New-IMMemory -MemoryAt "2024-01-01 00:00:00" -AssetIds 'bf973405-3f2a-48d2-a687-2ed4167164be', '9c4e0006-3a2b-4967-94b6-7e8bb8490a12'

        Creates a New Year's Day memory for 2024 with two specific assets.
    .EXAMPLE
        New-IMMemory -MemoryAt (Get-Date "2023-12-25") -Type 'on_this_day' -Year 2023

        Creates a Christmas Day memory for 2023 using DateTime object for the date.
    .EXAMPLE
        $assets = Get-IMAsset | Where-Object { $_.fileCreatedAt -like '*-07-04*' }
        New-IMMemory -MemoryAt "2024-07-04" -AssetIds $assets.id

        Creates a memory for July 4th using assets filtered by creation date.
    .NOTES
        Memories provide a way to automatically surface relevant photos from the past,
        enhancing the user experience by helping rediscover forgotten moments.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Do not agree, new initiates an entity not previously known to the system, that should not cause issues.')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter()]
        [ValidateRange(1, [int]::MaxValue)]
        [int]
        $Year,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [ApiParameter('assetIds')]
        [string[]]
        $AssetIds,

        [Parameter(Mandatory)]
        [ApiParameter('memoryAt')]
        [datetime]
        $MemoryAt,

        [Parameter()]
        [ApiParameter('seenAt')]
        [datetime]
        $SeenAt,

        [Parameter()]
        [ValidateSet('on_this_day')]
        [ApiParameter('type')]
        [string]
        $Type = 'on_this_day'
    )

    begin
    {
        $BodyParameters = @{
            assetIds = @()
            data     = @{
                year = $Year
            }
        }
        $BodyParameters += (ConvertTo-ApiParameters -BoundParameters $PSBoundParameters -CmdletName $MyInvocation.MyCommand.Name)
    }

    process
    {
        $AssetIds | ForEach-Object {
            $BodyParameters.assetIds += $PSItem
        }
    }

    end
    {
        InvokeImmichRestMethod -Method Post -RelativePath '/memories' -ImmichSession:$Session -Body $BodyParameters
    }

}
#endregion
