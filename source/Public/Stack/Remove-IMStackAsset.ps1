function Remove-IMStackAsset
{
    <#
    .DESCRIPTION
        Removes an asset from an Immich stack
    .PARAMETER Session
        Optionally define a immich session object to use. This is useful when you are connected to more than one immich instance.

        -Session $Session
    .PARAMETER StackId
        The stack ID from which to remove the asset
    .PARAMETER AssetId
        The asset ID to remove from the stack
    .PARAMETER Force
        Suppress confirmation prompt
    .EXAMPLE
        Remove-IMStackAsset -StackId <stackId> -AssetId <assetId>

        Removes the specified asset from the stack
    .EXAMPLE
        Remove-IMStackAsset -StackId <stackId> -AssetId <assetId> -Force

        Removes the asset from the stack without confirmation
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $StackId,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $AssetId,

        [Parameter()]
        [switch]
        $Force
    )

    BEGIN
    {
        if ($Force)
        {
            $ConfirmPreference = 'None'
        }
    }

    PROCESS
    {
        if ($PSCmdlet.ShouldProcess("Asset $AssetId from Stack $StackId", "Remove"))
        {
            InvokeImmichRestMethod -Method Delete -RelativePath "/stacks/$StackId/assets/$AssetId" -ImmichSession:$Session
        }
    }
}
