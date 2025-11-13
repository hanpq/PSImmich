function New-IMStack
{
    <#
    .SYNOPSIS
        Creates a new asset stack.
    .DESCRIPTION
        Groups related assets into a stack with the first asset as primary. Minimum 2 assets required.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER AssetIds
        Array of asset IDs to stack. First asset becomes the primary asset.
    .EXAMPLE
        New-IMStack -AssetIds @('asset1', 'asset2', 'asset3')

        Creates stack with asset1 as primary.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Do not agree that -new- alters system state')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string[]]
        $AssetIds
    )

    begin
    {
        $BodyParameters = @{
            assetIds = $AssetIds
        }
    }

    process
    {
        InvokeImmichRestMethod -Method Post -RelativePath '/stacks' -ImmichSession:$Session -Body $BodyParameters | AddCustomType IMStack
    }
}
