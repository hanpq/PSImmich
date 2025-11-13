function Remove-IMStackAsset
{
    <#
    .SYNOPSIS
        Removes assets from a stack.
    .DESCRIPTION
        Removes specific assets from an existing stack. If primary asset is removed, another becomes primary.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER StackId
        Stack ID to modify.
    .PARAMETER AssetId
        Asset ID to remove from the stack.
    .PARAMETER Force
        Suppresses confirmation prompt when specified.
    .EXAMPLE
        Remove-IMStackAsset -StackId 'stack-id' -AssetId 'asset-id'

        Removes asset from stack after confirmation.
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

    begin
    {
        if ($Force)
        {
            $ConfirmPreference = 'None'
        }
    }

    process
    {
        if ($PSCmdlet.ShouldProcess("Asset $AssetId from Stack $StackId", 'Remove'))
        {
            InvokeImmichRestMethod -Method Delete -RelativePath "/stacks/$StackId/assets/$AssetId" -ImmichSession:$Session
        }
    }
}
