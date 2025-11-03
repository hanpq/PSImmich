function New-IMStack
{
    <#
    .DESCRIPTION
        Creates a new Immich stack from assets
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER AssetIds
        Array of asset IDs to include in the stack. The first asset becomes the primary asset. Minimum 2 assets required.
    .EXAMPLE
        New-IMStack -AssetIds @('asset-id-1', 'asset-id-2', 'asset-id-3')

        Creates a new stack with the specified assets, with asset-id-1 as the primary
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions','', Justification='Do not agree that -new- alters system state')]
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

    BEGIN
    {
        $BodyParameters = @{
            assetIds = $AssetIds
        }
    }

    PROCESS
    {
        InvokeImmichRestMethod -Method Post -RelativePath '/stacks' -ImmichSession:$Session -Body $BodyParameters | AddCustomType IMStack
    }
}
