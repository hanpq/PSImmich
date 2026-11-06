function Set-IMStack
{
    <#
    .SYNOPSIS
        Updates stack configuration.
    .DESCRIPTION
        Modifies stack properties, such as changing the primary asset.
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        Stack ID to update.
    .PARAMETER PrimaryAssetId
        Asset ID to set as the new primary asset.
    .EXAMPLE
        Set-IMStack -Id 'stack-id' -PrimaryAssetId 'asset-id'

        Changes stack primary asset.

        Updates the stack to use the specified asset as the primary asset
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Do not agree that -set- alters system state')]
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

    begin
    {
        $BodyParameters = @{
            primaryAssetId = $PrimaryAssetId
        }
    }

    process
    {
        InvokeImmichRestMethod -Method Put -RelativePath "/stacks/$Id" -ImmichSession:$Session -Body $BodyParameters | AddCustomType IMStack
    }
}
