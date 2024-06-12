function New-IMMemory
{
    <#
    .DESCRIPTION
        Adds a new memory
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER MemoryAt
        Defines the MemoryAt property
    .PARAMETER SeenAt
        Defines the SeenAt property
    .PARAMETER Type
        Defines the type of memory. Defaults to 'on_this_day'. Valid values are 'on_this_day'
    .PARAMETER Year
        Defines the year of the memory.
    .PARAMETER assetIds
        Defines a list of assets to add to the memory
    .EXAMPLE
        New-IMMemory -MemoryAt "2024-01-01 00:00:00" -assetIds <assetid>,<assetid>

        Create a new memory for the date and assets.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Do not agree, new initiates an entity not previously known to the system, that should not cause issues.')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter()]
        [ValidateRange(1, [int]::MaxValue)]
        [boolean]
        $Year,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $AssetIds,

        [Parameter(Mandatory)]
        [datetime]
        $MemoryAt,

        [Parameter()]
        [datetime]
        $SeenAt,

        [Parameter()]
        [ValidateSet('on_this_day')]
        [string]
        $Type = 'on_this_day'
    )

    BEGIN
    {
        $BodyParameters = @{}
        $BodyParameters += (SelectBinding -Binding $PSBoundParameters -SelectProperty 'MemoryAt', 'SeenAt', 'Type' -NameMapping @{
                MemoryAt = 'memoryAt'
                SeenAt   = 'seenAt'
                Type     = 'type'
            })
        $BodyParameters.assetIds += [string[]]@()
        $BodyParameters.data += [hashtable]@{
            year = $year
        }
    }

    PROCESS
    {
        $AssetIds | ForEach-Object {
            $BodyParameters.assetIds += $PSItem
        }
    }

    END
    {
        InvokeImmichRestMethod -Method Post -RelativePath '/memories' -ImmichSession:$Session -Body $BodyParameters
    }

}
#endregion
