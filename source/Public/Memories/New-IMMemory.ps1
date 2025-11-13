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
