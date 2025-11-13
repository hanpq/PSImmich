function Get-IMStack
{
    <#
    .SYNOPSIS
        Retrieves asset stacks.
    .DESCRIPTION
        Gets stacks that group related assets together (like photo bursts or HDR sets).
    .PARAMETER Session
        Optional session object for multi-instance connections.
    .PARAMETER Id
        Specific stack ID to retrieve.
    .PARAMETER PrimaryAssetId
        Filter stacks by primary asset ID.
    .EXAMPLE
        Get-IMStack

        Gets all asset stacks.
    .EXAMPLE
        Get-IMStack -Id 'stack-id'

        Gets specific stack details.

        Retrieves a specific Immich stack by ID
    .EXAMPLE
        Get-IMStack -PrimaryAssetId <assetId>

        Retrieves stacks filtered by primary asset ID
    #>

    [CmdletBinding(DefaultParameterSetName = 'list')]
    param(
        [Parameter()]
        [ImmichSession]
        $Session = $null,

        [Parameter(Mandatory, ParameterSetName = 'id', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $Id,

        [Parameter(ParameterSetName = 'list')]
        [ValidatePattern('^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$')]
        [string]
        $PrimaryAssetId
    )

    begin
    {
        $QueryParameters = @{}
        if ($PrimaryAssetId)
        {
            $QueryParameters.primaryAssetId = $PrimaryAssetId
        }
    }

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'list'
            {
                InvokeImmichRestMethod -Method Get -RelativePath '/stacks' -ImmichSession:$Session -QueryParameters $QueryParameters | AddCustomType IMStack
            }
            'id'
            {
                InvokeImmichRestMethod -Method Get -RelativePath "/stacks/$Id" -ImmichSession:$Session | AddCustomType IMStack
            }
        }
    }
}
