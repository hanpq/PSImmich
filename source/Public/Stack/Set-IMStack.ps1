function Set-IMStack
{
    <#
    .DESCRIPTION
        Updates an existing Immich stack
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER Id
        The stack ID to update
    .PARAMETER PrimaryAssetId
        The asset ID to set as the primary asset for this stack
    .EXAMPLE
        Set-IMStack -Id <stackId> -PrimaryAssetId <assetId>

        Updates the stack to use the specified asset as the primary asset
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $Id,

        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $PrimaryAssetId
    )

    BEGIN
    {
        $BodyParameters = @{
            primaryAssetId = $PrimaryAssetId
        }
    }

    PROCESS
    {
        InvokeImmichRestMethod -Method Put -RelativePath "/stacks/$Id" -ImmichSession:$Session -Body $BodyParameters | AddCustomType IMStack
    }
}
